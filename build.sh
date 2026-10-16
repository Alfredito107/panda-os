#!/usr/bin/env bash
# =============================================================================
#  PandA! OS  ·  Script de construcción de la ISO
#  ---------------------------------------------------------------------------
#  Requisitos: Debian 12/13 o Ubuntu 22.04+ con `live-build` instalado.
#              Debe ejecutarse como root (sudo).
#
#  Uso:
#     sudo ./build.sh                 # compila (limpia antes) e informa del tamaño
#     sudo ./build.sh --no-clean      # reutiliza la caché de paquetes
#     sudo ./build.sh --deps          # instala las dependencias del sistema
#     sudo ./build.sh --level 9       # compresión xz máxima (ISO más pequeña, +lento)
#     sudo ./build.sh --config-only   # solo genera config/ (sin compilar)
#
#  Salida típica:  panda-os-amd64.hybrid.iso  (+ .sha256 y .zsync)
# =============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT_NAME="PandA! OS"
MAX_ISO_MB=4096              # límite duro solicitado (4 GB)
GITHUB_ASSET_LIMIT_MB=2048   # límite real de GitHub Releases por archivo (2 GB)

DO_CLEAN=1
INSTALL_DEPS=0
CONFIG_ONLY=0
COMPRESSION_LEVEL=""

usage() {
	cat <<-EOF
	${PROJECT_NAME} - construcción de la ISO

	  --deps           instala las dependencias (live-build, debootstrap, xorriso, ...)
	  --no-clean       no ejecuta 'lb clean --all' antes de compilar
	  --level N        nivel de compresión xz (1-9). Por defecto: el de mksquashfs
	  --config-only    solo regenera el directorio config/ (no compila)
	  -h, --help       muestra esta ayuda
	EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--deps)         INSTALL_DEPS=1 ;;
		--no-clean)     DO_CLEAN=0 ;;
		--config-only)  CONFIG_ONLY=1 ;;
		--level)        COMPRESSION_LEVEL="${2:?Falta el nivel de compresión}"; shift ;;
		-h|--help)      usage; exit 0 ;;
		*)              echo "Opción desconocida: $1" >&2; usage; exit 1 ;;
	esac
	shift
done

banner() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
warn()   { printf '\033[1;33mAVISO: %s\033[0m\n' "$*" >&2; }
die()    { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Comprobaciones previas
# -----------------------------------------------------------------------------
banner "Comprobando el entorno de compilación"

[ "$(id -u)" -eq 0 ] || die "ejecuta este script como root:  sudo ./build.sh"

case "$SCRIPT_DIR" in
	*" "*)
		die "la ruta de compilación contiene espacios:
     $SCRIPT_DIR
     live-build no puede compilar en directorios con espacios.
     Copia el proyecto a una ruta sin espacios, por ejemplo:
       cp -r \"$SCRIPT_DIR\" ~/panda-os && cd ~/panda-os && sudo ./build.sh"
		;;
esac

if [ "$INSTALL_DEPS" -eq 1 ]; then
	banner "Instalando dependencias del sistema"
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install -y --no-install-recommends \
		live-build debootstrap xorriso squashfs-tools zsync rsync file
fi

command -v lb >/dev/null 2>&1 || die "no se encontró 'lb' (Debian Live-Build).
     Instálalo con:  sudo apt install live-build debootstrap xorriso squashfs-tools
     O bien ejecuta: sudo ./build.sh --deps"

# Comprobación de espacio libre (necesitamos ~20 GB)
FREE_MB="$(df -Pm . | awk 'NR==2 {print $4}')"
if [ "${FREE_MB:-0}" -lt 20000 ]; then
	warn "solo hay ${FREE_MB} MB libres en $SCRIPT_DIR (se recomiendan 20 GB)"
fi

# -----------------------------------------------------------------------------
# 2. Normalizar finales de línea y permisos
#    (necesario si el repositorio se editó en Windows: los hooks deben usar LF)
# -----------------------------------------------------------------------------
banner "Normalizando el árbol de configuración"

