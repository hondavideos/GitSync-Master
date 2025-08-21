#!/usr/bin/env pwsh
# Simple demonstration script for GitSyncTUI module functionality
# This script shows the core features without requiring full terminal UI capabilities

# Import the module
Write-Host "`nImporting GitSyncTUI module..." -ForegroundColor Cyan
try {
    Import-Module ./GitSyncTUI.psd1 -ErrorAction Stop
    Write-Host "Module imported successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error importing module: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n===== GitSyncTUI Module Demonstration =====" -ForegroundColor Cyan
Write-Host "This script demonstrates key functionality without requiring interactive TUI features`n"

# Check Git installation
Write-Host "Checking Git installation..." -ForegroundColor Yellow
try {
    $gitVersion = & git --version
    Write-Host "✓ Git found: $gitVersion" -ForegroundColor Green
}
catch {
    Write-Host "✗ Git not found. Please install Git to use GitSyncTUI." -ForegroundColor Red
    exit 1
}

# Display test repository status
Write-Host "`nRetrieving repository status for './TestRepo'..." -ForegroundColor Yellow
try {
    Push-Location -Path "./TestRepo"
    $repoStatus = Get-RepositoryStatus
    Pop-Location
    
    if ($repoStatus.IsGitRepository) {
        Write-Host "✓ Valid Git repository found" -ForegroundColor Green
        Write-Host "  Repository: $($repoStatus.RepoName)" -ForegroundColor Cyan
        Write-Host "  Branch: $($repoStatus.CurrentBranch)" -ForegroundColor Cyan
        
        # Check for uncommitted changes
        $hasChanges = ($repoStatus.Modified.Count -gt 0 -or 
                      $repoStatus.Untracked.Count -gt 0 -or 
                      $repoStatus.Staged.Count -gt 0 -or 
                      $repoStatus.Deleted.Count -gt 0)
        
        if ($hasChanges) {
            Write-Host "  Status: Changes detected" -ForegroundColor Yellow
            
            if ($repoStatus.Modified.Count -gt 0) {
                Write-Host "    Modified files: $($repoStatus.Modified.Count)" -ForegroundColor Yellow
            }
            if ($repoStatus.Untracked.Count -gt 0) {
                Write-Host "    Untracked files: $($repoStatus.Untracked.Count)" -ForegroundColor Yellow
            }
            if ($repoStatus.Staged.Count -gt 0) {
                Write-Host "    Staged files: $($repoStatus.Staged.Count)" -ForegroundColor Green
            }
            if ($repoStatus.Deleted.Count -gt 0) {
                Write-Host "    Deleted files: $($repoStatus.Deleted.Count)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "  Status: Clean working directory" -ForegroundColor Green
        }
    }
    else {
        Write-Host "✗ Not a Git repository" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Error checking repository status: $_" -ForegroundColor Red
}

# Create a new file in the test repository
Write-Host "`nCreating a new file in the test repository..." -ForegroundColor Yellow
try {
    Push-Location -Path "./TestRepo"
    
    # Create a new file
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $newFileName = "test_file_$timestamp.txt"
    Set-Content -Path $newFileName -Value "This is a test file created by the GitSyncTUI demo script at $timestamp"
    
    Write-Host "✓ Created new file: $newFileName" -ForegroundColor Green
    
    # Show Git status after file creation
    Write-Host "`nGit status after creating the new file:" -ForegroundColor Yellow
    $output = Invoke-GitCommand -Command "status -s"
    if ($output) {
        foreach ($line in $output) {
            Write-Host "  $line"
        }
    }
    else {
        Write-Host "  No changes detected (this is unexpected)" -ForegroundColor Red
    }
    
    # Stage the new file
    Write-Host "`nStaging the new file..." -ForegroundColor Yellow
    $output = Invoke-GitCommand -Command "add $newFileName"
    Write-Host "✓ File staged" -ForegroundColor Green
    
    # Show status after staging
    Write-Host "`nGit status after staging:" -ForegroundColor Yellow
    $output = Invoke-GitCommand -Command "status -s"
    foreach ($line in $output) {
        Write-Host "  $line"
    }
    
    # Commit the new file
    Write-Host "`nCommitting the new file..." -ForegroundColor Yellow
    $commitMessage = "Add test file via demo script"
    $output = Invoke-GitCommand -Command "commit -m `"$commitMessage`""
    Write-Host "✓ Changes committed with message: $commitMessage" -ForegroundColor Green
    Write-Host "  Commit output: $output"
    
    # Show log of recent commits
    Write-Host "`nRecent commit history:" -ForegroundColor Yellow
    $output = Invoke-GitCommand -Command "log --oneline -n 3"
    foreach ($line in $output) {
        Write-Host "  $line"
    }
    
    Pop-Location
}
catch {
    Write-Host "✗ Error during repository operations: $_" -ForegroundColor Red
    Pop-Location -ErrorAction SilentlyContinue
}

# Describe the main components of the module
Write-Host "`n===== GitSyncTUI Module Components =====" -ForegroundColor Cyan
Write-Host "The module provides the following key components:`n"

Write-Host "1. Repository Status Tracking" -ForegroundColor Yellow
Write-Host "   - Get-RepositoryStatus: Retrieves detailed Git repository information"
Write-Host "   - Show-StatusPane: Displays repository status in the TUI"

Write-Host "`n2. Git Command Execution" -ForegroundColor Yellow
Write-Host "   - Invoke-GitCommand: Safely executes Git commands with validation"
Write-Host "   - Show-CommandBuilder: Interactive command builder interface"

Write-Host "`n3. Visual Diff and Preview" -ForegroundColor Yellow
Write-Host "   - Show-Diff: Visual representation of file changes"
Write-Host "   - Show-DiffPreview: Preview of changes before committing"

Write-Host "`n4. Security Features" -ForegroundColor Yellow
Write-Host "   - Get-SecureCredential: Secure credential handling for remote operations"
Write-Host "   - Test-Credential: Validates Git credentials without exposing them"

Write-Host "`n5. Tutorial Mode" -ForegroundColor Yellow
Write-Host "   - Start-GitTutorial: Interactive Git learning experience with simulated repositories"

# Module usage examples
Write-Host "`n===== Usage Examples =====" -ForegroundColor Cyan

Write-Host "`n1. Start the Terminal UI:" -ForegroundColor Yellow
Write-Host "   Import-Module GitSyncTUI"
Write-Host "   Show-GitSyncTUI"

Write-Host "`n2. Start in Tutorial Mode:" -ForegroundColor Yellow
Write-Host "   Import-Module GitSyncTUI"
Write-Host "   Show-GitSyncTUI -Tutorial"

Write-Host "`n3. Use in Dry-Run Mode:" -ForegroundColor Yellow
Write-Host "   Import-Module GitSyncTUI"
Write-Host "   Show-GitSyncTUI -DryRun"

Write-Host "`n4. Specify Repository Path:" -ForegroundColor Yellow
Write-Host "   Import-Module GitSyncTUI"
Write-Host "   Show-GitSyncTUI -Path C:\Projects\MyRepo"

Write-Host "`n===== Demo Complete =====" -ForegroundColor Cyan
Write-Host "The module is designed to provide a rich Terminal UI experience"
Write-Host "but may have limited functionality in environments without full terminal capabilities."
Write-Host "For the best experience, run in a modern terminal like Windows Terminal, PowerShell 7+, or a Linux terminal."