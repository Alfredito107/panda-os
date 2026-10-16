#!/usr/bin/env bash
# =============================================================================
#  PandA! OS · Validación estática de la configuración
# -----------------------------------------------------------------------------
#  Comprueba, SIN compilar, los errores que más tiempo cuestan:
#    · sintaxis de todos los scripts
#    · ShellCheck (POSIX y bash)
#    · YAML de Calamares (settings.conf, módulos, branding)
#    · workflow de GitHub Actions (actionlint)
#    · nombres de módulo de Calamares desconocidos
#    · CRLF/BOM, imágenes de branding ausentes, nombres de paquete sospechosos
#
#  Uso:      bash tools/validate.sh
#
#  Herramientas opcionales (se detectan en el PATH o se indican por variable):
#      - shellcheck :  SHELLCHECK=/ruta/shellcheck
#      - yq (v4)    :  YQ=/ruta/yq
#      - actionlint :  ACTIONLINT=/ruta/actionlint
# =============================================================================

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 2

FAIL=0; OK=0; SKIP=0

head2() { printf '\n\033[1;34m== %s\033[0m\n' "$*"; }
pass()  { OK=$((OK + 1));   printf '  \033[32mOK\033[0m      %s\n' "$*"; }
fail()  { FAIL=$((FAIL + 1)); printf '  \033[1;31mFALLO\033[0m   %s\n' "$*"; }
skip()  { SKIP=$((SKIP + 1)); printf '  \033[33mOMITIDO\033[0m %s\n' "$*"; }

POSIX_SCRIPTS="auto/config auto/clean config/hooks/live/*.hook.chroot config/includes.chroot/usr/local/bin/pandaos-install config/includes.chroot/usr/local/bin/pandaos-desktop-icon"
BASH_SCRIPTS="build.sh tools/validate.sh"

CAL_DIR="config/includes.chroot/etc/calamares"
BRANDING_DIR="config/includes.chroot/usr/share/calamares/branding/pandaos"
YAML_FILES="$CAL_DIR/settings.conf $CAL_DIR/modules/*.conf $BRANDING_DIR/branding.desc"

# -----------------------------------------------------------------------------
head2 "1. Sintaxis de los scripts (bash -n)"
# -----------------------------------------------------------------------------
for f in $BASH_SCRIPTS $POSIX_SCRIPTS; do
    if bash -n "$f" 2>/dev/null; then
        pass "$f"
    else
        fail "$f"
        bash -n "$f" || true
    fi
done

# -----------------------------------------------------------------------------
head2 "2. ShellCheck"
# -----------------------------------------------------------------------------
SC="${SHELLCHECK:-$(command -v shellcheck 2>/dev/null || true)}"
if [ -n "$SC" ]; then
    for f in $POSIX_SCRIPTS; do
        if out="$("$SC" -s sh -S warning -f gcc "$f" 2>&1)"; then
            pass "sh   $f"
        else
            fail "sh   $f"
            printf '%s\n' "$out"
        fi
    done
    for f in $BASH_SCRIPTS; do
        if out="$("$SC" -s bash -S warning -f gcc "$f" 2>&1)"; then
            pass "bash $f"
        else
            fail "bash $f"
            printf '%s\n' "$out"
        fi
    done
else
    skip "shellcheck no encontrado (instálalo con: apt install shellcheck)"
fi

# -----------------------------------------------------------------------------
head2 "3. YAML de Calamares"
# -----------------------------------------------------------------------------
Y="${YQ:-$(command -v yq 2>/dev/null || true)}"
if [ -n "$Y" ] && "$Y" --version 2>/dev/null | grep -qi mikefarah; then
    for f in $YAML_FILES; do
        if "$Y" eval '.' "$f" >/dev/null 2>&1; then
            pass "$f  (yq)"
        else
            fail "$f"
            "$Y" eval '.' "$f" 2>&1 | head -n3
        fi
    done
