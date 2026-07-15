# Drift fixture: delete a resource instance from local state without OpenTofu,
# so the next `tofu plan -detailed-exitcode` reports drift (exit 2).
param([Parameter(Mandatory)][string]$StateFile)
$s = Get-Content $StateFile -Raw | ConvertFrom-Json
$s.resources = @($s.resources | Where-Object { $_.type -ne 'random_pet' })
[System.IO.File]::WriteAllText($StateFile, ($s | ConvertTo-Json -Depth 50))
Write-Output "mutated: dropped random_pet from $StateFile"
