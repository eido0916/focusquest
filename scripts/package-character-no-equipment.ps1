$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskArt = Join-Path $taskRoot 'art/character_ui_v003'
$taskOut = Join-Path $taskRoot 'mobile/assets/images/character_ui_v003'
$taskGen = 'C:/Users/eido0/.codex/generated_images/01a12e79-fd12-7512-95d1-317d3caf4e83'
foreach ($dir in @($taskArt, "$taskArt/materials", "$taskArt/originals", "$taskArt/previews", $taskOut)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Add-Type -AssemblyName System.Drawing
$taskFiles = @{
    adventurer_panel = 'exec-4ab108a1-d260-45a7-8c36-0143b0e6fc83.png'
    stat_row = 'exec-52690036-2c35-4a3a-a982-ffe88c8116d7.png'
    exp_track = 'exec-60bcfc5d-515f-47c8-a117-b83d921ccf1f.png'
}
foreach ($entry in $taskFiles.GetEnumerator()) {
    $source = Join-Path $taskGen $entry.Value
    Copy-Item -LiteralPath $source -Destination "$taskArt/originals/$($entry.Key).png"
    $im = [Drawing.Bitmap]::new($source)
    $left = $im.Width; $right = 0; $top = $im.Height; $bottom = 0
    for ($y = 0; $y -lt $im.Height; $y += 3) {
        for ($x = 0; $x -lt $im.Width; $x += 3) {
            if ($im.GetPixel($x, $y).A -gt 32) {
                $left = [Math]::Min($left,$x); $right = [Math]::Max($right,$x)
                $top = [Math]::Min($top,$y); $bottom = [Math]::Max($bottom,$y)
            }
        }
    }
    $left = [Math]::Max(0,$left-3); $top = [Math]::Max(0,$top-3)
    $right = [Math]::Min($im.Width-1,$right+3); $bottom = [Math]::Min($im.Height-1,$bottom+3)
    $crop = $im.Clone([Drawing.Rectangle]::new($left,$top,$right-$left+1,$bottom-$top+1),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $crop.Save("$taskOut/$($entry.Key).png",[Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose(); $im.Dispose()
}
foreach ($name in @('identity_panel','parchment_panel','header_banner','title_list_panel','certificate_icon','chevron_icon','level_icon','stat_hp','stat_defense','stat_critical')) {
    Copy-Item -LiteralPath "$taskRoot/mobile/assets/images/character_ui_v002/$name.png" -Destination "$taskOut/$name.png"
}
Copy-Item -LiteralPath "$taskRoot/mobile/assets/images/character_ui_v002/equipment_row.png" -Destination "$taskOut/action_row.png"
Copy-Item -LiteralPath "$taskRoot/mobile/assets/images/lobby/castle_courtyard.png" -Destination "$taskOut/castle_courtyard.png"
Copy-Item -LiteralPath "$taskOut/level_icon.png" -Destination "$taskOut/title_icon.png"
# Individual transparent silhouette icons matching the reference's sword and boots.
$gold = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#ffd58b'))
$im = [Drawing.Bitmap]::new(128,128)
$g = [Drawing.Graphics]::FromImage($im)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$points = [Drawing.Point[]]@([Drawing.Point]::new(100,9),[Drawing.Point]::new(107,31),[Drawing.Point]::new(61,80),[Drawing.Point]::new(49,68))
$g.FillPolygon($gold,$points)
$pen = [Drawing.Pen]::new($gold.Color,10)
$g.DrawLine($pen,34,65,73,96); $g.DrawLine($pen,48,83,23,113)
$g.FillEllipse($gold,13,103,16,16)
$g.Dispose(); $pen.Dispose(); $im.Save("$taskOut/stat_attack.png"); $im.Dispose()
$im = [Drawing.Bitmap]::new(128,128); $g = [Drawing.Graphics]::FromImage($im)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
foreach ($offset in @(0,42)) {
    $pts = [Drawing.Point[]]@([Drawing.Point]::new(30+$offset,24),[Drawing.Point]::new(54+$offset,24),[Drawing.Point]::new(51+$offset,76),[Drawing.Point]::new(68+$offset,92),[Drawing.Point]::new(65+$offset,105),[Drawing.Point]::new(19+$offset,105),[Drawing.Point]::new(23+$offset,76))
    $g.FillPolygon($gold,$pts)
    $g.FillRectangle($gold,25+$offset,16,34,11)
}
$g.Dispose(); $im.Save("$taskOut/stat_speed.png"); $im.Dispose()
$im = [Drawing.Bitmap]::new(128,128); $g = [Drawing.Graphics]::FromImage($im)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$pen = [Drawing.Pen]::new($gold.Color,3)
$g.DrawArc($pen,22,15,84,96,30,120); $g.DrawArc($pen,22,15,84,96,30+180,120)
foreach ($side in @(-1,1)) {
    for ($i = 0; $i -lt 6; $i++) {
        $angle = (38 + $i * 20) * [Math]::PI / 180
        $x = 64 + $side * 39 * [Math]::Sin($angle)
        $y = 64 - 42 * [Math]::Cos($angle)
        $state = $g.Save(); $g.TranslateTransform($x,$y); $g.RotateTransform($side * (35 + $i * 17))
        $g.FillEllipse($gold,-4,-11,8,22); $g.Restore($state)
    }
}
$g.DrawLine($pen,64,23,64,87); $g.DrawLine($pen,47,40,81,40)
$g.FillPolygon($gold,[Drawing.Point[]]@([Drawing.Point]::new(64,13),[Drawing.Point]::new(71,28),[Drawing.Point]::new(64,34),[Drawing.Point]::new(57,28)))
$g.Dispose(); $pen.Dispose(); $im.Save("$taskOut/title_icon.png"); $im.Dispose(); $gold.Dispose()
Copy-Item "$taskOut/*.png" -Destination "$taskArt/materials"
$manifest = Get-ChildItem "$taskArt/materials/*.png" | ForEach-Object {
    $bitmap = [Drawing.Bitmap]::new($_.FullName)
    $record = @{asset=$_.Name; width=$bitmap.Width; height=$bitmap.Height; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}
    $bitmap.Dispose(); $record
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content "$taskArt/manifest.json" -Encoding utf8
Write-Output "Packaged $($manifest.Count) separate materials."
