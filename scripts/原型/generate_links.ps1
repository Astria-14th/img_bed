$rootDir = Split-Path -Parent $PSScriptRoot
$outputFile = Join-Path $PSScriptRoot "image_links.txt"
$baseUrl = "https://cdn.jsdelivr.net/gh/Astria-14th/img_bed/"
$imageExtensions = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.bmp', '*.webp')

$links = @()
Get-ChildItem -Path $rootDir -Recurse -Include $imageExtensions | ForEach-Object {
    $relativePath = $_.FullName.Substring($rootDir.Length + 1).Replace('\', '/')
    $links += $baseUrl + $relativePath
}

$uniqueLinks = $links | Sort-Object -Unique
$uniqueLinks | Out-File -FilePath $outputFile -Encoding utf8

Write-Host "已生成 $($uniqueLinks.Count) 个链接（去重后）" -ForegroundColor Green
Write-Host "输出文件: $outputFile"