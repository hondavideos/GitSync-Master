# GitSyncTUI Usage Examples

This document provides examples of how to use individual functions from the GitSyncTUI module without running the full terminal UI. This is useful in environments with limited terminal capabilities or for users who want to leverage specific functionality programmatically.

## Importing the Module

Import the module in your PowerShell session:

```powershell
Import-Module ./GitSyncTUI.psd1
```

## Repository Status Functions

### Get Repository Status

Retrieve detailed status information from a Git repository:

```powershell
$status = Get-RepositoryStatus
Write-Host "Repository: $($status.RepoName)"
Write-Host "Branch: $($status.CurrentBranch)"
Write-Host "Modified files: $($status.Modified.Count)"
Write-Host "Untracked files: $($status.Untracked.Count)"
```

### Example: Check if Repository Has Uncommitted Changes

```powershell
$status = Get-RepositoryStatus
$hasChanges = ($status.Modified.Count -gt 0 -or 
              $status.Untracked.Count -gt 0 -or 
              $status.Staged.Count -gt 0 -or 
              $status.Deleted.Count -gt 0)

if ($hasChanges) {
    Write-Host "Repository has uncommitted changes"
} else {
    Write-Host "Working directory is clean"
}
```

## Git Command Execution

### Execute Git Commands Safely

Use `Invoke-GitCommand` to safely execute Git commands with error handling:

```powershell
# Simple status check
$output = Invoke-GitCommand -Command "status -s"
$output | ForEach-Object { Write-Host $_ }

# Pull from remote
try {
    $output = Invoke-GitCommand -Command "pull origin main"
    Write-Host "Pull successful"
} catch {
    Write-Host "Pull failed: $_"
}
```

### Example: Create and Switch to a New Branch

```powershell
$branchName = "feature-xyz"

try {
    Invoke-GitCommand -Command "checkout -b $branchName"
    Write-Host "Created and switched to branch: $branchName" -ForegroundColor Green
} catch {
    Write-Host "Failed to create branch: $_" -ForegroundColor Red
}
```

### Example: Validate Potentially Destructive Commands

```powershell
try {
    # This will show a confirmation prompt before executing
    Invoke-GitCommand -Command "push --force origin main" -ValidateDestructive
} catch {
    Write-Host "Operation cancelled or failed: $_"
}
```

## Working with Diffs

### Generate and Display a Diff Preview

```powershell
# Show diff of staged changes
$diffOutput = Invoke-GitCommand -Command "diff --staged"
Show-DiffPreview -DiffOutput $diffOutput
```

## Security Functions

### Securely Handle Git Credentials

```powershell
# Store credentials securely (will prompt for input)
$cred = Get-SecureCredential -CredentialName "github"

# Test if credentials are valid
$isValid = Test-Credential -Credential $cred
if ($isValid) {
    Write-Host "Credentials are valid"
} else {
    Write-Host "Credentials are invalid"
}
```

## Advanced Examples

### Example: Automate a Git Sync Workflow

```powershell
function Sync-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath,
        
        [Parameter()]
        [string]$RemoteName = "origin",
        
        [Parameter()]
        [string]$BranchName = "main"
    )
    
    try {
        # Navigate to repository
        Push-Location -Path $RepoPath
        
        # Get initial status
        $initialStatus = Get-RepositoryStatus
        Write-Host "Repository: $($initialStatus.RepoName)"
        Write-Host "Current branch: $($initialStatus.CurrentBranch)"
        
        # Pull changes
        Write-Host "Pulling latest changes..." -NoNewline
        Invoke-GitCommand -Command "pull $RemoteName $BranchName"
        Write-Host "Done" -ForegroundColor Green
        
        # Check for uncommitted changes
        $currentStatus = Get-RepositoryStatus
        $hasChanges = ($currentStatus.Modified.Count -gt 0 -or 
                      $currentStatus.Untracked.Count -gt 0 -or 
                      $currentStatus.Staged.Count -gt 0)
        
        if ($hasChanges) {
            Write-Host "Uncommitted changes detected:"
            if ($currentStatus.Modified.Count -gt 0) {
                Write-Host "  Modified files: $($currentStatus.Modified.Count)"
            }
            if ($currentStatus.Untracked.Count -gt 0) {
                Write-Host "  Untracked files: $($currentStatus.Untracked.Count)"
            }
            
            $commitMessage = Read-Host "Enter commit message (leave empty to skip commit)"
            
            if ($commitMessage) {
                # Stage all changes
                Invoke-GitCommand -Command "add ."
                Write-Host "Changes staged" -ForegroundColor Green
                
                # Commit changes
                Invoke-GitCommand -Command "commit -m `"$commitMessage`""
                Write-Host "Changes committed" -ForegroundColor Green
                
                # Push to remote
                Write-Host "Pushing changes..." -NoNewline
                Invoke-GitCommand -Command "push $RemoteName $BranchName"
                Write-Host "Done" -ForegroundColor Green
            }
        } else {
            Write-Host "No changes to commit. Repository is up to date."
        }
        
        # Get final status
        $finalStatus = Get-RepositoryStatus
        Write-Host "Sync complete. Ahead by $($finalStatus.Ahead) and behind by $($finalStatus.Behind) commits."
    }
    catch {
        Write-Host "Error during repository sync: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

# Usage example
Sync-GitRepository -RepoPath "C:\Projects\MyRepo" -BranchName "development"
```

### Example: Generate a Repository Status Report

```powershell
function Get-RepositoryReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$RepoPath
    )
    
    try {
        Push-Location -Path $RepoPath
        
        $status = Get-RepositoryStatus
        $branchInfo = Invoke-GitCommand -Command "branch -v"
        $remoteInfo = Invoke-GitCommand -Command "remote -v"
        $logInfo = Invoke-GitCommand -Command "log --oneline -n 5"
        
        # Create report
        $report = [PSCustomObject]@{
            RepoName = $status.RepoName
            Path = $RepoPath
            CurrentBranch = $status.CurrentBranch
            Tracking = $status.Tracking
            Ahead = $status.Ahead
            Behind = $status.Behind
            HasUncommittedChanges = ($status.Modified.Count -gt 0 -or 
                                    $status.Untracked.Count -gt 0 -or 
                                    $status.Staged.Count -gt 0)
            ModifiedCount = $status.Modified.Count
            UntrackedCount = $status.Untracked.Count
            StagedCount = $status.Staged.Count
            AllBranches = $branchInfo
            Remotes = $remoteInfo
            RecentCommits = $logInfo
        }
        
        return $report
    }
    catch {
        Write-Error "Error generating repository report: $_"
        return $null
    }
    finally {
        Pop-Location
    }
}

