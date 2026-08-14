param([switch]$wait)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

# robocopy signals success with exit codes 1-7; under PowerShell 7.4+ those would
# otherwise throw, because ErrorActionPreference=Stop applies to native commands there
if (Get-Variable PSNativeCommandUseErrorActionPreference -EA 0) {
  $PSNativeCommandUseErrorActionPreference = $false
}

# ---- configure these two ----------------------------------------------------

$repo = "you/your-context-repo"

# project folder in repo  ->  local destination
$map = @{
  "example" = "C:\path\to\wherever\you\want\it"
}

# -----------------------------------------------------------------------------

$log = Join-Path $PSScriptRoot "pull-problems.log"

# Files that live in a destination but are not in the matching contexts/ folder.
# /MIR would delete them. Harmless if your destinations are separate from the
# folder this script runs from; essential if any destination IS that folder,
# because pat.txt would be the first thing to go.
$keep = @("pat.txt", "pull-problems.log", "pull-context.ps1")

# Say  -> console only. A pull that worked leaves no trace on disk.
# Flag -> console and the log. Problems only, so the log is all signal.
$problems = @()
function Say($msg)  { Write-Host $msg }
function Flag($msg) {
  $script:problems += "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  Write-Host $msg
}

$failed = $null
try {
  $patFile = Join-Path $PSScriptRoot "pat.txt"
  if (-not (Test-Path $patFile))          { throw "pat.txt not found next to the script" }
  $pat = (Get-Content $patFile -Raw).Trim()
  if ([string]::IsNullOrWhiteSpace($pat)) { throw "pat.txt is empty" }

  $tmp = "$env:TEMP\ctx"
  Remove-Item $tmp, "$tmp.zip" -Recurse -Force -EA 0
  Invoke-WebRequest "https://api.github.com/repos/$repo/zipball/main" -Headers @{Authorization="Bearer $pat"} -OutFile "$tmp.zip"
  Expand-Archive "$tmp.zip" $tmp -Force
  $src = (Get-ChildItem $tmp -Directory)[0].FullName

  foreach ($k in $map.Keys) {
    $from = Join-Path $src "contexts\$k"
    if (Test-Path $from) {
      robocopy $from $map[$k] /MIR /XF $keep /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
      if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $k (exit $LASTEXITCODE)" }
      Say "$k -> $($map[$k])  ($((Get-ChildItem $map[$k] -File).Count) files)"
    } else {
      # mapped but absent from the repo: not fatal, but someone should know
      Flag "$k -> no folder in repo, skipped"
    }
  }

  # The script deploys itself: the zipball just unpacked contains the root copy,
  # so a change pushed to the repo reaches the PC with no manual step. Best effort
  # -- a failure here must not fail the pull, and the next run retries.
  try {
    $new = Join-Path $src "pull-context.ps1"
    $me  = Join-Path $PSScriptRoot "pull-context.ps1"
    if (Test-Path $new) {
      if ((Get-FileHash $new).Hash -ne (Get-FileHash $me).Hash) {
        Copy-Item $new $me -Force
        Say "script updated from repo root"
      }
    } else {
      Flag "script not found at repo root, self-update skipped"
    }
  } catch {
    Flag "self-update skipped: $($_.Exception.Message)"
  }

  Say "OK"
}
catch {
  $failed = $_.Exception.Message
  Flag "FAILED: $failed"
}

# The log records problems only, so a clean run must not touch it at all -- its
# timestamp is meant to answer "when did this last go wrong", and no file means never.
if ($problems.Count -gt 0) {
  try {
    # assign in two steps: an if-expression unrolls a 1-element array back to a string
    $old = @()
    if (Test-Path $log) { $old = @(Get-Content $log -EA 0) }
    $all = @($old + $problems) | Select-Object -Last 200
    # join explicitly: Set-Content's trailing-newline behaviour differs across PS versions
    Set-Content $log -Value (($all -join "`r`n") + "`r`n") -NoNewline -Encoding UTF8
  } catch { }
}

# a scheduled run is hidden, so a failure has to announce itself
if ($failed -and -not $wait) {
  try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
      "$failed`n`nLog: $log", "Claude context pull failed", 'OK', 'Error') | Out-Null
  } catch { }
}

if ($wait) {
  Write-Host "`nPress any key..." -NoNewline
  $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
