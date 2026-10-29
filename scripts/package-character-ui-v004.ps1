param([Parameter(Mandatory = $true)][string]$ActionSource)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskArt = Join-Path $taskRoot 'art/character_ui_v004'
$taskOut = Join-Path $taskRoot 'mobile/assets/images/character_ui_v004'
$taskGen = 'C:/Users/eido0/.codex/generated_images/01a12e79-fd12-7512-95d1-317d3caf4e83'
foreach ($dir in @($taskArt, "$taskArt/materials", "$taskArt/originals", "$taskArt/previews", $taskOut)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Copy-Item -LiteralPath "$taskRoot/art/character_ui_v003/role_logos", "$taskRoot/art/character_ui_v003/portraits" -Destination $taskArt -Recurse
Copy-Item -LiteralPath "$taskRoot/art/character_ui_v002/materialicons_license.txt" -Destination "$taskArt/materialicons_license.txt"
Copy-Item "$taskRoot/mobile/assets/images/character_ui_v003/*.png" -Destination $taskOut
Add-Type -AssemblyName System.Drawing
$taskFiles = @{
    adventurer_panel = "$taskGen/exec-9702b5c2-1c3e-4cf6-b18e-a51f14db3998.png"
    parchment_panel = "$taskGen/exec-fff83bc1-bf65-43bf-941d-2ea3be953024.png"
    action_row = $ActionSource
}
foreach ($entry in $taskFiles.GetEnumerator()) {
    Copy-Item -LiteralPath $entry.Value -Destination "$taskArt/originals/$($entry.Key).png"
    $im = [Drawing.Bitmap]::new($entry.Value)
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
# Small code-native UI ornaments; keep the vector drawing source reproducible.
$gold = [Drawing.ColorTranslator]::FromHtml('#ffd58b')
$brush = [Drawing.SolidBrush]::new($gold)
$pen = [Drawing.Pen]::new($gold,2.5)
$im = [Drawing.Bitmap]::new(192,64)
$g = [Drawing.Graphics]::FromImage($im); $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.DrawLine($pen,7,45,185,45)
$g.DrawBezier($pen,32,45,45,45,47,29,58,39)
$g.DrawBezier($pen,58,39,64,45,65,52,75,45)
$g.DrawBezier($pen,160,45,147,45,145,29,134,39)
$g.DrawBezier($pen,134,39,128,45,127,52,117,45)
$g.DrawLines($pen,[Drawing.Point[]]@([Drawing.Point]::new(76,33),[Drawing.Point]::new(80,44),[Drawing.Point]::new(88,36),[Drawing.Point]::new(96,47),[Drawing.Point]::new(104,36),[Drawing.Point]::new(112,44),[Drawing.Point]::new(116,33)))
foreach ($diamond in @(@(96,16,6,10),@(68,27,4,6),@(124,27,4,6))) {
    $cx=$diamond[0]; $cy=$diamond[1]; $dx=$diamond[2]; $dy=$diamond[3]
    $g.FillPolygon($brush,[Drawing.Point[]]@([Drawing.Point]::new($cx,$cy-$dy),[Drawing.Point]::new($cx+$dx,$cy),[Drawing.Point]::new($cx,$cy+$dy),[Drawing.Point]::new($cx-$dx,$cy)))
}
$g.Dispose(); $im.Save("$taskOut/level_icon.png"); $im.Dispose()
$im = [Drawing.Bitmap]::new(64,384); $g = [Drawing.Graphics]::FromImage($im)
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.DrawLine($pen,32,4,32,172); $g.DrawLine($pen,32,212,32,380)
$g.DrawPolygon($pen,[Drawing.Point[]]@([Drawing.Point]::new(32,177),[Drawing.Point]::new(43,192),[Drawing.Point]::new(32,207),[Drawing.Point]::new(21,192)))
$g.FillPolygon($brush,[Drawing.Point[]]@([Drawing.Point]::new(32,186),[Drawing.Point]::new(36,192),[Drawing.Point]::new(32,198),[Drawing.Point]::new(28,192)))
$g.Dispose(); $im.Save("$taskOut/identity_divider.png"); $im.Dispose(); $pen.Dispose(); $brush.Dispose()
Copy-Item "$taskOut/*.png" -Destination "$taskArt/materials"
$manifest = Get-ChildItem "$taskArt/materials/*.png" | ForEach-Object {
    $bitmap = [Drawing.Bitmap]::new($_.FullName)
    $record = @{asset=$_.Name; width=$bitmap.Width; height=$bitmap.Height; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}
    $bitmap.Dispose(); $record
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content "$taskArt/manifest.json" -Encoding utf8
Write-Output "Packaged $($manifest.Count) individual materials. v003 remains preserved."
