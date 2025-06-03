#!/usr/bin/env pwsh
# Demo script for GitSyncTUI that shows key features without requiring full terminal interaction

# Import the module
Import-Module ./GitSyncTUI.psd1 -ErrorAction Stop

Write-Host "`n===== GitSyncTUI Module Demo =====" -ForegroundColor Cyan
Write-Host "This demo shows the key functionality of the GitSyncTUI module`n"

# Check if Git is installed and available
try {
    $gitVersion = & git --version
    Write-Host "Git found: " -NoNewline
    Write-Host $gitVersion -ForegroundColor Green
}
catch {
    Write-Host "Git not found. Please install Git to use GitSyncTUI." -ForegroundColor Red
    exit 1
}

# Display module information
Write-Host "`nModule Information:" -ForegroundColor Yellow
$moduleInfo = Get-Module GitSyncTUI
Write-Host "  Name: $($moduleInfo.Name)"
Write-Host "  Version: $($moduleInfo.Version)"
Write-Host "  Description: $($moduleInfo.Description)"

# Get current directory Git status
Write-Host "`nCurrent Repository Status:" -ForegroundColor Yellow
try {
    $repoStatus = Get-RepositoryStatus
    
    if ($repoStatus.IsGitRepository) {
        Write-Host "  Repository: " -NoNewline
        Write-Host $repoStatus.RepoName -ForegroundColor Cyan
        
        Write-Host "  Branch: " -NoNewline
        Write-Host $repoStatus.CurrentBranch -ForegroundColor Green
        
        if ($repoStatus.Tracking) {
            Write-Host "  Tracking: " -NoNewline
            Write-Host $repoStatus.Tracking -ForegroundColor Magenta
            
            if ($repoStatus.Ahead -gt 0 -or $repoStatus.Behind -gt 0) {
                if ($repoStatus.Ahead -gt 0) {
                    Write-Host "  Ahead by: " -NoNewline
                    Write-Host "$($repoStatus.Ahead) commit(s)" -ForegroundColor Yellow
                }
                if ($repoStatus.Behind -gt 0) {
                    Write-Host "  Behind by: " -NoNewline
                    Write-Host "$($repoStatus.Behind) commit(s)" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "  Not tracking any remote branch" -ForegroundColor Yellow
        }
        
        # Display file status information
        Write-Host "`n  File Status:" -ForegroundColor Yellow
        
        if ($repoStatus.Staged.Count -eq 0 -and $repoStatus.Modified.Count -eq 0 -and 
            $repoStatus.Untracked.Count -eq 0 -and $repoStatus.Deleted.Count -eq 0) {
            Write-Host "    Clean working directory" -ForegroundColor Green
        }
        else {
            if ($repoStatus.Staged.Count -gt 0) {
                Write-Host "    Staged files: $($repoStatus.Staged.Count)" -ForegroundColor Green
                foreach ($file in $repoStatus.Staged | Select-Object -First 3) {
                    Write-Host "      + $file" -ForegroundColor Green
                }
                if ($repoStatus.Staged.Count -gt 3) {
                    Write-Host "      ... and $($repoStatus.Staged.Count - 3) more" -ForegroundColor Green
                }
            }
            
            if ($repoStatus.Modified.Count -gt 0) {
                Write-Host "    Modified files: $($repoStatus.Modified.Count)" -ForegroundColor Yellow
                foreach ($file in $repoStatus.Modified | Select-Object -First 3) {
                    Write-Host "      ~ $file" -ForegroundColor Yellow
                }
                if ($repoStatus.Modified.Count -gt 3) {
                    Write-Host "      ... and $($repoStatus.Modified.Count - 3) more" -ForegroundColor Yellow
                }
            }
            
            if ($repoStatus.Untracked.Count -gt 0) {
                Write-Host "    Untracked files: $($repoStatus.Untracked.Count)" -ForegroundColor Red
                foreach ($file in $repoStatus.Untracked | Select-Object -First 3) {
                    Write-Host "      ? $file" -ForegroundColor Red
                }
                if ($repoStatus.Untracked.Count -gt 3) {
                    Write-Host "      ... and $($repoStatus.Untracked.Count - 3) more" -ForegroundColor Red
                }
            }
            
            if ($repoStatus.Deleted.Count -gt 0) {
                Write-Host "    Deleted files: $($repoStatus.Deleted.Count)" -ForegroundColor Magenta
                foreach ($file in $repoStatus.Deleted | Select-Object -First 3) {
                    Write-Host "      - $file" -ForegroundColor Magenta
                }
                if ($repoStatus.Deleted.Count -gt 3) {
                    Write-Host "      ... and $($repoStatus.Deleted.Count - 3) more" -ForegroundColor Magenta
                }
            }
        }
    }
    else {
        Write-Host "  Not a Git repository" -ForegroundColor Red
    }
}
catch {
    Write-Host "  Error getting repository status: $_" -ForegroundColor Red
}

# Display available commands for command builder
Write-Host "`nGit Commands Available in Command Builder:" -ForegroundColor Yellow
$gitCommands = @(
    "status", "pull", "push", "commit", "branch", 
    "checkout", "merge", "fetch", "stash", "reset", 
    "clone", "remote", "log", "diff", "init"
)

$columns = 3
$maxCommandLength = ($gitCommands | Measure-Object -Property Length -Maximum).Maximum + 2
$columnWidth = $maxCommandLength + 2
$padSize = $columnWidth - 2

for ($i = 0; $i -lt $gitCommands.Count; $i++) {
    if ($i % $columns -eq 0) {
        Write-Host ""
        Write-Host "  " -NoNewline
    }
    
    Write-Host $gitCommands[$i].PadRight($padSize) -NoNewline -ForegroundColor Cyan
}
Write-Host "`n"

# Demonstrate command execution
Write-Host "Command Execution Example:" -ForegroundColor Yellow
Write-Host "  Command to execute: git status -s"

try {
    Write-Host "`n  Output:" -ForegroundColor Green
    $output = Invoke-GitCommand -Command "status -s"
    if ($output) {
        foreach ($line in $output) {
            Write-Host "    $line"
        }
    }
    else {
        Write-Host "    No output (clean working directory)" -ForegroundColor Green
    }
}
catch {
    Write-Host "  Error executing command: $_" -ForegroundColor Red
}

# Display information about tutorial mode
Write-Host "`nTutorial Mode:" -ForegroundColor Yellow
Write-Host "  The module includes an interactive tutorial mode that guides you through:"
Write-Host "  • Creating a Git repository"
Write-Host "  • Making changes and commits"
Write-Host "  • Branching and merging"
Write-Host "  • Working with remotes"
Write-Host "`n  Launch with: " -NoNewline
Write-Host "Show-GitSyncTUI -Tutorial" -ForegroundColor Cyan

# Final note
Write-Host "`nTo launch the full Terminal UI:" -ForegroundColor Yellow
Write-Host "  Show-GitSyncTUI" -ForegroundColor Cyan
Write-Host "`nNote: The full terminal UI requires an interactive terminal with ANSI color support."
Write-Host "      For best experience, run in a modern terminal like Windows Terminal, iTerm2, or a Linux terminal."
Write-Host "`n===== Demo Complete =====" -ForegroundColor Cyan