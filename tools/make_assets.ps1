# Genera imagenes del sitio: diagrama de DwgMerge y tarjeta para compartir (Open Graph).
# GDI+ (System.Drawing). ASCII-only a proposito (PowerShell 5.1 lee .ps1 como ANSI).
#   .\tools\make_assets.ps1   ->  img\dwgmerge-merge.png, img\og-card.png

Add-Type -AssemblyName System.Drawing

$root = Split-Path $PSScriptRoot -Parent
$img  = Join-Path $root "img"

$ink   = [System.Drawing.Color]::FromArgb(0x22,0x33,0x44)
$gray  = [System.Drawing.Color]::FromArgb(0x6B,0x77,0x85)
$light = [System.Drawing.Color]::FromArgb(0xE3,0xE8,0xEE)
$red   = [System.Drawing.Color]::FromArgb(0xC0,0x39,0x2B)
$green = [System.Drawing.Color]::FromArgb(0x1E,0x8E,0x3E)
$blue  = [System.Drawing.Color]::FromArgb(0x2E,0x86,0xC1)
$teal  = [System.Drawing.Color]::FromArgb(0x17,0xA5,0x89)

$center = New-Object System.Drawing.StringFormat
$center.Alignment = [System.Drawing.StringAlignment]::Center
$center.LineAlignment = [System.Drawing.StringAlignment]::Center
$left = New-Object System.Drawing.StringFormat
$left.LineAlignment = [System.Drawing.StringAlignment]::Center

function New-Gfx([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $gr = [System.Drawing.Graphics]::FromImage($bmp)
    $gr.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gr.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    $gr.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    return ,@($bmp, $gr)
}

function F([single]$size, [bool]$bold) {
    if ($bold) { $st = [System.Drawing.FontStyle]::Bold } else { $st = [System.Drawing.FontStyle]::Regular }
    return New-Object System.Drawing.Font("Arial", $size, $st, [System.Drawing.GraphicsUnit]::Pixel)
}

function Text([System.Drawing.Graphics]$gr, [string]$t, [System.Drawing.Font]$f, [System.Drawing.Color]$c, [single]$x, [single]$y, [single]$w, [single]$h, $fmt) {
    $b = New-Object System.Drawing.SolidBrush($c)
    $gr.DrawString($t, $f, $b, (New-Object System.Drawing.RectangleF($x, $y, $w, $h)), $fmt)
}

function RoundRect([single]$x, [single]$y, [single]$w, [single]$h, [single]$r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = 2 * $r
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# Una lamina: rectangulo con cajetin abajo a la derecha y "contenido" esquematico.
function Sheet([System.Drawing.Graphics]$gr, [single]$x, [single]$y, [single]$w, [single]$h, [string]$name) {
    $white = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen($ink, 2.0)
    $thin = New-Object System.Drawing.Pen($gray, 1.2)
    $gr.FillRectangle($white, $x, $y, $w, $h)
    $gr.DrawRectangle($pen, $x, $y, $w, $h)
    # contenido esquematico (planta)
    $gr.DrawRectangle($thin, ($x + 14), ($y + 14), ($w * 0.55), ($h * 0.55))
    $gr.DrawLine($thin, ($x + 14), ($y + 14 + $h * 0.3), ($x + 14 + $w * 0.55), ($y + 14 + $h * 0.3))
    $gr.DrawLine($thin, ($x + 14 + $w * 0.3), ($y + 14), ($x + 14 + $w * 0.3), ($y + 14 + $h * 0.55))
    # cajetin
    $tbw = $w * 0.42; $tbh = $h * 0.22
    $gr.DrawRectangle($pen, ($x + $w - $tbw - 8), ($y + $h - $tbh - 8), $tbw, $tbh)
    Text $gr $name (F 16 $true) $ink ($x + $w - $tbw - 8) ($y + $h - $tbh - 8) $tbw $tbh $center
}

# ============ DwgMerge: muchas laminas -> un DWG con un layout por lamina ============
$o = New-Gfx 1600 900; $bmp = $o[0]; $g = $o[1]
$g.Clear([System.Drawing.Color]::White)
$band = New-Object System.Drawing.RectangleF(0, 0, 1600, 96)
$g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($band, $blue, $teal, 0.0)), $band)
Text $g "Export sheets and merge them into one DWG" (F 34 $true) ([System.Drawing.Color]::White) 40 0 1520 96 $left

