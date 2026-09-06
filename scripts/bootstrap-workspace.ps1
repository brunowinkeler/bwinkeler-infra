# Requires -Version 7
<#
.SYNOPSIS
Clones every platform repository side by side into the aggregator folder.

.DESCRIPTION
Reads scripts/repos.json and clones any missing repository into the parent of
this repository, producing the layout described in docs/REPOSITORIES.md.
Existing clones are left untouched: this script never fetches, resets, or
rewrites a remote. Unlike the other scripts here, it runs on a workstation, not
on the production host.

.EXAMPLE
pwsh scripts/bootstrap-workspace.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Root
)

$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $PSScriptRoot 'repos.json'
if (-not $Root) {
    $Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is not available on PATH.'
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if (-not (Test-Path -LiteralPath $Root)) {
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
}

foreach ($repo in $manifest.repositories) {
    $target = Join-Path $Root $repo.directory

    if (Test-Path -LiteralPath (Join-Path $target '.git')) {
        Write-Host "ok: $($repo.directory) already cloned"
        continue
    }

    if (Test-Path -LiteralPath $target) {
        Write-Warning "skip: $target exists but is not a Git repository"
        continue
    }

    $arguments = @('clone')
    if ($repo.recurseSubmodules) { $arguments += '--recurse-submodules' }
    $arguments += @($repo.url, $target)

    if ($PSCmdlet.ShouldProcess($target, "git $($arguments -join ' ')")) {
        & git @arguments
        if ($LASTEXITCODE -ne 0) { throw "clone failed: $($repo.url)" }
        Write-Host "cloned: $($repo.directory)"
    }
}

Write-Host ''
Write-Host "Workspace ready at $Root"
Write-Host 'Open bwinkeler-infra/bwinkeler.code-workspace in VS Code.'