elif command -v python3 >/dev/null 2>&1 && python3 -c 'import yaml' 2>/dev/null; then
    for f in $YAML_FILES; do
        if python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1], encoding="utf-8"))' "$f" 2>/dev/null; then
            pass "$f  (python3+yaml)"
        else
            fail "$f"
        fi
    done
else
    skip "ni 'yq' (v4) ni 'python3' con PyYAML (opciones: apt install yq | apt install python3-yaml)"
fi

# -----------------------------------------------------------------------------
head2 "4. Workflow de GitHub Actions"
# -----------------------------------------------------------------------------
AL="${ACTIONLINT:-$(command -v actionlint 2>/dev/null || true)}"
if [ -n "$AL" ]; then
    if out="$("$AL" .github/workflows/build-iso.yml 2>&1)"; then
        pass ".github/workflows/build-iso.yml"
    else
        fail ".github/workflows/build-iso.yml"
        printf '%s\n' "$out"
    fi
else
    skip "actionlint no encontrado (opcional: https://github.com/rhysd/actionlint)"
fi

# -----------------------------------------------------------------------------
head2 "5. Módulos de Calamares usados en settings.conf"
# -----------------------------------------------------------------------------
# Lista de módulos válidos: los de Calamares 3.3 upstream + los que añade el
# paquete calamares-settings-debian (verificado contra el código fuente).
VALIDOS="welcome locale keyboard partition users summary finished
mount unpackfs luksbootkeyfile machineid fstab localecfg displaymanager
networkcfg hwclock services-systemd grubcfg bootloader packages shellprocess
initramfscfg initramfs umount
bootloader-config dpkg-unsafe-io dpkg-unsafe-io-undo sources-media sources-media-unmount sources-final"

if [ -f "$CAL_DIR/settings.conf" ]; then
    # Extrae los nombres de módulo de la sección '- exec:', ignorando los
    # comentarios que van al final de la línea (p. ej. "- unpackfs   # ...").
    usados="$(awk '/^- exec:/{f=1;next} /^- show:/{f=0} f && /^  - /{sub(/^  - /,""); sub(/[[:space:]]*#.*$/,""); if (length($0)) print}' "$CAL_DIR/settings.conf")"
    for m in $usados; do
        case " $(printf '%s' "$VALIDOS" | tr '\n' ' ') " in
            *" $m "*) pass "módulo conocido: $m" ;;
            *)        fail "módulo DESCONOCIDO en la secuencia: $m" ;;
        esac
    done

    # El directorio de branding indicado debe existir
    b="$(awk '/^branding:/{sub(/^branding:[[:space:]]*/,"");print;exit}' "$CAL_DIR/settings.conf")"
    if [ -n "$b" ] && [ -d "config/includes.chroot/usr/share/calamares/branding/$b" ]; then
        pass "branding '$b' existe"
    else
        fail "branding '$b' no encontrado en config/includes.chroot/usr/share/calamares/branding/"
    fi
else
    fail "no existe $CAL_DIR/settings.conf"
fi

# -----------------------------------------------------------------------------
head2 "6. Branding: imágenes referenciadas"
# -----------------------------------------------------------------------------
for img in panda-logo.png panda-welcome.png; do
    if [ -f "$BRANDING_DIR/$img" ]; then
        pass "$img ($(wc -c < "$BRANDING_DIR/$img" | tr -d ' ') bytes)"
    else
        fail "falta $BRANDING_DIR/$img"
    fi
done

# -----------------------------------------------------------------------------
head2 "7. Ficheros de texto: CRLF, BOM y nombres de paquete"
# -----------------------------------------------------------------------------
crlf=0; bom=0
while IFS= read -r f; do
    case "$f" in *.png|*.jpg|*.jpeg|*.gz|*.xz) continue ;; esac
    if LC_ALL=C grep -q "$(printf '\r')" "$f" 2>/dev/null; then
        fail "CRLF en $f"; crlf=1
    fi
    if head -c 3 "$f" | LC_ALL=C grep -q "$(printf '\357\273\277')" 2>/dev/null; then
        fail "BOM en $f"; bom=1
    fi
