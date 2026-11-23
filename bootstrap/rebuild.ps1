param([string]$Output = "build")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (![IO.Path]::IsPathRooted($Output)) { $Output = Join-Path $root $Output }
[IO.Directory]::CreateDirectory($Output) | Out-Null
$bundle = Join-Path $Output "stage1.h0"
$seed = Join-Path $PSScriptRoot "seed/h0-windows-x64.exe"
$manifest = Join-Path $PSScriptRoot "modules.txt"
$staged = "$bundle.new"
$process = Start-Process -FilePath $seed -ArgumentList 48 -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardInput $manifest -RedirectStandardOutput $staged -Wait -PassThru
if ($process.ExitCode -ne 0) { throw "H0 project bundling failed with exit status $($process.ExitCode)" }
Move-Item -LiteralPath $staged -Destination $bundle -Force
foreach ($target in @(@("h0-windows-x64.exe", 0), @("h0-linux-x64", 1))) {
    $outputPath = Join-Path $Output $target[0]
    $staged = "$outputPath.new"
    $process = Start-Process -FilePath $seed -ArgumentList $target[1] -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardInput $bundle -RedirectStandardOutput $staged -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "H0 stage1 failed for $($target[0]) with exit status $($process.ExitCode)" }
    Move-Item -LiteralPath $staged -Destination $outputPath -Force
}
