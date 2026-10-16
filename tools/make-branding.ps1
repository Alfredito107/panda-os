<#
=============================================================================
 PandA! OS · Generador de las imágenes de marca (PNG)
-----------------------------------------------------------------------------
 Crea los ficheros que usa el branding de Calamares y el icono del instalador:

   config/includes.chroot/usr/share/calamares/branding/pandaos/panda-logo.png
   config/includes.chroot/usr/share/calamares/branding/pandaos/panda-welcome.png
   config/includes.chroot/usr/share/icons/hicolor/256x256/apps/pandaos-install.png

 Uso (Windows PowerShell, desde la carpeta panda-os):
     powershell -ExecutionPolicy Bypass -File .\tools\make-branding.ps1

 Las imágenes resultantes se pueden sustituir por los logotipos definitivos:
 basta con mantener los mismos nombres de fichero.
=============================================================================
#>

Add-Type -AssemblyName System.Drawing

$root       = Split-Path -Parent $PSScriptRoot
$brandingDir = Join-Path $root 'config\includes.chroot\usr\share\calamares\branding\pandaos'
$iconDir     = Join-Path $root 'config\includes.chroot\usr\share\icons\hicolor\256x256\apps'

New-Item -ItemType Directory -Force -Path $brandingDir, $iconDir | Out-Null

$green  = [System.Drawing.Color]::FromArgb(255, 47, 143, 78)
$dark   = [System.Drawing.Color]::FromArgb(255, 29, 59, 40)
$white  = [System.Drawing.Color]::White

function New-RoundedBrush {
    param([int]$Size, [System.Drawing.Color]$Color)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush($Color)
    $margin = [int]($Size * 0.03)
    $g.FillEllipse($brush, $margin, $margin, $Size - (2 * $margin), $Size - (2 * $margin))
    return @($bmp, $g, $brush)
}

# --- Logotipo cuadrado (productLogo / productIcon) ---------------------------
$size = 512
$parts = New-RoundedBrush -Size $size -Color $green
$bmp = $parts[0]; $g = $parts[1]
$font = New-Object System.Drawing.Font('Segoe UI', 260, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fmt  = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
$rect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
$g.DrawString('P!', $font, [System.Drawing.Brushes]::White, $rect, $fmt)
$logoPath = Join-Path $brandingDir 'panda-logo.png'
$bmp.Save($logoPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

# --- Imagen de bienvenida (productWelcome) -----------------------------------
$w = 640; $h = 200
$welcome = New-Object System.Drawing.Bitmap($w, $h)
$gw = [System.Drawing.Graphics]::FromImage($welcome)
$gw.SmoothingMode = 'AntiAlias'
$gw.TextRenderingHint = 'AntiAliasGridFit'
$gw.Clear([System.Drawing.Color]::Transparent)

$fTitle = New-Object System.Drawing.Font('Segoe UI', 56, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fSub   = New-Object System.Drawing.Font('Segoe UI', 22, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fmtTitle = New-Object System.Drawing.StringFormat
$fmtTitle.Alignment = 'Center'
$gw.DrawString('PandA! OS', $fTitle, (New-Object System.Drawing.SolidBrush($dark)), (New-Object System.Drawing.RectangleF(0, 40, $w, 80)), $fmtTitle)
$gw.DrawString('Oficina e inventarios · LibreOffice en espanol', $fSub, (New-Object System.Drawing.SolidBrush($green)), (New-Object System.Drawing.RectangleF(0, 120, $w, 40)), $fmtTitle)
$welcomePath = Join-Path $brandingDir 'panda-welcome.png'
$welcome.Save($welcomePath, [System.Drawing.Imaging.ImageFormat]::Png)
$gw.Dispose(); $welcome.Dispose()

# --- Icono de la aplicación (256x256) ---------------------------------------
$iconSize = 256
$pi = New-RoundedBrush -Size $iconSize -Color $green
$bi = $pi[0]; $gi = $pi[1]
$fi = New-Object System.Drawing.Font('Segoe UI', 130, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$gfi = New-Object System.Drawing.StringFormat
$gfi.Alignment = 'Center'; $gfi.LineAlignment = 'Center'
$gi.DrawString('P!', $fi, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 0, $iconSize, $iconSize)), $gfi)
$iconPath = Join-Path $iconDir 'pandaos-install.png'
$bi.Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Png)
$gi.Dispose(); $bi.Dispose()

Write-Host "Imágenes generadas:"
Write-Host "  $logoPath"
Write-Host "  $welcomePath"
Write-Host "  $iconPath"