done < <(find . -type f -not -path './.git/*')
[ "$crlf" -eq 0 ] && pass "ningún fichero con CRLF"
[ "$bom" -eq 0 ] && pass "ningún fichero con BOM"

# live-build entrega cada palabra de la línea a 'apt-get install' (xargs), de
# modo que un comentario al final de la línea se convertiría en nombres de
# paquete y rompería la compilación. Aquí se comprueba que no ocurra.
badpkg=0
pkgcount=0
while IFS= read -r p; do
    p="${p%"${p##*[![:space:]]}"}"   # quita espacios finales
    case "$p" in
        "") continue ;;
        "#"*) continue ;;            # comentario de línea completa: correcto
    esac
    pkgcount=$((pkgcount + 1))
    case "$p" in
        *"#"*)
            fail "comentario EN LÍNEA en una lista de paquetes: '$p'"
            fail "  -> live-build pasaría '#' a apt-get y la compilación fallaría"
            badpkg=1 ;;
        *[[:space:]]*)
            fail "varios tokens en una línea de paquete: '$p'"
            badpkg=1 ;;
        *[!a-z0-9+.-]*)
            fail "nombre de paquete sospechoso: '$p'"
            badpkg=1 ;;
    esac
done < <(cat config/package-lists/*.list.chroot 2>/dev/null)
[ "$badpkg" -eq 0 ] && pass "$pkgcount nombres de paquete, uno por línea y sin comentarios en línea"

# -----------------------------------------------------------------------------
head2 "8. Nombres de paquete reales en el archivo de Debian (solo con --online)"
# -----------------------------------------------------------------------------
# Un nombre mal escrito en una lista de paquetes rompe la compilación, y los
# que están en 'remove' de Calamares abortan la INSTALACIÓN. Esta comprobación
# (opcional, necesita red) los valida contra el archivo real de Debian.
if [ "${1:-}" = "--online" ]; then
    if ! command -v curl >/dev/null 2>&1; then
        skip "curl no disponible"
    else
        red=0; netfail=0; tot=0
        while IFS= read -r p; do
            [ -n "$p" ] || continue
            tot=$((tot + 1))
            if resp="$(curl -fsS --max-time 25 \
                 "https://api.ftp-master.debian.org/madison?package=${p}&table=debian&f=json" 2>/dev/null)"; then
                case "$resp" in
                    "[]"|"")
                        fail "el paquete '$p' NO existe en el archivo de Debian"
                        red=1 ;;
                esac
            else
                netfail=1
                break
            fi
        done < <(
            {
                sed -n 's/^[[:space:]]*#.*//; s/[[:space:]]*$//p' config/package-lists/*.list.chroot 2>/dev/null
                sed -n "s/^[[:space:]]*- '\([^']*\)'.*/\1/p" "$CAL_DIR/modules/packages.conf" 2>/dev/null
            } | grep -v '^$' | sort -u
        )
        if [ "$netfail" -eq 1 ]; then
            skip "no se pudo consultar la API de Debian (¿sin red?); comprobados $tot"
        else
            [ "$red" -eq 0 ] && pass "$tot nombres comprobados contra el archivo real de Debian"
        fi
    fi
else
    skip "usa 'bash tools/validate.sh --online' para comprobar los nombres contra Debian"
fi

# -----------------------------------------------------------------------------
head2 "Resumen"
# -----------------------------------------------------------------------------
printf '  Comprobaciones correctas: %s\n  Fallos: %s\n  Omitidas: %s\n' "$OK" "$FAIL" "$SKIP"
if [ "$FAIL" -gt 0 ]; then
    printf '\n\033[1;31mHay %s problema(s): corrige antes de compilar la ISO.\033[0m\n' "$FAIL"
    exit 1
fi
printf '\n\033[1;32mTodo correcto: la configuración pasa todas las validaciones.\033[0m\n'
