param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$supabaseCli = Join-Path $repoRoot "node_modules\.bin\supabase.CMD"
if (-not (Test-Path $supabaseCli)) {
  throw "Supabase CLI not found. Run: pnpm install"
}

$existingPassword = [Environment]::GetEnvironmentVariable("SUPABASE_DB_PASSWORD", "Process")
$setPasswordForThisRun = [string]::IsNullOrWhiteSpace($existingPassword)

if ($setPasswordForThisRun) {
  $securePassword = Read-Host "Supabase DB password" -AsSecureString
  $plainPassword = [System.Net.NetworkCredential]::new("", $securePassword).Password
  [Environment]::SetEnvironmentVariable("SUPABASE_DB_PASSWORD", $plainPassword, "Process")
}

try {
  if ($DryRun) {
    & $supabaseCli db push --dry-run
  } else {
    & $supabaseCli db push
  }

  if ($LASTEXITCODE -ne 0) {
    throw "supabase db push failed with exit code $LASTEXITCODE"
  }
} finally {
  if ($setPasswordForThisRun) {
    [Environment]::SetEnvironmentVariable("SUPABASE_DB_PASSWORD", $null, "Process")
  }
  if (Get-Variable plainPassword -ErrorAction SilentlyContinue) {
    Remove-Variable plainPassword -Force
  }
  if (Get-Variable securePassword -ErrorAction SilentlyContinue) {
    Remove-Variable securePassword -Force
  }
}