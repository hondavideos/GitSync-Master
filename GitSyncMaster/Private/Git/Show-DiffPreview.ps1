function Show-DiffPreview {
    <#
    .SYNOPSIS
        Shows a visual preview of Git diff.
    
    .DESCRIPTION
        Displays a visual preview of changes before commit, allowing users
        to review their changes in a user-friendly format.
    
    .PARAMETER Path
        The path to the Git repository. Defaults to the current directory.
    
    .PARAMETER File
        Optional file path to show diff for a specific file.
    
    .PARAMETER Staged
        If specified, shows diff for staged changes (--cached).
    
    .PARAMETER DiffTool
        If specified, uses 'git difftool' instead of 'git diff'.
    
    .EXAMPLE
        Show-DiffPreview
        
        Shows a preview of all unstaged changes in the current repository.
    
    .EXAMPLE
        Show-DiffPreview -File "README.md" -Staged
        
        Shows a preview of staged changes for README.md.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,
        
        [Parameter()]
        [string]$File,
        
        [Parameter()]
        [switch]$Staged,
        
        [Parameter()]
        [switch]$DiffTool
    )
    
    try {
        # Store original location
        $originalLocation = Get-Location
        
        # Change to repository path
        if (Test-Path -Path $Path -PathType Container) {
            Set-Location -Path $Path
        }
        else {
            throw "The specified path does not exist: $Path"
        }
        
        # Check if this is a Git repository
        $isRepo = $false
        try {
            $isRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
        }
        catch {
            # Not a git repository
        }
        
        if (-not $isRepo) {
            throw "The specified path is not a Git repository: $Path"
        }
        
        # Build command
        $command = if ($DiffTool) { "difftool" } else { "diff" }
        
        if ($Staged) {
            $command += " --staged"
        }
        
        if ($File) {
            $command += " -- `"$File`""
        }
        
        # Get terminal size
        $terminalSize = Get-TerminalSize
        $width = $terminalSize.Width
        $height = $terminalSize.Height
        
        # Calculate dimensions
        $boxWidth = [Math]::Min($width - 4, 120)
        $boxHeight = [Math]::Min($height - 6, 30)
        $boxX = [Math]::Floor(($width - $boxWidth) / 2)
        $boxY = [Math]::Floor(($height - $boxHeight) / 2)
        
        # Save current screen state
        Write-Host "$script:EscChar[?47h" -NoNewline
        
        # Clear screen
        Clear-Screen
        
        # Draw container box
        Draw-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight -Title "Git Diff Preview" -Styles 'Bold', 'FgBlue'
        
        # Show the diff
        Show-Diff -X ($boxX + 2) -Y ($boxY + 1) -Width ($boxWidth - 4) -Height ($boxHeight - 2) -File $File -Staged:$Staged
        
        # Draw footer with instructions
        Move-Cursor -Row ($boxY + $boxHeight) -Column $boxX
        Write-Colored -Text "Press any key to return to menu..." -Styles 'FgCyan'
        
        # Wait for key press
        $null = [Console]::ReadKey($true)
        
        # Restore previous screen
        Write-Host "$script:EscChar[?47l" -NoNewline
    }
    catch {
        Write-Error "Error showing diff preview: $_"
        
        # Ensure we restore screen
        Write-Host "$script:EscChar[?47l" -NoNewline
    }
    finally {
        # Restore original location
        Set-Location -Path $originalLocation
    }
}