if command -v file >/dev/null 2>&1; then
	find auto config -type f -exec sh -c '
		case "$(file -b --mime-encoding "$1" 2>/dev/null)" in
			*gzip*|*binary*) exit 0 ;;
		esac
		sed -i "s/\r$//" "$1" 2>/dev/null || true
	' _ {} \;
fi

chmod 0755 auto/config auto/clean build.sh 2>/dev/null || true
find config/hooks -type f -exec chmod 0755 {} + 2>/dev/null || true
find config/includes.chroot/usr/local/bin -type f -exec chmod 0755 {} + 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. Limpieza
# -----------------------------------------------------------------------------
if [ "$DO_CLEAN" -eq 1 ]; then
	banner "Limpiando compilaciones anteriores"
	lb clean --all || true
	rm -rf cache
else
	warn "'--no-clean': se reutilizará la caché de paquetes (${SCRIPT_DIR}/cache)"
	rm -rf cache/bootstrap
fi

# -----------------------------------------------------------------------------
# 4. Configuración
# -----------------------------------------------------------------------------
banner "Generando la configuración de live-build (auto/config)"

if [ -n "$COMPRESSION_LEVEL" ]; then
	case "$COMPRESSION_LEVEL" in
		1|2|3|4|5|6|7|8|9) ;;
		*) die "el nivel de compresión debe estar entre 1 y 9" ;;
	esac
	./auto/config --chroot-squashfs-compression-level "$COMPRESSION_LEVEL"
else
	./auto/config
fi

if [ "$CONFIG_ONLY" -eq 1 ]; then
	banner "Configuración generada (--config-only). Sin compilar."
	exit 0
fi

# -----------------------------------------------------------------------------
# 5. Compilación
# -----------------------------------------------------------------------------
banner "Compilando ${PROJECT_NAME} (esto puede tardar entre 1 y 3 horas)"
echo "    · Registro de la compilación: $SCRIPT_DIR/build.log"

lb build 2>&1 | tee build.log

# -----------------------------------------------------------------------------
# 6. Informe de resultados
# -----------------------------------------------------------------------------
banner "Resultado"

ISO="$(find "$SCRIPT_DIR" -maxdepth 1 -name '*.iso' -printf '%T@ %p\n' | sort -rn | head -n1 | cut -d' ' -f2- || true)"
[ -n "$ISO" ] || die "no se generó ninguna ISO: revisa build.log"

SIZE_BYTES="$(stat -c %s "$ISO")"
SIZE_MB="$((SIZE_BYTES / 1024 / 1024))"

echo "  Imagen ......... $ISO"
echo "  Tamaño ......... $(numfmt --to=iec-i --suffix=B "$SIZE_BYTES" 2>/dev/null || echo "${SIZE_MB} MB") (${SIZE_MB} MB)"
[ -f "${ISO}.sha256" ] && echo "  Suma SHA-256 ... ${ISO}.sha256"
[ -f "${ISO}.zsync" ] && echo "  zsync .......... ${ISO}.zsync (para actualizaciones diferenciales)"
[ -f "$SCRIPT_DIR/binary/live/filesystem.squashfs" ] && \
	echo "  SquashFS ....... $(du -h "$SCRIPT_DIR/binary/live/filesystem.squashfs" | cut -f1) (comprimido con xz)"

if [ "$SIZE_MB" -gt "$MAX_ISO_MB" ]; then
	die "la ISO supera los ${MAX_ISO_MB} MB (${SIZE_MB} MB).
     Reduce el tamaño: revisa el apartado «Control de tamaño» del README.md
     (o usa: sudo ./build.sh --level 9)."
fi

if [ "$SIZE_MB" -gt "$GITHUB_ASSET_LIMIT_MB" ]; then
	warn "la ISO (${SIZE_MB} MB) cumple el límite de 4 GB, pero GitHub Releases
     rechaza archivos de más de ${GITHUB_ASSET_LIMIT_MB} MB.
     Opciones: reduce el tamaño, publica la ISO en un servidor externo
     (Archive.org, SourceForge...) o entrega solo el .zsync para actualizaciones."
else
	echo "  GitHub ......... OK: cabe como asset de un GitHub Release (<2 GB)"
fi

banner "${PROJECT_NAME} compilado correctamente"
