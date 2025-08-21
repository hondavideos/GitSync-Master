# GitSyncTUI

A PowerShell-based terminal UI for Git synchronization with a visual command builder and contextual help.

## Features
- Interactive multi-pane interface
- Visual command builder
- Context-sensitive help tooltips
- Real-time repository status
- Dry run mode to preview commands
- Visual diff previews
- Cross-platform support (PowerShell 7+)

## Installation
1. Clone the repository.
2. Import the module:
   ```powershell
   Import-Module ./GitSyncTUI.psd1
   ```

## Usage
Launch the terminal UI from the repository root:
```powershell
pwsh -File ./Show-GitSyncTUI.ps1
```

Optional parameters:
- `-Path <directory>` — open a specific repository
- `-DryRun` — show commands without executing them

## Navigation
- **Tab**: switch panes
- **Arrow Keys**: navigate options
- **Enter**: select
- **T**: toggle tooltips
- **F1**: help
- **Esc** or **Alt+Q**: exit

## Module Structure
- `Public/Show-GitSyncTUI.ps1` — main entry function
- `Private/Git/` — Git operations
- `Private/UI/` — user interface components

## Development
Demo scripts, tutorial files, and sample repositories have been removed to keep the project focused on the core TUI.
