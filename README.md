# 🐼 PandA! OS

ISO **live** de **Debian 13 «trixie»** con **KDE Plasma**, la suite **completa de
LibreOffice en español** y las herramientas de trabajo de oficina e inventarios,
con un **instalador gráfico Calamares** integrado.

| | |
|---|---|
| **Base** | Debian 13 `trixie` (stable) · amd64 |
| **Arranque** | ISO híbrida: BIOS (isolinux) + UEFI (grub-efi, con soporte Secure Boot) |
| **Escritorio** | KDE Plasma (`kde-standard`) + SDDM |
| **Oficina** | LibreOffice Writer · Calc · Impress · Draw · Base · Math + `libreoffice-l10n-es` |
| **Navegador** | `firefox-esr` + paquete de idioma español |
| **Visores/herramientas** | Okular, Xournal++, Simple Scan, Ark, KCalc, Kate |
| **Sistema/impresión** | CUPS (+ drivers), Timeshift, KDE Connect |
| **Idioma por defecto** | `es_ES.UTF-8` · teclado `es` · zona `Europe/Madrid` |
| **Compresión** | SquashFS **xz** (por defecto en live-build) → ISO < **4 GB** |
| **Usuario live** | `panda` (contraseña vacía) · host `pandaos` |

---

## 📁 Estructura del proyecto

```
panda-os/                            # ← esta carpeta ES la raíz del repositorio Git
├── .github/workflows/build-iso.yml  # Compilación automática de la ISO en GitHub Actions
├── .gitattributes                   # Fuerza finales de línea LF en los scripts
├── .gitignore                       # Ignora los artefactos de compilación
├── build.sh                         # Script de compilación (limpia, compila y verifica el tamaño)
├── auto/
│   ├── config                       # Opciones de live-build (distribución, xz, área de archivos...)
│   └── clean                        # Limpieza del directorio de compilación
├── config/
│   ├── package-lists/               # ⭐ LISTA DE PAQUETES (aquí se añaden o quitan programas)
│   │   ├── 01-panda-base.list.chroot
│   │   ├── 02-panda-kde.list.chroot
│   │   ├── 03-panda-office.list.chroot
│   │   ├── 04-panda-web.list.chroot
│   │   ├── 05-panda-tools.list.chroot
│   │   ├── 06-panda-system.list.chroot
│   │   └── 07-panda-installer.list.chroot      # ← bórralo para una ISO sin instalador
│   ├── hooks/live/
│   │   ├── 0100-panda-system.hook.chroot       # Idioma, teclado, zona horaria, SDDM, CUPS
│   │   └── 0900-panda-cleanup.hook.chroot      # Limpieza final (cachés, documentación)
│   ├── rootfs/excludes              # Ficheros que NO entran en el SquashFS
│   └── includes.chroot/             # Ficheros copiados al sistema de la ISO
│       ├── etc/calamares/           # settings.conf + módulos de Calamares
│       ├── usr/share/calamares/branding/pandaos/   # branding.desc + logotipos
│       ├── usr/share/applications/pandaos-install.desktop
│       ├── usr/local/bin/pandaos-install           # lanzador del instalador (sesión live)
│       └── etc/xdg/autostart/       # crea el icono "Instalar PandA! OS" en el escritorio
├── tools/
│   ├── make-branding.ps1            # Regenera los PNG de marca (Windows/PowerShell)
│   └── validate.sh                  # ⭐ Comprueba la configuración SIN compilar
└── README.md                        # Este documento
```

---

## ✅ Requisitos

**Para compilar** (en Linux; en Windows no es posible, usa WSL2 o la GitHub Action):

- Debian 12/13 o Ubuntu 22.04+ con acceso a `sudo`
- Paquetes: `live-build debootstrap xorriso squashfs-tools zsync rsync`
  → `sudo ./build.sh --deps` los instala
- **20 GB** de espacio libre y ~6 GB de RAM
- Entre **1 y 3 horas** de compilación (KDE + LibreOffice con compresión xz)

