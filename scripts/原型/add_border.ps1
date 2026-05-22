Add-Type -AssemblyName System.Drawing

function Trim-TransparentEdges {
    param(
        [System.Drawing.Bitmap]$img
    )

    $width = $img.Width
    $height = $img.Height

    $left = $width
    $right = 0
    $top = $height
    $bottom = 0

    for ($x = 0; $x -lt $width; $x++) {
        for ($y = 0; $y -lt $height; $y++) {
            $pixel = $img.GetPixel($x, $y)
            if ($pixel.A -gt 0) {
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }
    }

    if ($left -gt $right -or $top -gt $bottom) {
        return $img
    }

    $cropWidth = $right - $left + 1
    $cropHeight = $bottom - $top + 1

    $croppedImg = New-Object System.Drawing.Bitmap($cropWidth, $cropHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($croppedImg)
    $graphics.Clear([System.Drawing.Color]::Transparent)
    $graphics.DrawImage($img, 0, 0, [System.Drawing.Rectangle]::new($left, $top, $cropWidth, $cropHeight), [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()

    $img.Dispose()
    return $croppedImg
}

function Add-BlackBorder {
    param(
        [string]$inputPath,
        [int]$borderWidth = 3
    )

    $img = New-Object System.Drawing.Bitmap($inputPath)
    
    $img = Trim-TransparentEdges -img $img
    $width = $img.Width
    $height = $img.Height

    $newImg = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($newImg)
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $graphics.DrawImage($img, 0, 0)

    for ($x = 0; $x -lt $width; $x++) {
        for ($y = 0; $y -lt $height; $y++) {
            $pixel = $img.GetPixel($x, $y)
            if ($pixel.A -gt 0) {
                for ($dx = -$borderWidth; $dx -le $borderWidth; $dx++) {
                    for ($dy = -$borderWidth; $dy -le $borderWidth; $dy++) {
                        $nx = $x + $dx
                        $ny = $y + $dy
                        if ($nx -ge 0 -and $nx -lt $width -and $ny -ge 0 -and $ny -lt $height) {
                            $borderPixel = $newImg.GetPixel($nx, $ny)
                            if ($borderPixel.A -eq 0) {
                                $newImg.SetPixel($nx, $ny, [System.Drawing.Color]::Black)
                            }
                        }
                    }
                }
            }
        }
    }

    $graphics.DrawImage($img, 0, 0)

    $img.Dispose()
    $graphics.Dispose()

    $newImg.Save($inputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $newImg.Dispose()

    Write-Host "处理完成: $inputPath" -ForegroundColor Green
}

$clothesFolder = Join-Path (Split-Path -Parent $PSScriptRoot) "clothes"

$pngFiles = Get-ChildItem -Path $clothesFolder -Recurse -Include "*.png"
$count = 0

foreach ($file in $pngFiles) {
    Add-BlackBorder -inputPath $file.FullName -borderWidth 3
    $count++
}

Write-Host "`n全部处理完成！共处理 $count 个 PNG 文件" -ForegroundColor Cyan