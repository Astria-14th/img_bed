Add-Type -AssemblyName System.Drawing

$rootDir = Split-Path -Parent $PSScriptRoot
$targetDir = Join-Path $rootDir "phone\head_pic"
$imageExtensions = @('*.png', '*.jpg', '*.jpeg')
$targetSizeKB = 100
$maxDimension = 400

Get-ChildItem -Path $targetDir -Recurse -Include $imageExtensions | ForEach-Object {
    $relativePath = $_.FullName.Substring($rootDir.Length + 1)
    $currentSizeKB = $_.Length / 1KB

    if ($currentSizeKB -gt $targetSizeKB) {
        Write-Host "压缩: $relativePath (当前: $([math]::Round($currentSizeKB, 2))KB) ..."

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
            Write-Host "  调整尺寸: $($img.Width)x$($img.Height) -> ${newWidth}x${newHeight}" -ForegroundColor Yellow
        }

        $newImg = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newImg)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.DrawImage($img, 0, 0, $newWidth, $newHeight)

        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 15)

        $tempPath = $_.FullName + ".tmp"
        $newImg.Save($tempPath, $encoder, $encoderParams)

        $graphics.Dispose()
        $newImg.Dispose()
        $img.Dispose()

        $newSizeKB = (Get-Item $tempPath).Length / 1KB
        $savedKB = $currentSizeKB - $newSizeKB
        Write-Host "  完成! $([math]::Round($newSizeKB, 2))KB (节省 $([math]::Round($savedKB, 2))KB)" -ForegroundColor Green

        Remove-Item $_.FullName
        Move-Item $tempPath $_.FullName
    } else {
        Write-Host "跳过: $relativePath ($([math]::Round($currentSizeKB, 2))KB < 100KB)" -ForegroundColor Gray
    }
}

$outputFile = Join-Path $rootDir "image_links_headpic.txt"
$baseUrl = "https://cdn.jsdelivr.net/gh/Astria-14th/img_bed/"
$links = @()
Get-ChildItem -Path $targetDir -Recurse -Include $imageExtensions | ForEach-Object {
    $relativePath = $_.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    $links += $baseUrl + $relativePath
}

$existingLinks = @()
if (Test-Path $outputFile) {
    $existingLinks = Get-Content $outputFile
}

$uniqueLinks = $links | Sort-Object -Unique
$newLinks = $uniqueLinks | Where-Object { $_ -notin $existingLinks }

if ($newLinks.Count -gt 0) {
    $newLinks | Out-File -FilePath $outputFile -Append -Encoding utf8
    Write-Host "`n已追加 $($newLinks.Count) 个新链接到 image_links_headpic.txt" -ForegroundColor Green
} else {
    Write-Host "`n没有新链接需要添加（全部已存在）" -ForegroundColor Yellow
}

Write-Host "输出文件: $outputFile" -ForegroundColor Cyan
Write-Host "`n全部压缩完成!" -ForegroundColor Cyan
