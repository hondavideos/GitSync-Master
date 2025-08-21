function Show-HelpTips {
    <#
    .SYNOPSIS
        Shows help tips and information in the help pane.
    
    .DESCRIPTION
        Displays context-sensitive help and tips based on the current
        state of the application and selected command.
    
    .PARAMETER X
        The X coordinate for the help pane.
    
    .PARAMETER Y
        The Y coordinate for the help pane.
    
    .PARAMETER Width
        The width of the help pane.
    
    .PARAMETER Height
        The height of the help pane.
    
    .EXAMPLE
        Show-HelpTips -X 72 -Y 5 -Width 30 -Height 15
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
        [int]$Height
    )
    
    # Title
    Move-Cursor -Row $Y -Column $X
    Write-Colored -Text "Git Help & Tips" -Styles 'Bold'
    
    # Separator
    Move-Cursor -Row ($Y + 1) -Column $X
    Write-Colored -Text ("-" * $Width) -Styles 'FgBlue'
    
    # Context-sensitive help
    if ($script:AppState.CommandParts.Count -gt 0) {
        # Get contextual tooltips based on current command parts
        $tooltip = Get-GitCommandTooltip -CommandParts $script:AppState.CommandParts
        
        # Display command title
        Move-Cursor -Row ($Y + 2) -Column $X
        Write-Colored -Text $tooltip.Title -Styles 'Bold', 'FgYellow'
        
        # Word wrap description text
        $lines = @()
        $words = $tooltip.Description -split ' '
        $currentLine = ""
        
        foreach ($word in $words) {
            if (($currentLine.Length + $word.Length + 1) -le $Width) {
                if ($currentLine.Length -gt 0) {
                    $currentLine += " "
                }
                $currentLine += $word
            }
            else {
                $lines += $currentLine
                $currentLine = $word
            }
        }
        if ($currentLine.Length -gt 0) {
            $lines += $currentLine
        }
        
        # Display wrapped description text
        for ($i = 0; $i -lt [Math]::Min($lines.Count, 4); $i++) {
            Move-Cursor -Row ($Y + 3 + $i) -Column $X
            Write-Host $lines[$i]
        }
        
        # Examples section
        if ($tooltip.Examples.Count -gt 0) {
            Move-Cursor -Row ($Y + 8) -Column $X
            Write-Colored -Text "Examples:" -Styles 'Bold', 'FgCyan'
            
            $row = $Y + 9
            for ($i = 0; $i -lt [Math]::Min($tooltip.Examples.Count, 3); $i++) {
                Move-Cursor -Row $row -Column $X
                Write-Colored -Text "• $($tooltip.Examples[$i])" -Styles 'FgWhite'
                $row++
            }
        }
        
        # Warning section if available
        if (-not [string]::IsNullOrEmpty($tooltip.Warning)) {
            $row = [Math]::Max($row, $Y + 12)
            Move-Cursor -Row $row -Column $X
            Write-Colored -Text "Warning:" -Styles 'Bold', 'FgRed'
            $row++
            
            # Word wrap warning text
            $warnLines = @()
            $warnWords = $tooltip.Warning -split ' '
            $currentWarnLine = ""
            
            foreach ($word in $warnWords) {
                if (($currentWarnLine.Length + $word.Length + 1) -le $Width) {
                    if ($currentWarnLine.Length -gt 0) {
                        $currentWarnLine += " "
                    }
                    $currentWarnLine += $word
                }
                else {
                    $warnLines += $currentWarnLine
                    $currentWarnLine = $word
                }
            }
            if ($currentWarnLine.Length -gt 0) {
                $warnLines += $currentWarnLine
            }
            
            # Display warning text
            for ($i = 0; $i -lt [Math]::Min($warnLines.Count, 2); $i++) {
                Move-Cursor -Row $row -Column $X
                Write-Colored -Text $warnLines[$i] -Styles 'FgRed'
                $row++
            }
        }
        
        # Add help shortcut reminder
        $row = [Math]::Max($row + 1, $Y + $Height - 3)
        Move-Cursor -Row $row -Column $X
        Write-Colored -Text "Press F1 for more detailed help" -Styles 'FgCyan'
    }
    else {
        # General Git help when no command is selected
        Move-Cursor -Row ($Y + 2) -Column $X
        Write-Colored -Text "Getting Started:" -Styles 'Bold', 'FgYellow'
        
        Move-Cursor -Row ($Y + 3) -Column $X
        Write-Host "Select a Git command from the Command Builder"
        Move-Cursor -Row ($Y + 4) -Column $X
        Write-Host "pane to see specific help and tips."
        
        Move-Cursor -Row ($Y + 6) -Column $X
        Write-Colored -Text "Common Workflows:" -Styles 'Bold', 'FgCyan'
        
        Move-Cursor -Row ($Y + 7) -Column $X
        Write-Colored -Text "1. Check Status:" -Styles 'FgWhite'
        Move-Cursor -Row ($Y + 8) -Column ($X + 3)
        Write-Host "Use 'git status' to view repository state"
        
        Move-Cursor -Row ($Y + 9) -Column $X
        Write-Colored -Text "2. Sync Changes:" -Styles 'FgWhite'
        Move-Cursor -Row ($Y + 10) -Column ($X + 3)
        Write-Host "Pull first with 'git pull', then 'git push'"
        
        Move-Cursor -Row ($Y + 11) -Column $X
        Write-Colored -Text "3. Save Work:" -Styles 'FgWhite'
        Move-Cursor -Row ($Y + 12) -Column ($X + 3)
        Write-Host "Stage with 'git add', commit with 'git commit'"
        
        Move-Cursor -Row ($Y + 14) -Column $X
        Write-Colored -Text "Press F1 for more help | Alt+T for tutorial" -Styles 'FgCyan'
    }
}
