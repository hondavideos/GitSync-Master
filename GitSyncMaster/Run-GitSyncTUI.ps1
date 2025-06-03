#!/usr/bin/env pwsh
# Run the GitSyncTUI module

# Import the module
Import-Module ./GitSyncTUI.psd1 -ErrorAction Stop

# Run the TUI
Show-GitSyncTUI
