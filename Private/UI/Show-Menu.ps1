function script:Show-Menu {
    <#
    .SYNOPSIS
        Displays a menu in the terminal
    
    .DESCRIPTION
        Shows a menu with options and handles selection
    
    .PARAMETER Title
        The title of the menu
    
    .PARAMETER Options
        Array of options to display in the menu
    
    .PARAMETER X
        The X coordinate for the menu
    
    .PARAMETER Y
        The Y coordinate for the menu
    
    .PARAMETER Width
        The width of the menu
    
    .PARAMETER Height
        The height of the menu
    
    .PARAMETER SelectedIndex
        The index of the currently selected option
    
    .EXAMPLE
        Show-Menu -Title "Git Commands" -Options @("status", "pull", "push") -X 5 -Y 10 -Width 20 -Height 10 -SelectedIndex 0
    #>
    param (
        [string]$Title = "",
        
        [Parameter(Mandatory)]
        [string[]]$Options,
        
        [Parameter(Mandatory)]
        [int]$X,
        
        [Parameter(Mandatory)]
        [int]$Y,
        
        [Parameter(Mandatory)]
        [int]$Width,
        
        [Parameter(Mandatory)]
        [int]$Height,
        
        [Parameter()]
        [int]$SelectedIndex = 0
    )
    
    # Draw menu title
    Move-Cursor -Row $Y -Column $X
    Write-Colored -Text $Title -Styles 'Bold', 'FgCyan'
    
    # Calculate max visible options
    $maxVisibleOptions = $Height - 2
    
    # Calculate scroll position
    $scrollOffset = 0
    if ($Options.Count -gt $maxVisibleOptions) {
        if ($SelectedIndex -ge $maxVisibleOptions) {
            $scrollOffset = [Math]::Min($SelectedIndex - $maxVisibleOptions + 1, $Options.Count - $maxVisibleOptions)
        }
    }
    
    # Draw options
    $visibleCount = [Math]::Min($Options.Count, $maxVisibleOptions)
    for ($i = 0; $i -lt $visibleCount; $i++) {
        $optionIndex = $i + $scrollOffset
        if ($optionIndex -lt $Options.Count) {
            $option = $Options[$optionIndex]
            
            # Truncate option if too long
            if ($option.Length -gt $Width - 4) {
                $option = $option.Substring(0, $Width - 7) + "..."
            }
            
            Move-Cursor -Row ($Y + $i + 1) -Column $X
            
            # Highlight selected option
            if ($optionIndex -eq $SelectedIndex) {
                Write-Colored -Text "> $option" -Styles 'Bold', 'FgGreen'
            }
            else {
                Write-Colored -Text "  $option" -Styles 'Reset'
            }
            
            # Clear rest of line
            Write-Host " " * ($Width - $option.Length - 3) -NoNewline
        }
    }
    
    # Show scroll indicators if needed
    if ($Options.Count -gt $maxVisibleOptions) {
        if ($scrollOffset -gt 0) {
            Move-Cursor -Row $Y -Column ($X + $Width - 2)
            Write-Colored -Text "↑" -Styles 'FgCyan'
        }
        
        if ($scrollOffset + $maxVisibleOptions -lt $Options.Count) {
            Move-Cursor -Row ($Y + $maxVisibleOptions) -Column ($X + $Width - 2)
            Write-Colored -Text "↓" -Styles 'FgCyan'
        }
    }
}
