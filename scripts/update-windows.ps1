param(
    [Parameter(Mandatory = $true)]
    [string]$Root
)

$ErrorActionPreference = "Stop"

$CacheDir   = Join-Path $Root ".cache"
$RuntimeDir = Join-Path $CacheDir "runtimes\windows-x64"
$SrcDir     = Join-Path $Root "src"
$TempDir    = Join-Path $Root ".tmp"
$SourceUrl  = "https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.zip"

Write-Host "Downloading the latest Hermes Agent from GitHub..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$srcArchive = Join-Path $RuntimeDir "source.zip"
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    $curlArgs = @("-L", "-f", "--ssl-no-revoke", "-o", $srcArchive, $SourceUrl)
    & curl.exe @curlArgs
} else {
    Invoke-WebRequest -Uri $SourceUrl -OutFile $srcArchive -UseBasicParsing
}

Write-Host "Extracting and installing the latest version..." -ForegroundColor Cyan
$srcTemp = Join-Path $TempDir "source"
if (Test-Path $srcTemp) { Remove-Item $srcTemp -Recurse -Force -ErrorAction SilentlyContinue }
Expand-Archive -Path $srcArchive -DestinationPath $srcTemp -Force

$srcSub = Get-ChildItem $srcTemp -Directory | Select-Object -First 1
if (-not $srcSub) {
    throw "Hermes source archive did not contain a source folder"
}

$destSrc = Join-Path $SrcDir "hermes-agent"
if (Test-Path $destSrc) {
    try {
        Remove-Item $destSrc -Recurse -Force -ErrorAction Stop
    } catch {
        Get-ChildItem $destSrc -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
New-Item -ItemType Directory -Force -Path $destSrc | Out-Null
Copy-Item (Join-Path $srcSub.FullName "*") $destSrc -Recurse -Force

$venvPython = Join-Path $RuntimeDir "venv\Scripts\python.exe"
$uvExe      = Join-Path $RuntimeDir "uv\uv.exe"

Write-Host "Updating dependencies..." -ForegroundColor Cyan
if (Test-Path $uvExe) {
    & $uvExe pip install --python $venvPython --link-mode=copy -e "$destSrc[all]"
} else {
    & $venvPython -m pip install -e "$destSrc[all]"
}

Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Hermes core updated successfully!" -ForegroundColor Green
