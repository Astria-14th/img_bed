Add-Type -AssemblyName System.Drawing

$targetDir = $PSScriptRoot
$outputDir = Split-Path -Parent $PSScriptRoot

Write-Host "Image Splitter Tool" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

$cols = Read-Host "Enter number of columns"
$rows = Read-Host "Enter number of rows"

if (-not ($cols -match '^\d+$') -or -not ($rows -match '^\d+$')) {
    Write-Host "Error: Please enter valid numbers" -ForegroundColor Red
    exit 1
}

$cols = [int]$cols
$rows = [int]$rows

if ($cols -le 0 -or $rows -le 0) {
    Write-Host "Error: Rows and columns must be greater than 0" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$images = Get-ChildItem -Path $targetDir -Filter '*.png'
$images += Get-ChildItem -Path $targetDir -Filter '*.jpg'
$images += Get-ChildItem -Path $targetDir -Filter '*.jpeg'

if ($images.Count -eq 0) {
    Write-Host "No image files found" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($images.Count) images, will split into ${rows}x${cols} = $($rows * $cols) pieces" -ForegroundColor Green
Write-Host ""

$totalPieces = 0
foreach ($image in $images) {
    Write-Host "Processing: $($image.Name)" -ForegroundColor Cyan

    $img = [System.Drawing.Image]::FromFile($image.FullName)
    $width = $img.Width
    $height = $img.Height

    $pieceWidth = [int]($width / $cols)
    $pieceHeight = [int]($height / $rows)

    if ($pieceWidth -eq 0 -or $pieceHeight -eq 0) {
        Write-Host "  Warning: Image too small to split, skipping" -ForegroundColor Yellow
        $img.Dispose()
        continue
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($image.Name)

    for ($r = 0; $r -lt $rows; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            $x = $c * $pieceWidth
            $y = $r * $pieceHeight

            $bitmap = New-Object System.Drawing.Bitmap($pieceWidth, $pieceHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $graphics.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $pieceWidth, $pieceHeight)), (New-Object System.Drawing.Rectangle($x, $y, $pieceWidth, $pieceHeight)), [System.Drawing.GraphicsUnit]::Pixel)

            $outputName = "${baseName}_r${r}_c${c}$($image.Extension)"
            $bitmap.Save((Join-Path $outputDir $outputName))

            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    $piecesCount = $rows * $cols
    $totalPieces += $piecesCount
    Write-Host "  Done: ${width}x${height} -> ${piecesCount} pieces (each ${pieceWidth}x${pieceHeight})" -ForegroundColor Green

    $img.Dispose()
}

Write-Host ""
Write-Host "================" -ForegroundColor Cyan
Write-Host "Completed! Total pieces created: $totalPieces" -ForegroundColor Green
Write-Host "Output directory: $outputDir" -ForegroundColor Cyan