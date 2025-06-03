function Show-Diff {
    <#
    .SYNOPSIS
        Shows a visual diff of changes in the repository.
    
    .DESCRIPTION
        Displays a colorized visual representation of file changes 
        using Git's diff functionality in the terminal UI.
    
    .PARAMETER X
        The X coordinate for the diff display.
    
    .PARAMETER Y
        The Y coordinate for the diff display.
    
    .PARAMETER Width
        The width of the diff display area.
    
    .PARAMETER Height
        The height of the diff display area.
    
    .PARAMETER File
        Optional file path to show diff for a specific file.
        If not specified, shows diff for all changed files.
    
    .PARAMETER Staged
        If specified, shows diff for staged changes.
    
    .EXAMPLE
        Show-Diff -X 5 -Y 10 -Width 70 -Height 20
        
        Shows diff for all unstaged changes starting at coordinates (5,10).
    
    .EXAMPLE
        Show-Diff -X 5 -Y 10 -Width 70 -Height 20 -File "README.md" -Staged
        
        Shows diff for staged changes in README.md starting at coordinates (5,10).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$X,
        
        [Parameter(Mandatory)]
        [int]$Y,
        
        [Parameter(Mandatory)]
        [int]$Width,
        
        [Parameter(Mandatory)]
        [int]$Height,
        
        [Parameter()]
        [string]$File = '',
        
        [Parameter()]
        [switch]$Staged
    )
    
    # Get diff command
    $diffCommand = "diff"
    if ($Staged) {
        $diffCommand = "diff --staged"
    }
    
    if ($File) {
        $diffCommand += " -- `"$File`""
    }
    
    try {
        # Run git diff command
        $diffOutput = Invoke-GitCommand -Command $diffCommand
        
        # If no diff output, show message
        if (-not $diffOutput) {
            Move-Cursor -Row $Y -Column $X
            Write-Colored -Text "No changes to display." -Styles 'FgYellow'
            return
        }
        
        # Split diff output into lines
        $diffLines = $diffOutput -split "`n"
        
        # Calculate max visible lines
        $maxVisibleLines = $Height
        $diffCount = [Math]::Min($diffLines.Count, $maxVisibleLines)
        
        # Display diff output with coloring
        for ($i = 0; $i -lt $diffCount; $i++) {
            $line = $diffLines[$i]
            
            # Truncate line if too long
            if ($line.Length -gt $Width) {
                $line = $line.Substring(0, $Width - 3) + "..."
            }
            
            Move-Cursor -Row ($Y + $i) -Column $X
            
            # Colorize diff output
            if ($line -match '^diff --git') {
                Write-Colored -Text $line -Styles 'Bold', 'FgCyan'
            }
            elseif ($line -match '^index ' -or $line -match '^---' -or $line -match '^\+\+\+') {
                Write-Colored -Text $line -Styles 'FgCyan'
            }
            elseif ($line -match '^@@') {
                Write-Colored -Text $line -Styles 'FgMagenta'
            }
            elseif ($line -match '^\+') {
                Write-Colored -Text $line -Styles 'FgGreen'
            }
            elseif ($line -match '^-') {
                Write-Colored -Text $line -Styles 'FgRed'
            }
            else {
                Write-Host $line
            }
            
            # Clear rest of line
            Write-Host " " * ($Width - $line.Length) -NoNewline
        }
        
        # Show more indicator if there are more lines
        if ($diffLines.Count -gt $maxVisibleLines) {
            Move-Cursor -Row ($Y + $maxVisibleLines - 1) -Column $X
            Write-Colored -Text "... more lines not shown ($($diffLines.Count - $maxVisibleLines) more) ..." -Styles 'FgYellow'
        }
    }
    catch {
        Move-Cursor -Row $Y -Column $X
        Write-Colored -Text "Error displaying diff: $_" -Styles 'FgRed'
    }
}