> ⚠️ **La ruta de compilación no puede contener espacios.** Es una limitación
> interna de live-build (`Cannot build live image from a directory containing spaces`).
> Este proyecto está ahora dentro de `…\Proyecto predeterminado\`, así que **cópialo**
> a una ruta sin espacios (o clónalo en `~`) antes de compilar:

```bash
cp -r panda-os ~/panda-os      # de C:\...\Proyecto predeterminado\panda-os
cd ~/panda-os
sudo ./build.sh --deps         # instala dependencias y compila
```

> 💡 El script `build.sh` detecta este problema y te lo indica con la orden exacta
> a ejecutar, así que no pasa nada si lo intentas desde la carpeta original.

---

## 🐙 Subirlo a GitHub

El repositorio Git **ya está inicializado** en `panda-os/`, con un commit inicial
que incluye los 34 ficheros y los scripts marcados como ejecutables dentro del
repositorio (`build.sh`, `auto/config`, `auto/clean`, `tools/validate.sh`, los
hooks y los lanzadores). Así que solo faltan dos cosas:

1. **Crear el repositorio vacío** en <https://github.com/new> con el nombre
   `panda-os` (sin README ni licencia, para que el primer push no dé conflictos).
2. Subirlo:

```bash
cd panda-os                    # raíz del repositorio
git remote add origin https://github.com/Alfredito107/panda-os.git
git push -u origin main
```

Si prefieres empezar de cero (o replicarlo en otro equipo), este es el
procedimiento completo:

```bash
cd panda-os                    # raíz del repositorio
git init -b main
git add .
# Marca los scripts como ejecutables DENTRO del repositorio. Es necesario si
# editas en Windows, donde el sistema de ficheros no guarda el bit de ejecución
# (así, al clonar en Linux, './build.sh' funciona directamente):
git update-index --chmod=+x build.sh auto/config auto/clean tools/validate.sh \
  config/hooks/live/*.hook.chroot config/includes.chroot/usr/local/bin/*
git commit -m "PandA! OS 1.0: configuración inicial de la ISO (Debian 13 + KDE + LibreOffice)"
git remote add origin https://github.com/Alfredito107/panda-os.git
git push -u origin main
```

> ℹ️ Los enlaces del repositorio **ya están configurados** a
> `github.com/Alfredito107/panda-os` en `auto/config` (campo `--iso-publisher`)
> y en `branding.desc` (`productUrl`, `supportUrl`, `knownIssuesUrl`,
> `releaseNotesUrl`, `donateUrl`), así que el instalador y la ISO muestran ya tu
> repositorio.
>
> Si algún día cambias de usuario u organización, sustitúyelo en ambos ficheros:
>
> ```bash
> sed -i 's/Alfredito107/USUARIO_NUEVO/g' auto/config \
>   config/includes.chroot/usr/share/calamares/branding/pandaos/branding.desc
> ```

---

## 🚀 Compilación

```bash
sudo ./build.sh                 # limpia + compila + verifica el tamaño (recomendado)
sudo ./build.sh --no-clean      # reutiliza la caché de paquetes (mucho más rápido)
sudo ./build.sh --level 9       # compresión xz máxima (ISO más pequeña, más lenta)
sudo ./build.sh --config-only   # solo genera config/ (para revisar las opciones)
```

> 💡 Si has subido el repositorio desde Windows, el bit de ejecución puede faltar:
> usa `sudo bash build.sh` (idéntico) o `chmod +x build.sh auto/config auto/clean`.
> El propio `build.sh` se encarga de dar permisos a los hooks y a los lanzadores.

Al terminar obtienes, dentro de `panda-os/`:

```
panda-os-amd64.hybrid.iso          # la imagen (ISO híbrida, USB o DVD)
panda-os-amd64.hybrid.iso.sha256   # suma de verificación
panda-os-amd64.hybrid.iso.zsync    # para actualizaciones diferenciales
binary/live/filesystem.squashfs    # sistema comprimido con xz
```

### Compilación automática en GitHub (recomendada)

El flujo `.github/workflows/build-iso.yml` compila la ISO en los servidores de
GitHub (gratis para repositorios públicos) y la publica:

```bash
git tag v1.0.0
git push origin v1.0.0
```

También puedes lanzarla a mano desde **Actions → Build PandA! OS ISO → Run workflow**
(elige el nivel de compresión). La ISO queda como *artifact* descargable durante 7 días.

Antes de compilar, el flujo ejecuta `tools/validate.sh` (ver el apartado siguiente):
si algo está mal escrito, lo sabrás en **segundos** en lugar de después de tres horas.

---

## 🔍 Validación previa (30 segundos que te ahorran 3 horas)

```bash
bash tools/validate.sh            # comprobaciones locales (rápidas)
bash tools/validate.sh --online   # + nombres de paquete reales en Debian (necesita red)
```

Comprueba, **sin compilar**:

- la sintaxis de **todos** los scripts (`bash -n`);
- **ShellCheck** (si está instalado) en modo POSIX y bash;
- que los **YAML de Calamares** (`settings.conf`, módulos y branding) se analizan bien;
- el **workflow** de GitHub Actions con `actionlint` (si está instalado);
- que **todos los módulos** de la secuencia de `settings.conf` existen de verdad
  (Calamares **aborta** si uno no existe);
- que el directorio de *branding* y sus imágenes existen;
- que no hay **CRLF** ni **BOM** ni nombres de paquete mal escritos;
- con `--online`: que **todos los nombres de paquete existen** en el archivo de
  Debian (los de las listas y los del `remove` de Calamares, que si falla
  **aborta la instalación**).

Las herramientas son opcionales: si no están instaladas, ese bloque se omite con
un aviso (`shellcheck`, `yq` v4 y `actionlint`). En Debian/Ubuntu:

```bash
sudo apt install shellcheck python3-yaml    # + yq y actionlint si los quieres
```

> ⭐ **Regla de oro de las listas de paquetes.** En
> `config/package-lists/*.list.chroot` escribe **un paquete por línea y nada más
> detrás**. live-build entrega cada palabra de la línea a `apt-get install`
> (a través de `xargs`), de modo que un comentario al final de la línea
> (`ark   # archivador`) se interpretaría como nombres de paquete y
> **rompería la compilación** con `E: Unable to locate package #`.
> Los comentarios van **siempre en su propia línea**, empezando por `#`.
> `tools/validate.sh` lo comprueba por ti.

---

## 📏 Control de tamaño (objetivo: < 4 GB)

Ya viene optimizado de fábrica:

| Medida | Dónde se define | Ahorro aproximado |
|---|---|---|
| SquashFS **xz** (y no gzip) | `auto/config` → `--chroot-squashfs-compression-type xz` | 25-30 % frente a gzip |
| `--apt-indices false` (sin listas APT dentro de la ISO) | `auto/config` | ~40 MB |
| Documentación de paquetes eliminada (se conservan los `copyright`) | `0900-panda-cleanup.hook.chroot` | ~150 MB |
| Sin páginas de manual, `info`, `lintian`, cachés APT | `config/rootfs/excludes` | ~60 MB |
| Initramfs comprimido con LZMA, sin memtest, sin instalador de Debian clásico | `auto/config` | ~30 MB |

**Si necesitas bajar todavía más** (por ejemplo, para que quepa en un GitHub
Release, que limita los archivos a **2 GB**), comenta estas líneas:

| Paquete / opción | Dónde | Ahorro |
|---|---|---|
| `libreoffice-help-es` (ayuda F1 en español) | `03-panda-office.list.chroot` | ~50 MB |
| `printer-driver-all` (todos los drivers de impresora) | `06-panda-system.list.chroot` | ~80 MB |
| `firmware-*` (si no usas wifi) | `auto/config` → `--firmware-chroot false` | ~300 MB |
| `fonts-noto-core` | `03-panda-office.list.chroot` | ~40 MB |
| Compresión máxima | `sudo ./build.sh --level 9` | 5-10 % |
| Excluir también `/usr/share/doc` | final de `config/rootfs/excludes` | ~150 MB (⚠️ quita avisos de copyright) |

Para medir el resultado real:

```bash
du -h binary/live/filesystem.squashfs     # peso del sistema comprimido
ls -lh panda-os-amd64.hybrid.iso          # peso final de la ISO
```

> Estimación orientativa: **2,4 – 3,4 GB** de ISO con la configuración por defecto.
> Comprueba el número real tras la primera compilación y ajusta según necesites.

---

## 🌐 Distribución gratuita de actualizaciones por GitHub

1. **GitHub Releases** (lo más sencillo): el flujo de trabajo ya publica la ISO
   automáticamente al crear una etiqueta `v*`.
   Límite real de GitHub: **2 GB por archivo** (no 4 GB). Si la ISO supera ese
   tamaño, el flujo **no crea el Release**: avisa y deja la ISO como *artifact*
   descargable de la ejecución (durante 7 días), para que la compilación no se
   pierda.

   Opciones cuando la ISO pesa más de 2 GB:
   - reducir paquetes (tabla anterior) hasta bajar de 2 GB;
   - publicar la ISO en un servidor externo (Archive.org, SourceForge, un VPS…)
     y dejar en el Release solo el enlace y el fichero `.zsync`;
   - **Git LFS**: cuota gratuita de 1 GB de almacenamiento y 1 GB/mes de tráfico,
     insuficiente para ISOs de varios GB (no recomendado).

2. **Actualizaciones diferenciales con `zsync`** (ya activado):
   quien tenga `panda-os-amd64.hybrid.iso.zsync` solo descarga los bloques que
   cambiaron entre versiones:

   ```bash
   zsync http://tu-servidor/panda-os-amd64.hybrid.iso.zsync
   ```

3. **Verificación** para tus usuarios:

   ```bash
   sha256sum -c panda-os-amd64.hybrid.iso.sha256
   ```

4. **Licencias**: al distribuir binarios de Debian tienes que ofrecer el código
   fuente correspondiente. Apunta a los repositorios oficiales
   (`deb-src` de `deb.debian.org` y `security.debian.org`) y a
   <https://sources.debian.org> en el texto del Release; PandA! OS solo añade
   scripts de configuración (los de este repositorio).

---

## 💾 Prueba la ISO antes de distribuirla

```bash
# QEMU con aceleración (rápido)
qemu-system-x86_64 -m 4096 -enable-kvm -cdrom panda-os-amd64.hybrid.iso

# Probar el arranque UEFI
qemu-system-x86_64 -m 4096 -enable-kvm -bios /usr/share/OVMF/OVMF_CODE.fd \
  -cdrom panda-os-amd64.hybrid.iso

# USB real (¡ojo con el nombre del dispositivo!)
sudo dd if=panda-os-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

También funciona arrastrándola a [Ventoy] o a VirtualBox (BIOS y EFI).

---

## 🧾 Ideas para reforzar el uso de oficina e inventarios

Todos estos paquetes **existen en Debian 13** y puedes añadirlos a
`config/package-lists/` cuando los necesites (cuestan espacio en la ISO):

| Necesidad | Paquete(s) |
|---|---|
| Etiquetas, códigos de barras y carteles de inventario | `glabels`, `zint` |
| OCR (convertir escaneos en texto buscable) | `tesseract-ocr`, `tesseract-ocr-spa`, `ocrmypdf`, `gscan2pdf` |
| Organizar y reordenar PDF escaneados | `pdfarranger` |
| Hojas de cálculo alternativas | `gnumeric` |
| Correo, calendario y contactos | `thunderbird` (+ `thunderbird-l10n-es-es`) |
| Diseño e imprenta (folletos, carteles) | `scribus` |
| Escritorio remoto (soporte a otros equipos) | `remmina` |
| Grabar la pantalla (tutoriales internos) | `vokoscreen-ng` |
| Gestor de contraseñas | `keepassxc` |
| Particionado y discos (equipos nuevos) | `gparted`, `gnome-disk-utility` |
| Grabar esta ISO en USB desde KDE | `k3b`, `isoimagewriter` |
| Antivirus (intercambio de ficheros con Windows) | `clamtk`, `clamav` |

Ejemplo: para añadir OCR y etiquetas basta con crear un fichero nuevo:

```bash
cat > config/package-lists/08-panda-inventario.list.chroot <<'EOF'
glabels
zint
tesseract-ocr
tesseract-ocr-spa
ocrmypdf
pdfarranger
EOF
sudo ./build.sh --no-clean
```

---

## 🎨 Personalización rápida

| Quiero… | Dónde tocar |
|---|---|
| Añadir o quitar programas | los ficheros `config/package-lists/*.list.chroot` (**un paquete por línea, sin nada detrás**; luego `bash tools/validate.sh`) |
| Cambiar nombre, versión o etiqueta de la ISO | `auto/config` (`--iso-application`, `--image-name`, `--iso-volume`) |
| Cambiar el usuario live | `auto/config` → `--bootappend-live username=…` |
| Cambiar idioma/teclado/zona horaria | `auto/config` → `locales=`, `keyboard-layouts=`, `timezone=` **y** `0100-panda-system.hook.chroot` |
| Poner tu repositorio en los enlaces | ya configurado como `Alfredito107/panda-os` en `auto/config` (`--iso-publisher`) y en `branding.desc`; cámbialo con `sed` si usas otro usuario |
| Cambiar logotipos | sustituye los PNG en `config/includes.chroot/usr/share/calamares/branding/pandaos/` (o edita `tools/make-branding.ps1`) |
| Fondo de pantalla / tema de Plasma | `config/includes.chroot/etc/skel/.config/` y `.../usr/share/wallpapers/` |
| Añadir una presentación durante la instalación | crea `show.qml` en el directorio de branding y descomenta `slideshow:` en `branding.desc` |
| ISO sin instalador | borra `07-panda-installer.list.chroot` |

Tras cualquier cambio:

```bash
sudo ./build.sh --no-clean
```

---

## 🧩 Qué hace cada pieza de Calamares

| Fichero | Función |
|---|---|
| `etc/calamares/settings.conf` | Orden de los pasos del instalador (bienvenida, particionado, usuario, resumen, instalación, fin) |
| `etc/calamares/modules/unpackfs.conf` | Descomprime `/run/live/medium/live/filesystem.squashfs` en el disco destino |
| `etc/calamares/modules/users.conf` | Usuario y grupos (incluye `lpadmin` para imprimir y `scanner` para digitalizar) |
| `etc/calamares/modules/displaymanager.conf` | Configura **SDDM** y fuerza la sesión de **Plasma** |
| `etc/calamares/modules/welcome.conf` | Requisitos mínimos: 25 GB de disco y 2 GB de RAM |
| `etc/calamares/modules/packages.conf` | Elimina del sistema instalado los paquetes de la sesión live |
| `etc/calamares/modules/shellprocess.conf` | Retira el lanzador «Instalar PandA! OS» del escritorio ya instalado |
| `usr/share/calamares/branding/pandaos/` | Nombre, versión, enlaces, colores y logotipos de PandA! OS |

Todos los ficheros de `config/includes.chroot/` se copian **después** de instalar
los paquetes, así que **sobrescriben** los que trae `calamares-settings-debian`.
Los hooks se ejecutan aún más tarde, por lo que pueden ajustar permisos.

Además, el hook `0100-panda-system.hook.chroot` **retira el lanzador «Install
Debian»** que instala `calamares-settings-debian` (su script
`/usr/bin/calamares-install-debian`, su entrada de autostart y su icono), de modo
que en la sesión live aparece **un único icono**: «Instalar PandA! OS». Sin esa
limpieza verías dos instaladores distintos en el escritorio.

---

## 🛠️ Solución de problemas

| Síntoma | Causa / solución |
|---|---|
| `Cannot build live image from a directory containing spaces` | copia el proyecto a `~/panda-os` y vuelve a compilar |
| `No space left on device` | libera 20 GB o compila con `--no-clean`; borra `cache/` y `chroot/` |
| Los hooks fallan con `\r` o `bad interpreter` | el repositorio tiene CRLF: `.gitattributes` fuerza LF; ejecuta `./build.sh`, que normaliza el árbol automáticamente |
| La ISO arranca en BIOS pero no en UEFI | usa `--bootloaders "grub-efi,syslinux"` (ya configurado) y prueba en una máquina con `shim-signed` disponible |
| No hay wifi en el equipo de prueba | añade `firmware-iwlwifi`/`firmware-realtek` a `01-panda-base.list.chroot` o activa `--firmware-chroot true` (ya está activo) |
| La instalación con Calamares se detiene al final | revisa `/var/log/calamares.log` en el sistema destino; suele ser un paquete de `packages.conf` que no existe (usa `try_remove`) |
| Falta la ayuda de LibreOffice en español | comprueba que `libreoffice-help-es` siga en `03-panda-office.list.chroot` |
| `E: Unable to locate package #` (o `de`, `ficheros`…) al instalar paquetes | hay un **comentario al final de una línea** en `config/package-lists/*.list.chroot`: pásalo a su propia línea y ejecuta `bash tools/validate.sh` |
| Calamares muestra «Unknown module» o no arranca | algún nombre de módulo de `settings.conf` no existe: `bash tools/validate.sh` te dice cuál |
| Aparecen **dos** iconos de instalación en el escritorio live | el hook `0100-panda-system.hook.chroot` no se aplicó (revisa `build.log`): debe borrar el lanzador de `calamares-settings-debian` |
| `./build.sh: Permission denied` | el repositorio se subió desde Windows sin bit de ejecución: usa `sudo bash build.sh` o `git update-index --chmod=+x build.sh` |

---

## 📜 Licencias

- **Debian** y todos los paquetes incluidos conservan sus licencias originales
  (mayoritariamente GPL/LGPL, MIT, BSD y algunas no libres en `contrib`/`non-free`).
  Al redistribuir la ISO, debes ofrecer el código fuente correspondiente:
  enlaza a los repositorios de Debian.
- La configuración de este repositorio (scripts, hooks, branding) puedes
  licenciarla como quieras; se sugiere **GPL-3.0-or-later** para mantener el
  espíritu libre del proyecto.
- `firefox-esr` se distribuye bajo MPL-2.0; LibreOffice bajo MPL-2.0/LGPLv3+.

---

## 🔗 Referencias

- Manual de live-build: `man lb_config`, `man live-build`
- Debian Live: <https://wiki.debian.org/DebianLive>
- Calamares: <https://calamares.io> · configuración de Debian: `calamares-settings-debian`
- zsync: <https://zsync.moria.org.uk>

[Ventoy]: https://www.ventoy.net
