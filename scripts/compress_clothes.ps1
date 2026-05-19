Add-Type -AssemblyName System.Drawing

$rootDir = Split-Path -Parent $PSScriptRoot
$targetDir = Join-Path $rootDir "clothes"
$imageExtensions = @('*.png', '*.jpg', '*.jpeg')
$targetSizeKB = 50
$maxDimension = 400
$baseUrl = "https://cdn.jsdelivr.net/gh/Astria-14th/img_bed/"

Write-Host "Compressing images in clothes folder (excluding processed)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

Get-ChildItem -Path $targetDir -Recurse -Include $imageExtensions | Where-Object {
    $_.FullName -notmatch [regex]::Escape((Join-Path $targetDir "processed"))
} | ForEach-Object {
    $relativePath = $_.FullName.Substring($rootDir.Length + 1)
    $currentSizeKB = $_.Length / 1KB

    if ($currentSizeKB -gt $targetSizeKB) {
        Write-Host "Compressing: $relativePath ($([math]::Round($currentSizeKB, 2))KB)..." -ForegroundColor Yellow

        $img = [System.Drawing.Image]::FromFile($_.FullName)

        $newWidth = $img.Width
        $newHeight = $img.Height
        if ($newWidth -gt $maxDimension -or $newHeight -gt $maxDimension) {
            if ($newWidth -gt $newHeight) {
                $newHeight = [int]($newHeight * $maxDimension / $newWidth)
                $newWidth = $maxDimension
            } else {
                $newWidth = [int]($newWidth * $maxDimension / $newHeight)
                $newHeight = $maxDimension
            }
            Write-Host "  Resize: $($img.Width)x$($img.Height) -> ${newWidth}x${newHeight}" -ForegroundColor Yellow
        }

        $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newImg)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.Clear([System.Drawing.Color]::Transparent)
        $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)

        $tempPath = $_.FullName + ".tmp"
        
        if ($_.Extension -eq '.png') {
            $newImg.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } else {
            $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 80)
            $newImg.Save($tempPath, $encoder, $encoderParams)
        }

        $graphics.Dispose()
        $newImg.Dispose()
        $img.Dispose()

        $newSizeKB = (Get-Item $tempPath).Length / 1KB
        Remove-Item $_.FullName
        Move-Item $tempPath $_.FullName

        Write-Host "  Done! $([math]::Round($newSizeKB, 2))KB" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Generating link lists..." -ForegroundColor Cyan

Get-ChildItem -Path $targetDir -Directory | Where-Object {
    $_.Name -ne "processed"
} | ForEach-Object {
    $folderPath = $_.FullName
    $folderRelativePath = $folderPath.Substring($rootDir.Length + 1)
    $outputFile = Join-Path $folderPath "image_links.txt"
    
    $links = @()
    Get-ChildItem -Path $folderPath -Recurse -Include $imageExtensions | ForEach-Object {
        $relativePath = $_.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
        $links += $baseUrl + $relativePath
    }

    $existingLinks = @()
    if (Test-Path $outputFile) {
        $existingLinks = Get-Content $outputFile -ErrorAction SilentlyContinue
    }

    $uniqueLinks = $links | Sort-Object -Unique
    $newLinks = $uniqueLinks | Where-Object { $_ -notin $existingLinks }

    if ($newLinks.Count -gt 0) {
        $newLinks | Out-File -FilePath $outputFile -Append -Encoding utf8
        Write-Host "  $folderRelativePath : $($newLinks.Count) new links added" -ForegroundColor Green
    } else {
        Write-Host "  $folderRelativePath : no new links" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "All done!" -ForegroundColor Green