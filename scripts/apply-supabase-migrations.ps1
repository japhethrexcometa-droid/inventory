param(
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$projectRef = "jjypcucugbtmfjynhuvh"
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
} else {
  $plainPassword = $existingPassword
}

$encodedPassword = [uri]::EscapeDataString($plainPassword)
$dbUrl = "postgresql://postgres:$encodedPassword@db.$projectRef.supabase.co:5432/postgres"

try {
  if ($DryRun) {
    & $supabaseCli db push --db-url $dbUrl --dry-run
  } else {
    & $supabaseCli db push --db-url $dbUrl
  }

  if ($LASTEXITCODE -ne 0) {
    throw "supabase db push failed with exit code $LASTEXITCODE"
  }
} finally {
  if (Get-Variable dbUrl -ErrorAction SilentlyContinue) {
    Remove-Variable dbUrl -Force
  }
  if (Get-Variable encodedPassword -ErrorAction SilentlyContinue) {
    Remove-Variable encodedPassword -Force
  }
  if (Get-Variable plainPassword -ErrorAction SilentlyContinue) {
    Remove-Variable plainPassword -Force
  }
  if (Get-Variable securePassword -ErrorAction SilentlyContinue) {
    Remove-Variable securePassword -Force
  }
}