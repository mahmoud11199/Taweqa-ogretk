# Download Cairo variable font for the project
$fontDir = Join-Path $PSScriptRoot "..\assets\fonts"
New-Item -ItemType Directory -Path $fontDir -Force | Out-Null

$url = "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf"
$out = Join-Path $fontDir "Cairo-Variable.ttf"

Write-Host "Downloading Cairo variable font..."
Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
Write-Host "Done! ($((Get-Item $out).Length) bytes saved to $fontDir)"
