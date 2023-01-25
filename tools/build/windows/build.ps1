# --- LRR Windows build script ---

Write-Output "🎌 Building up LRR Windows Package 🎌"
Write-Output "Inferring version from package.json..."

$json = (Get-Content "package.json" -Raw) | ConvertFrom-Json
$version = $json.version
Write-Output "Version is $version"
$env:LRR_VERSION_NUM=$version

# Use Docker image
Move-Item .\package\package.tar .\tools\build\windows\Karen\External\package.tar 

# Use Karen master
Set-Location .\tools\build\windows\Karen
Write-Output (Resolve-Path .\).Path
nuget restore

# Build Karen and Setup 
msbuild /p:Configuration=Release

Get-FileHash .\Setup\bin\LANraragi.msi | Format-List