# Usage example
$report = Get-RepositoryReport -RepoPath "C:\Projects\MyRepo"
$report | Format-List
```

## Tutorial Mode without Full TUI

While the full tutorial experience is designed for the terminal UI, you can still run a simplified version:

```powershell
# Create a temporary directory for the tutorial
$tutorialPath = Join-Path ([System.IO.Path]::GetTempPath()) "GitTutorial"
New-Item -Path $tutorialPath -ItemType Directory -Force | Out-Null
Set-Location $tutorialPath

# Initialize repository
git init
Write-Host "Initialized tutorial repository at $tutorialPath" -ForegroundColor Green

# Create a file
Set-Content -Path "README.md" -Value "# Tutorial Project`n`nThis is a sample project for Git learning."
Write-Host "Created README.md file" -ForegroundColor Green

# Stage and commit
git add README.md
git commit -m "Initial commit"
Write-Host "Changes committed" -ForegroundColor Green

# Create a branch
git checkout -b feature
Write-Host "Created and switched to 'feature' branch" -ForegroundColor Green

# Make changes in the branch
Add-Content -Path "README.md" -Value "`n## New Feature`n- This line was added in the feature branch"
git add README.md
git commit -m "Add feature details"
Write-Host "Changes committed to feature branch" -ForegroundColor Green

# Switch back and merge
git checkout main # or master depending on your Git version
git merge feature
Write-Host "Merged feature branch back to main" -ForegroundColor Green

# Show log
git log --oneline
```

## Contextual Help System

The GitSyncTUI module includes a powerful contextual help system that provides detailed information about Git commands. These functions can be used independently to enhance your custom scripts.

### Get Command Help Information

Retrieve detailed help information for a Git command:

```powershell
# Get help information for 'git push'
$helpInfo = Get-GitCommandTooltip -CommandParts @("push")
Write-Host "Title: $($helpInfo.Title)"
Write-Host "Description: $($helpInfo.Description)"
Write-Host "Examples:"
$helpInfo.Examples | ForEach-Object { Write-Host "- $_" }
if ($helpInfo.Warning) { 
    Write-Host "Warning: $($helpInfo.Warning)" -ForegroundColor Red 
}

# Get help for a specific command option
$helpInfo = Get-GitCommandTooltip -CommandParts @("push", "--force")
Write-Host "Title: $($helpInfo.Title)"
Write-Host "Description: $($helpInfo.Description)"
if ($helpInfo.Warning) { 
    Write-Host "Warning: $($helpInfo.Warning)" -ForegroundColor Red 
}
```

### Example: Build a Custom Git Command Helper

```powershell
function Show-GitHelp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter()]
        [string]$Option
    )
    
    $commandParts = @($Command)
    if ($Option) {
        $commandParts += $Option
    }
    
    $helpInfo = Get-GitCommandTooltip -CommandParts $commandParts
    
    # Display help in a formatted way
    Write-Host $helpInfo.Title -ForegroundColor Cyan -BackgroundColor Black
    Write-Host ""
    Write-Host $helpInfo.Description
    Write-Host ""
    
    if ($helpInfo.Examples.Count -gt 0) {
        Write-Host "Examples:" -ForegroundColor Yellow
        foreach ($example in $helpInfo.Examples) {
            Write-Host "  $example"
        }
        Write-Host ""
    }
    
    if ($helpInfo.Warning) {
        Write-Host "⚠ WARNING:" -ForegroundColor Red
        Write-Host "  $($helpInfo.Warning)" -ForegroundColor Red
    }
}

# Usage example
Show-GitHelp -Command "reset" -Option "--hard"
Show-GitHelp -Command "push" -Option "--force"
Show-GitHelp -Command "pull" -Option "--rebase"
```

## Notes for Best Experience

1. For the full interactive experience, use the module in a modern terminal like Windows Terminal, iTerm2, or a native Linux terminal.
2. The module functions work best in PowerShell 7.0 or later.
3. Some visual elements may not render correctly in all terminal environments.
4. When using individual functions, be aware that they may depend on module-level variables or other functions.
5. The contextual help system contains comprehensive information about Git commands, making it useful even outside the full TUI.