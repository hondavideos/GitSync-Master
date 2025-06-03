function Get-TerminalSize {
    <#
    .SYNOPSIS
        Gets the current terminal window size.
    
    .DESCRIPTION
        Retrieves the width and height of the current terminal window
        in a cross-platform compatible way.
    
    .EXAMPLE
        $size = Get-TerminalSize
        Write-Host "Width: $($size.Width), Height: $($size.Height)"
    
    .NOTES
        This function works on both Windows and Unix-like systems.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        # Use .NET Console class for width/height
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight
        
        # Fallback to ANSI escape sequence if the width/height is 0
        if ($width -eq 0 -or $height -eq 0) {
            # Send ANSI escape sequence to get terminal size
            # Save cursor position
            Write-Host "$script:EscChar[s" -NoNewline
            
            # Move to bottom-right and request cursor position
            Write-Host "$script:EscChar[999;999H" -NoNewline
            Write-Host "$script:EscChar[6n" -NoNewline
            
            # Read response
            $response = ""
            while ($true) {
                $key = [Console]::ReadKey($true)
                $response += $key.KeyChar
                if ($key.KeyChar -eq 'R') { break }
            }
            
            # Restore cursor position
            Write-Host "$script:EscChar[u" -NoNewline
            
            # Parse response (format should be ESC[rows;colsR)
            if ($response -match '\[(\d+);(\d+)R') {
                $height = [int]$Matches[1]
                $width = [int]$Matches[2]
            }
        }
        
        # Ensure minimum size
        $width = [Math]::Max(80, $width)
        $height = [Math]::Max(24, $height)
        
        # Return as object
        return [PSCustomObject]@{
            Width = $width
            Height = $height
        }
    }
    catch {
        # Fallback to reasonable defaults
        Write-Verbose "Error getting terminal size: $_"
        return [PSCustomObject]@{
            Width = 80
            Height = 24
        }
    }
}
