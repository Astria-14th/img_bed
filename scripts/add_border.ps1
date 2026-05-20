Add-Type -AssemblyName System.Drawing

function Add-BlackBorder {
    param(
        [string]$inputPath,
        [int]$borderWidth = 2
    )

    $img = [System.Drawing.Image]::FromFile($inputPath)
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
    Add-BlackBorder -inputPath $file.FullName -borderWidth 2
    $count++
}

Write-Host "`n全部处理完成！共处理 $count 个 PNG 文件" -ForegroundColor Cyan