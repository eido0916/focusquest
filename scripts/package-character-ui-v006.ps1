param([string]$SourcesJson)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$fqAssemblies = @([Drawing.Bitmap].Assembly.Location, [Drawing.Rectangle].Assembly.Location,
 (Join-Path $PSHOME 'System.Runtime.dll'), (Join-Path $PSHOME 'System.Runtime.InteropServices.dll'))
$fqAssemblies += (Get-ChildItem (Join-Path $PSHOME 'System.Private.Windows.*.dll')).FullName
Add-Type -ReferencedAssemblies $fqAssemblies -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class FqTexturePack {
 public static void Normalize(string input,string output,int width,int height) {
  using(var src=new Bitmap(input)) {
   int x0=src.Width,y0=src.Height,x1=-1,y1=-1;
   var data=src.LockBits(new Rectangle(0,0,src.Width,src.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
   var bytes=new byte[Math.Abs(data.Stride)*src.Height];
   System.Runtime.InteropServices.Marshal.Copy(data.Scan0,bytes,0,bytes.Length);
   for(int y=0;y<src.Height;y++)for(int x=0;x<src.Width;x++)
    if(bytes[y*data.Stride+x*4+3]>8){x0=Math.Min(x0,x);x1=Math.Max(x1,x);y0=Math.Min(y0,y);y1=Math.Max(y1,y);}
   src.UnlockBits(data);
   if(x1<0)throw new Exception("Empty texture");
   x0=Math.Max(0,x0-2);y0=Math.Max(0,y0-2);x1=Math.Min(src.Width-1,x1+2);y1=Math.Min(src.Height-1,y1+2);
   using(var dst=new Bitmap(width,height,PixelFormat.Format32bppArgb))
   using(var g=Graphics.FromImage(dst)){
    g.Clear(Color.Transparent);g.CompositingMode=CompositingMode.SourceCopy;
    g.InterpolationMode=InterpolationMode.HighQualityBicubic;
    g.DrawImage(src,new Rectangle(0,0,width,height),new Rectangle(x0,y0,x1-x0+1,y1-y0+1),GraphicsUnit.Pixel);
    dst.Save(output,ImageFormat.Png);
   }
  }
 }
}
'@
$fqRoot=Split-Path -Parent $PSScriptRoot
$fqArt=Join-Path $fqRoot 'art/character_ui_v006'
$fqOut=Join-Path $fqRoot 'mobile/assets/images/character_ui_v006'
$fqSources=Get-Content -LiteralPath $SourcesJson -Raw | ConvertFrom-Json
$fqSizes=@{identity_panel=@(1200,210);stats_parchment=@(1200,540);info_parchment=@(1200,339);stat_row=@(600,120);action_row=@(1200,120)}
foreach($fqEntry in $fqSources.psobject.Properties){
 Copy-Item -LiteralPath $fqEntry.Value -Destination "$fqArt/originals/$($fqEntry.Name).png" -Force
 $fqSize=$fqSizes[$fqEntry.Name]
 [FqTexturePack]::Normalize($fqEntry.Value,"$fqOut/$($fqEntry.Name).png",$fqSize[0],$fqSize[1])
}
# Small native ornaments: standalone PNGs with reproducible vector drawing source.
function Save-Rule {
 $b=[Drawing.Bitmap]::new(360,24);$g=[Drawing.Graphics]::FromImage($b)
 $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
 $p=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#bc893a'),2)
 $br=[Drawing.SolidBrush]::new($p.Color)
 $g.DrawLine($p,8,12,330,12)
 foreach($v in @(10,320,344)){
  $g.FillPolygon($br,[Drawing.Point[]]@([Drawing.Point]::new($v,5),[Drawing.Point]::new($v+7,12),[Drawing.Point]::new($v,19),[Drawing.Point]::new($v-7,12)))
 }
 $b.Save("$fqOut/section_rule.png",[Drawing.Imaging.ImageFormat]::Png)
 $br.Dispose();$p.Dispose();$g.Dispose();$b.Dispose()
}
Save-Rule
foreach($fqName in @('exp_track','exp_fill')){
 $b=[Drawing.Bitmap]::new(600,30);$g=[Drawing.Graphics]::FromImage($b)
 $r=[Drawing.Rectangle]::new(1,1,597,27)
 $colors=if($fqName -eq 'exp_track'){@('#253c58','#47617c')}else{@('#68a7d1','#b6ddee')}
 $br=[Drawing.Drawing2D.LinearGradientBrush]::new($r,[Drawing.ColorTranslator]::FromHtml($colors[0]),[Drawing.ColorTranslator]::FromHtml($colors[1]),90.0)
 $g.FillRectangle($br,$r)
 if($fqName -eq 'exp_track'){
  $p=[Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml('#d8d1b2'),2);$g.DrawRectangle($p,$r);$p.Dispose()
 }
 $b.Save("$fqOut/$fqName.png",[Drawing.Imaging.ImageFormat]::Png)
 $br.Dispose();$g.Dispose();$b.Dispose()
}
$b=[Drawing.Bitmap]::new(3,90);$g=[Drawing.Graphics]::FromImage($b)
$br=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(150,210,190,130));$g.FillRectangle($br,1,0,1,90)
$b.Save("$fqOut/value_divider.png",[Drawing.Imaging.ImageFormat]::Png);$br.Dispose();$g.Dispose();$b.Dispose()
Copy-Item "$fqOut/*.png" -Destination "$fqArt/materials" -Force
$manifest=Get-ChildItem "$fqArt/materials/*.png" | ForEach-Object {
 $b=[Drawing.Bitmap]::new($_.FullName)
 $row=@{asset=$_.Name;width=$b.Width;height=$b.Height;sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}
 $b.Dispose();$row
}
$manifest|ConvertTo-Json -Depth 4|Set-Content "$fqArt/manifest.json" -Encoding utf8
Write-Output "Packaged $($manifest.Count) independent PNG materials."

