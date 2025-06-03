function Show-CommandTooltip {
    <#
    .SYNOPSIS
        Shows a floating tooltip near the command builder selection.
    
    .DESCRIPTION
        Displays a floating tooltip box with contextual help about
        the currently highlighted option in the command builder.
        The tooltip appears near the selected option without blocking it.
    
    .PARAMETER X
        The X coordinate for the tooltip box.
    
    .PARAMETER Y
        The Y coordinate for the tooltip box.
    
    .PARAMETER OptionText
        The text of the option being hovered or selected.
    
    .PARAMETER CommandParts
        The current array of command parts in the command builder.
    
    .EXAMPLE
        Show-CommandTooltip -X 40 -Y 12 -OptionText "--rebase" -CommandParts @("pull")
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [int]$X,
        
        [Parameter(Mandatory)]
        [int]$Y,
        
        [Parameter(Mandatory)]
        [string]$OptionText,
        
        [Parameter()] # Removed Mandatory
        [string[]]$CommandParts
    )
    
    # Set up dimensions for the tooltip
    $tooltipWidth = 40
    $tooltipMaxHeight = 5
    
    # Create a temporary array with the current command parts plus the hovered option
    $tempCommandParts = $CommandParts + $OptionText
    
    # Get tooltip information from our helper function
    $tooltipInfo = Get-GitCommandTooltip -CommandParts $tempCommandParts
    
    # Calculate tooltip position
    # Try to position to the right of the option first
    $tooltipX = $X + $OptionText.Length + 4
    
    # If tooltip would go off the right edge of the screen, position it to the left
    $termWidth = $script:AppState.TerminalSize.Width
    if (($tooltipX + $tooltipWidth) -gt $termWidth) {
        $tooltipX = [Math]::Max(2, $X - $tooltipWidth - 2)
    }
    
    # Ensure tooltip is visible on screen
    $tooltipX = [Math]::Max(2, [Math]::Min($tooltipX, $termWidth - $tooltipWidth - 2))
    
    # Calculate Y position, try to center on the option
    $tooltipY = $Y - 1
    $termHeight = $script:AppState.TerminalSize.Height
    if (($tooltipY + $tooltipMaxHeight) -gt $termHeight) {
        $tooltipY = [Math]::Max(2, $termHeight - $tooltipMaxHeight - 2)
    }
    
    # Ensure tooltip is visible on screen
    $tooltipY = [Math]::Max(2, [Math]::Min($tooltipY, $termHeight - $tooltipMaxHeight - 2))
    
    # Draw tooltip box
    Draw-Box -X $tooltipX -Y $tooltipY -Width $tooltipWidth -Height $tooltipMaxHeight -Styles 'FgCyan', 'Bold'
    
    # Determine what content to show
    $title = $tooltipInfo.Title
    $description = $tooltipInfo.Description
    
    # Trim title if too long
    if ($title.Length -gt ($tooltipWidth - 4)) {
        $title = $title.Substring(0, $tooltipWidth - 7) + "..."
    }
    
    # Display title
    Move-Cursor -Row $tooltipY -Column ($tooltipX + [Math]::Floor(($tooltipWidth - $title.Length) / 2))
    Write-Colored -Text $title -Styles 'Bold', 'FgYellow'
    
    # Truncate description if needed and display
    if ($description.Length -gt ($tooltipWidth - 4) * 3) {
        $description = $description.Substring(0, ($tooltipWidth - 4) * 3 - 3) + "..."
    }
    
    # Word wrap description
    $lines = @()
    $words = $description -split ' '
    $currentLine = ""
    
    foreach ($word in $words) {
        if (($currentLine.Length + $word.Length + 1) -le $tooltipWidth - 4) {
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
    
    # Display description (up to 3 lines)
    for ($i = 0; $i -lt [Math]::Min($lines.Count, 3); $i++) {
        Move-Cursor -Row ($tooltipY + $i + 1) -Column ($tooltipX + 2)
        Write-Host $lines[$i]
    }
    
    # If there's a warning, display an indicator
    if (-not [string]::IsNullOrEmpty($tooltipInfo.Warning)) {
        Move-Cursor -Row ($tooltipY + $tooltipMaxHeight - 1) -Column ($tooltipX + $tooltipWidth - 12)
        Write-Colored -Text "⚠ Warning" -Styles 'FgRed', 'Bold'
    }
}
