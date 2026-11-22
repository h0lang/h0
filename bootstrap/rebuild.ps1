param([string]$Output = "build")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (![IO.Path]::IsPathRooted($Output)) { $Output = Join-Path $root $Output }
[IO.Directory]::CreateDirectory($Output) | Out-Null
$bundle = Join-Path $Output "stage1.h0"
$io = [IO.File]::ReadAllLines((Join-Path $root "std/io.h0"))
$lines = @("#!f") + $io[0..3]
foreach ($module in [IO.File]::ReadAllLines((Join-Path $PSScriptRoot "modules.txt"))) {
    $lines += [IO.File]::ReadAllLines((Join-Path $root $module))
}
$lines += $io[4..($io.Length - 1)]
[IO.File]::WriteAllText($bundle, ($lines -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
$seed = Join-Path $PSScriptRoot "seed/h0-windows-x64.exe"
foreach ($target in @(@("h0-windows-x64.exe", 0), @("h0-linux-x64", 1))) {
    $outputPath = Join-Path $Output $target[0]
    $staged = "$outputPath.new"
    $process = Start-Process -FilePath $seed -ArgumentList $target[1] -WorkingDirectory $root -WindowStyle Hidden -RedirectStandardInput $bundle -RedirectStandardOutput $staged -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "H0 stage1 failed for $($target[0]) with exit status $($process.ExitCode)" }
    Move-Item -LiteralPath $staged -Destination $outputPath -Force
}
