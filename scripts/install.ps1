# codegraph quick-install for Windows.
#
# Usage:
#   iwr https://github.com/peterctwang/codegraph-rust-public/raw/main/scripts/install.ps1 | iex
#
# Does:
#   1. Detects CPU.
#   2. Downloads the matching codegraph release binary (public — no token).
#   3. Drops it at $env:USERPROFILE\.codegraph\bin\codegraph.exe and adds
#      that dir to your user PATH.
#   4. Runs `codegraph install --location global` — writes MCP config for
#      every installed agent (Claude Code, Cursor, Codex CLI, opencode).
#
# No GitHub token needed — this repo and its releases are public.

$ErrorActionPreference = "Stop"
$Owner   = "peterctwang"
$Repo    = "codegraph-rust-public"
$Version = if ($env:CODEGRAPH_VERSION) { $env:CODEGRAPH_VERSION } else { "latest" }

function Resolve-Target {
    $arch = $env:PROCESSOR_ARCHITECTURE
    switch ($arch) {
        "AMD64" { return "x86_64-pc-windows-msvc" }
        "ARM64" {
            Write-Warning "No Windows arm64 binary published yet — falling back to x64 (runs under emulation)."
            return "x86_64-pc-windows-msvc"
        }
        default { throw "Unsupported Windows arch: $arch" }
    }
}

function Get-AssetUrl([string]$Target) {
    if ($Version -eq "latest") {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    } else {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$Version"
    }
    $headers = @{ "User-Agent" = "codegraph-installer"; "Accept" = "application/vnd.github+json" }
    $rel = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    $assetName = "codegraph-rust-$Target.exe"
    $asset = $rel.assets | Where-Object { $_.name -eq $assetName }
    if (-not $asset) { throw "No asset $assetName on release $($rel.tag_name)" }
    return @{ Url = $asset.browser_download_url; Tag = $rel.tag_name }
}

function Ensure-OnPath([string]$Dir) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -split ";" -contains $Dir) { return }
    $newPath = if ($userPath) { "$userPath;$Dir" } else { $Dir }
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$env:PATH;$Dir"
    Write-Host "Added $Dir to your user PATH. Open a new shell or reload your profile."
}

$target = Resolve-Target
Write-Host "Resolved target: $target"
$info = Get-AssetUrl -Target $target
Write-Host "Downloading codegraph $($info.Tag)…"

$binDir = Join-Path $env:USERPROFILE ".codegraph\bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$binPath = Join-Path $binDir "codegraph-rust.exe"

Invoke-WebRequest -Uri $info.Url -OutFile $binPath -UseBasicParsing
Write-Host "Wrote $binPath"

Ensure-OnPath -Dir $binDir

Write-Host "Wiring MCP config into installed agents…"
& $binPath install --location global

Write-Host ""
Write-Host "codegraph $($info.Tag) is ready. Restart Claude Code / Cursor to pick up the MCP server."
Write-Host "Then in any project:  codegraph init  &&  codegraph index"
