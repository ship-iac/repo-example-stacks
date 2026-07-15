# Drift fixture: delete a resource instance from local state without OpenTofu,
# so the next `tofu plan -detailed-exitcode` reports drift (exit 2).
param([Parameter(Mandatory)][string]$StateFile)
# Resolve via PowerShell's own current location before handing the path to a
# .NET API: [System.IO.File] uses [Environment]::CurrentDirectory, which does
# not reliably track $PWD/Set-Location, so a relative path can silently
# resolve against the wrong directory.
$resolvedPath = (Resolve-Path -LiteralPath $StateFile).ProviderPath
$s = Get-Content $resolvedPath -Raw | ConvertFrom-Json
$s.resources = @($s.resources | Where-Object { $_.type -ne 'random_pet' })
[System.IO.File]::WriteAllText($resolvedPath, ($s | ConvertTo-Json -Depth 50))
Write-Output "mutated: dropped random_pet from $resolvedPath"
