# Convert every images_raw/*.png -> images/*.jpg on a cream background.
# Incremental: skips files where the JPG already exists and is newer than the PNG.
# Usage:  pwsh scripts/convert_images.ps1  [-Force]  [-Quality 85]

param(
  [switch]$Force,
  [int]$Quality = 85
)

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'images_raw'
$dst  = Join-Path $root 'images'

Add-Type -AssemblyName System.Drawing
if (-not (Test-Path $dst)) { New-Item -ItemType Directory -Path $dst | Out-Null }

$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq 'image/jpeg' }
$params = New-Object System.Drawing.Imaging.EncoderParameters(1)
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
  [System.Drawing.Imaging.Encoder]::Quality, [long]$Quality
)

$converted = 0
$skipped   = 0

Get-ChildItem -Path $src -Filter *.png | ForEach-Object {
  $inPath  = $_.FullName
  $outPath = Join-Path $dst ($_.BaseName + '.jpg')

  if (-not $Force -and (Test-Path $outPath)) {
    $outMtime = (Get-Item $outPath).LastWriteTimeUtc
    if ($outMtime -ge $_.LastWriteTimeUtc) {
      $skipped++
      return
    }
  }

  $png = [System.Drawing.Image]::FromFile($inPath)
  $bmp = New-Object System.Drawing.Bitmap $png.Width, $png.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::FromArgb(255, 255, 246, 229))
  $g.DrawImage($png, 0, 0, $png.Width, $png.Height)
  $g.Dispose()
  $bmp.Save($outPath, $encoder, $params)
  $bmp.Dispose()
  $png.Dispose()

  $inKB  = [math]::Round($_.Length / 1KB, 1)
  $outKB = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
  "{0,-30} {1,7} KB -> {2,7} KB" -f $_.Name, $inKB, $outKB
  $converted++
}

""
"converted: $converted, skipped (up-to-date): $skipped"
