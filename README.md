# GitSyncTUI - PowerShell Terminal UI for Git Synchronization

A PowerShell-based interactive terminal UI for Git synchronization with visual command building, learning aids, and cross-platform support.

## Features

- **Interactive Terminal UI**: Multi-pane ASCII-art style interface with color highlighting
- **Visual Command Builder**: Step-by-step command building with context-sensitive options
- **Contextual Help Tooltips**: Floating tooltips provide detailed information about Git commands and options
- **Real-time Status Display**: Continuously updated repository status information
- **Interactive Tutorial Mode**: Learn Git concepts with guided examples
- **Dry Run Mode**: Preview commands without executing them
- **Visual Diff Previews**: See file changes before committing
- **Safe Git Operations**: Confirmation prompts for potentially destructive commands
- **Cross-Platform Support**: Works on Windows, macOS, and Linux with PowerShell 7+

## Requirements

- PowerShell 7.0 or later
- Git installed and available in PATH
- Terminal with ANSI color support

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/GitSyncTUI.git
   ```

2. Import the module:
   ```powershell
   Import-Module ./GitSyncTUI.psd1
   ```

## Usage

### Basic Usage

Start the Terminal UI in the current directory:

```powershell
Show-GitSyncTUI
```

### Tutorial Mode

Start the interactive Git tutorial:

```powershell
Show-GitSyncTUI -Tutorial
```

### Dry Run Mode

Preview Git commands without executing them:

```powershell
Show-GitSyncTUI -DryRun
```

### Specify Repository Path

Open a specific repository:

```powershell
Show-GitSyncTUI -Path C:\Projects\MyRepo
```

## User Interface

The UI is divided into three main panes:

1. **Status Pane**: Shows repository information, branch status, and file changes
2. **Command Builder**: Interactive menu for building Git commands
3. **Help & Tips**: Context-sensitive help information

### Navigation Keys

- **Tab**: Switch between panes
- **Arrow Keys**: Navigate within a pane
- **Enter**: Execute selected action
- **Backspace**: Remove the last command part
- **F1**: Show help
- **T**: Toggle command tooltips
- **Alt+T**: Start tutorial mode
- **Esc**: Exit the application

## Module Structure

- **Public/Show-GitSyncTUI.ps1**: Main entry point
- **Private/Git/**: Git operation functions
- **Private/UI/**: User interface components
- **Private/Security/**: Credential management
- **Private/Tutorial/**: Tutorial mode implementation

## Core Functions

### Public Functions

- **Show-GitSyncTUI**: Main terminal UI for Git synchronization

### Private Functions

- **Get-RepositoryStatus**: Retrieves detailed Git repository status
- **Invoke-GitCommand**: Safely executes Git commands with validation
- **Show-Diff**: Displays file changes in a visual format
- **Show-CommandBuilder**: Interactive command building interface
- **Show-StatusPane**: Repository status visualization
- **Show-HelpTips**: Context-sensitive help display
- **Get-GitCommandTooltip**: Provides detailed help information for Git commands
- **Show-CommandTooltip**: Displays floating tooltips with command details
- **Get-SecureCredential**: Secure credential management
- **Start-GitTutorial**: Interactive Git tutorial

## Example Workflows

### Basic Sync Workflow

1. View repository status in the Status Pane
2. Select 'pull' in the Command Builder
3. Choose 'origin' and your branch name
4. Execute the command
5. Make local changes
6. Stage and commit changes
7. Select 'push' and follow the prompts
8. Execute the push command

### Branch Management Workflow

1. Select 'branch' in the Command Builder
2. Choose 'new' to create a new branch
3. Enter branch name
4. Select 'checkout' to switch to the new branch
5. Make changes and commit them
6. Checkout main/master branch
7. Use 'merge' to integrate changes

## Notes for Use in Limited Environments

When running in environments with limited terminal capabilities:

1. Use the `-DryRun` parameter to explore functionality safely
2. Consider importing individual functions instead of launching the full TUI
3. For learning purposes, try the tutorial mode which uses simpler UI components
4. Use modern terminal applications like Windows Terminal or iTerm2 for the best experience

## Extending the Module

The module can be extended by:

1. Adding new command options in the Command Builder
2. Creating additional help content
3. Extending the tutorial with more advanced Git concepts
4. Adding support for Git hooks and integrations