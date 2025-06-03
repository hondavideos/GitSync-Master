function Show-CommandBuilder {
    <#
    .SYNOPSIS
        Shows the interactive Git command builder interface.
    
    .DESCRIPTION
        Displays the command builder interface that allows users to
        construct Git commands visually by selecting options.
    
    .PARAMETER X
        The X coordinate for the command builder pane.
    
    .PARAMETER Y
        The Y coordinate for the command builder pane.
    
    .PARAMETER Width
        The width of the command builder pane.
    
    .PARAMETER Height
        The height of the command builder pane.
    
    .EXAMPLE
        Show-CommandBuilder -X 40 -Y 5 -Width 30 -Height 15
    #>
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
    
    # Initialize command builder options if needed
    if ($null -eq $script:AppState.CommandBuilderOptions -or $script:AppState.CommandBuilderOptions.Count -eq 0) {
        Update-CommandBuilderOptions
    }
    
    # Track if we should show tooltips
    $script:AppState.ShowTooltips = $true
    
    # Show current command
    Move-Cursor -Row $Y -Column $X
    Write-Colored -Text "Current Command:" -Styles 'Bold'
    
    Move-Cursor -Row ($Y + 1) -Column $X
    if ($script:AppState.CommandParts.Count -gt 0) {
        $command = "git " + ($script:AppState.CommandParts -join " ")
        
        # Truncate if too long
        if ($command.Length -gt $Width) {
            $command = $command.Substring(0, $Width - 3) + "..."
        }
        
        Write-Colored -Text $command -Styles 'FgGreen'
    }
    else {
        Write-Colored -Text "git " -Styles 'FgGreen'
    }
    
    # Separator
    Move-Cursor -Row ($Y + 2) -Column $X
    Write-Colored -Text ("-" * $Width) -Styles 'FgBlue'
    
    # Show options menu
    Move-Cursor -Row ($Y + 3) -Column $X
    Write-Colored -Text "Select Option:" -Styles 'Bold'
    
    # Display options as a menu
    $optionsHeight = $Height - 6
    Show-Menu -Title "" -Options $script:AppState.CommandBuilderOptions -X $X -Y ($Y + 4) -Width $Width -Height $optionsHeight -SelectedIndex $script:AppState.SelectedIndex
    
    # Calculate max visible options and scroll position for tooltip positioning
    $maxVisibleOptions = $optionsHeight - 2
    $scrollOffset = 0
    if ($script:AppState.CommandBuilderOptions.Count -gt $maxVisibleOptions) {
        if ($script:AppState.SelectedIndex -ge $maxVisibleOptions) {
            $scrollOffset = [Math]::Min($script:AppState.SelectedIndex - $maxVisibleOptions + 1, $script:AppState.CommandBuilderOptions.Count - $maxVisibleOptions)
        }
    }
    
    # Show tooltip for selected option if available
    if ($script:AppState.CommandBuilderOptions.Count -gt 0 -and 
        $script:AppState.SelectedIndex -ge 0 -and 
        $script:AppState.SelectedIndex -lt $script:AppState.CommandBuilderOptions.Count -and
        $script:AppState.ShowTooltips) {
        
        $selectedOption = $script:AppState.CommandBuilderOptions[$script:AppState.SelectedIndex]
        
        # Skip tooltips for Execute and Clear options
        if ($selectedOption -ne "Execute" -and $selectedOption -ne "Clear") {
            # Calculate the position of the selected option in the visible area
            $visibleIndex = $script:AppState.SelectedIndex - $scrollOffset
            
            if ($visibleIndex -ge 0 -and $visibleIndex -lt $maxVisibleOptions) {
                $tooltipY = $Y + 4 + $visibleIndex + 1
                $tooltipX = $X + 2 + $selectedOption.Length
                
                # Display tooltip
                Show-CommandTooltip -X $tooltipX -Y $tooltipY -OptionText $selectedOption -CommandParts $script:AppState.CommandParts
            }
        }
    }
    
    # Show navigation help
    Move-Cursor -Row ($Y + $Height - 2) -Column $X
    Write-Colored -Text "↑↓: Navigate | Enter: Select | Backspace: Remove last" -Styles 'FgCyan'
    
    # Show tooltip help
    Move-Cursor -Row ($Y + $Height - 1) -Column $X
    Write-Colored -Text "T: Toggle tooltips" -Styles 'FgCyan'
}
