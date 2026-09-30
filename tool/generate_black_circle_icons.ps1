# Generate PrivateAgent black-circle launcher icons + in-app logo.
# Replaces tool/generate_icons.py (which required Pillow + a hardcoded macOS path).
# Design: solid black circle, no text/gradient/shadow — see UI_REDESIGN_PLAN.md.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tool\generate_black_circle_icons.ps1
#
# Outputs:
#   android/app/src/main/res/mipmap-{mdpi..xxxhdpi}/ic_launcher.png  (legacy fallback)
#   assets/icon/genie_logo.png                                      (in-app branding)
#   web/favicon.png, web/icons/Icon-{192,512}.png, Icon-maskable-*  (web scaffold)
# Adaptive foreground/background are handled by XML (drawable vector + color),
# not by this script; obsolete *_foreground.png / *_background.png are deleted here.

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$res  = Join-Path $root 'android\app\src\main\res'
$web  = Join-Path $root 'web'

function New-CirclePng {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][int]$Size,
        [double]$DiameterFrac = 0.86,
        [ValidateSet('transparent', 'white')][string]$Background = 'transparent'
    )
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    try {
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.SmoothingMode = 'AntiAlias'
            $g.PixelOffsetMode = 'HighQuality'
            if ($Background -eq 'white') {
                $g.Clear([System.Drawing.Color]::FromArgb(255, 255, 255))
            } else {
                $g.Clear([System.Drawing.Color]::Transparent)
            }
            $d = [int][math]::Round($Size * $DiameterFrac)
            $off = [int][math]::Round(($Size - $d) / 2.0)
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 0, 0))
            try { $g.FillEllipse($brush, $off, $off, $d, $d) } finally { $brush.Dispose() }
        } finally { $g.Dispose() }

        $dir = Split-Path -Parent $Path
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
        $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output "wrote $Path  ($Size px, circle $([int]($DiameterFrac * 100))%, $Background bg)"
    } finally { $bmp.Dispose() }
}

# --- Android legacy launcher icons (fallback for @mipmap/ic_launcher) -------
$launcher = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($density in $launcher.Keys) {
    New-CirclePng -Path (Join-Path $res "mipmap-$density\ic_launcher.png") `
        -Size $launcher[$density] -DiameterFrac 0.86 -Background transparent
    # Remove obsolete indigo/amber adaptive art (replaced by vector + color XML).
    foreach ($obsolete in @('ic_launcher_foreground.png', 'ic_launcher_background.png')) {
        $p = Join-Path $res "mipmap-$density\$obsolete"
        if (Test-Path $p) { Remove-Item $p -Force; Write-Output "removed $p" }
    }
}

# --- In-app logo (AppBar + drawer) -------------------------------------------
New-CirclePng -Path (Join-Path $root 'assets\icon\genie_logo.png') `
    -Size 512 -DiameterFrac 0.96 -Background transparent

# --- Web scaffold icons ------------------------------------------------------
New-CirclePng -Path (Join-Path $web 'favicon.png') `
    -Size 16 -DiameterFrac 0.94 -Background transparent
foreach ($n in @(192, 512)) {
    New-CirclePng -Path (Join-Path $web "icons\Icon-$n.png") `
        -Size $n -DiameterFrac 0.84 -Background white
    # Maskable: full-bleed background, circle inside the 80%-diameter safe zone.
    New-CirclePng -Path (Join-Path $web "icons\Icon-maskable-$n.png") `
        -Size $n -DiameterFrac 0.62 -Background white
}

Write-Output 'done.'