Text $g "BEFORE - one file per sheet" (F 24 $true) $red 120 120 560 34 $center
Text $g "AFTER - one DWG, one layout per sheet" (F 24 $true) $green 900 120 600 34 $center

# Izquierda: 4 laminas sueltas, cada una con su icono de archivo.
$names = @("A-101", "A-102", "A-103", "A-104")
for ($i = 0; $i -lt 4; $i++) {
    $col = $i % 2; $row = [Math]::Floor($i / 2)
    $sx = 150 + $col * 270; $sy = 190 + $row * 330
    Sheet $g $sx $sy 240 170 $names[$i]
    Text $g ($names[$i] + ".dwg") (F 18 $false) $gray $sx ($sy + 180) 240 26 $center
}

# Flecha
$ap = New-Object System.Drawing.Pen($blue, 6.0)
$ap.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
$g.DrawLine($ap, [single]730, [single]480, [single]870, [single]480)

# Derecha: ventana de un unico DWG con pestanas de layout.
$wx = 900; $wy = 180; $ww = 600; $wh = 560
$frame = RoundRect $wx $wy $ww $wh 12
$g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0xF5,0xF7,0xF9))), $frame)
$g.DrawPath((New-Object System.Drawing.Pen($ink, 2.0)), $frame)
# barra de titulo
$g.FillRectangle((New-Object System.Drawing.SolidBrush($ink)), ($wx + 1), ($wy + 1), ($ww - 2), 40)
Text $g "Project_Sheets.dwg" (F 20 $true) ([System.Drawing.Color]::White) ($wx + 16) ($wy + 1) 400 40 $left
# hoja activa
Sheet $g ($wx + 70) ($wy + 70) 460 330 "A-101"
# pestanas de layout
$tabs = @("Model", "A-101", "A-102", "A-103", "A-104")
$tx = $wx + 16
for ($i = 0; $i -lt $tabs.Count; $i++) {
    $tw = 104
    if ($i -eq 1) { $fill = [System.Drawing.Color]::White } else { $fill = $light }
    $g.FillRectangle((New-Object System.Drawing.SolidBrush($fill)), $tx, ($wy + $wh - 64), ($tw - 4), 40)
    $g.DrawRectangle((New-Object System.Drawing.Pen($gray, 1.2)), $tx, ($wy + $wh - 64), ($tw - 4), 40)
    Text $g $tabs[$i] (F 17 ($i -eq 1)) $ink $tx ($wy + $wh - 64) ($tw - 4) 40 $center
    $tx += $tw
}
$bmp.Save((Join-Path $img "dwgmerge-merge.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "Generado: img\dwgmerge-merge.png" -ForegroundColor Green

# ============ Tarjeta Open Graph 1200x630 ============
$o = New-Gfx 1200 630; $bmp = $o[0]; $g = $o[1]
$all = New-Object System.Drawing.RectangleF(0, 0, 1200, 630)
$g.FillRectangle((New-Object System.Drawing.Drawing2D.LinearGradientBrush($all, $blue, $teal, 35.0)), $all)
# marca DL
$mark = RoundRect 80 90 120 120 26
$g.FillPath((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(60,255,255,255))), $mark)
Text $g "DL" (F 56 $true) ([System.Drawing.Color]::White) 80 90 120 120 $center
Text $g "Dynamo Labs" (F 72 $true) ([System.Drawing.Color]::White) 230 90 900 120 $left
Text $g "Productivity add-ins for Autodesk Revit" (F 36 $false) ([System.Drawing.Color]::White) 80 250 1050 60 $left
Text $g "Revit 2018-2027  |  Multilingual  |  Autodesk App Store" (F 26 $false) ([System.Drawing.Color]::FromArgb(230,255,255,255)) 80 320 1050 50 $left
# iconos de las apps
$i1 = [System.Drawing.Image]::FromFile((Join-Path $img "gridautonumber-icon.png"))
$i2 = [System.Drawing.Image]::FromFile((Join-Path $img "dwgmerge-icon.png"))
$g.DrawImage($i1, 80, 420, 130, 130)
$g.DrawImage($i2, 240, 420, 130, 130)
Text $g "Grid Auto Number  +  DwgMerge" (F 30 $true) ([System.Drawing.Color]::White) 400 420 760 130 $left
$i1.Dispose(); $i2.Dispose()
$bmp.Save((Join-Path $img "og-card.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "Generado: img\og-card.png" -ForegroundColor Green
