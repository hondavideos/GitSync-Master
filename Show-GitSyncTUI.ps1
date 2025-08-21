param(
    [string]$Path,
    [switch]$DryRun
)

Import-Module "$PSScriptRoot/GitSyncTUI.psd1" -Force
Show-GitSyncTUI @PSBoundParameters
