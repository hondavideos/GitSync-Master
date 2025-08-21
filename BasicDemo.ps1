#!/usr/bin/env pwsh
# Basic demonstration of GitSyncTUI module functionality
# Minimalist version without terminal UI dependencies

Write-Output "Importing module..."
try {
    Import-Module ./GitSyncTUI.psd1 -ErrorAction Stop
    Write-Output "Module imported successfully!"
}
catch {
    Write-Output "Error importing module: $_"
    exit 1
}

Write-Output ""
Write-Output "===== GitSyncTUI Basic Demo ====="
Write-Output ""

# Check Git installation
Write-Output "Checking Git installation..."
try {
    $gitVersion = & git --version
    Write-Output "Git found: $gitVersion"
}
catch {
    Write-Output "Git not found. Please install Git to use GitSyncTUI."
    exit 1
}

# Display module information
Write-Output ""
Write-Output "Module Information:"
$moduleInfo = Get-Module GitSyncTUI
Write-Output "  Name: $($moduleInfo.Name)"
Write-Output "  Version: $($moduleInfo.Version)"
Write-Output "  Description: $($moduleInfo.Description)"

# Display test repository status
Write-Output ""
Write-Output "Testing repository functions with './TestRepo'..."
try {
    Push-Location -Path "./TestRepo"
    Write-Output "Current location: $(Get-Location)"
    
    # Create a test file
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $newFileName = "test_file_$timestamp.txt"
    Set-Content -Path $newFileName -Value "Test file created at $timestamp"
    Write-Output "Created test file: $newFileName"
    
    # Get status using direct git command (not module function)
    $status = & git status -s
    Write-Output "Git status after file creation:"
    Write-Output $status
    
    # Stage the file
    & git add $newFileName
    Write-Output "File staged"
    
    # Commit the file
    $commitOutput = & git commit -m "Add test file via basic demo"
    Write-Output "File committed:"
    Write-Output $commitOutput
    
    # Show recent commits
    $log = & git log --oneline -n 2
    Write-Output "Recent commits:"
    Write-Output $log
    
    Pop-Location
}
catch {
    Write-Output "Error during repository operations: $_"
    Pop-Location -ErrorAction SilentlyContinue
}

# Describe available functions
Write-Output ""
Write-Output "===== Available Module Functions ====="
Write-Output ""
Write-Output "Public functions:"
Write-Output "  * Show-GitSyncTUI - Main terminal UI for Git synchronization"
Write-Output ""
Write-Output "Key internal functions:"
Write-Output "  * Get-RepositoryStatus - Retrieves Git repository status"
Write-Output "  * Invoke-GitCommand - Safely executes Git commands"
Write-Output "  * Show-DiffPreview - Displays visual diff of changes"
Write-Output "  * Start-GitTutorial - Interactive Git tutorial mode"
Write-Output ""
Write-Output "===== Demo Complete ====="