function Show-StatusPane {
    <#
    .SYNOPSIS
        Shows the Git repository status pane.
    
    .DESCRIPTION
        Displays information about the current Git repository status,
        including branch name, tracking information, and file status.
    
    .PARAMETER X
        The X coordinate for the status pane.
    
    .PARAMETER Y
        The Y coordinate for the status pane.
    
    .PARAMETER Width
        The width of the status pane.
    
    .PARAMETER Height
        The height of the status pane.
    
    .EXAMPLE
        Show-StatusPane -X 2 -Y 5 -Width 30 -Height 15
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
    
    $status = $script:AppState.GitStatus
    
    # Repository info section
    Move-Cursor -Row $Y -Column $X
    Write-Colored -Text "Branch: " -Styles 'Bold' -NoNewline
    Write-Colored -Text $status.CurrentBranch -Styles 'FgGreen'
    
    Move-Cursor -Row ($Y + 1) -Column $X
    if ($status.Tracking) {
        Write-Colored -Text "Tracking: " -Styles 'Bold' -NoNewline
        Write-Colored -Text ($status.Tracking -replace '^$', '(none)') -Styles 'FgCyan'
        
        # Show ahead/behind info
        if ($status.Ahead -gt 0 -or $status.Behind -gt 0) {
            Move-Cursor -Row ($Y + 2) -Column $X
            if ($status.Ahead -gt 0) {
                Write-Colored -Text "Ahead: " -Styles 'Bold' -NoNewline
                Write-Colored -Text "$($status.Ahead) commit(s)" -Styles 'FgYellow' -NoNewline
            }
            
            if ($status.Behind -gt 0) {
                if ($status.Ahead -gt 0) {
                    Write-Host ", " -NoNewline
                }
                Write-Colored -Text "Behind: " -Styles 'Bold' -NoNewline
                Write-Colored -Text "$($status.Behind) commit(s)" -Styles 'FgYellow'
            }
            else {
                Write-Host ""
            }
        }
    }
    else {
        Write-Colored -Text "Not tracking any remote branch" -Styles 'FgYellow'
    }
    
    # Separator
    Move-Cursor -Row ($Y + 3) -Column $X
    Write-Colored -Text ("-" * $Width) -Styles 'FgBlue'
    
    # Working directory status
    Move-Cursor -Row ($Y + 4) -Column $X
    Write-Colored -Text "Working directory:" -Styles 'Bold'
    
    $row = $Y + 5
    
    if ($status.Modified.Count -eq 0 -and $status.Untracked.Count -eq 0 -and 
        $status.Staged.Count -eq 0 -and $status.Deleted.Count -eq 0) {
        Move-Cursor -Row $row -Column $X
        Write-Colored -Text "Clean working directory" -Styles 'FgGreen'
        $row++
    }
    else {
        if ($status.Staged.Count -gt 0) {
            Move-Cursor -Row $row -Column $X
            Write-Colored -Text "Staged files: " -Styles 'Bold' -NoNewline
            Write-Colored -Text $status.Staged.Count -Styles 'FgGreen'
            $row++
            
            $maxFiles = [Math]::Min($status.Staged.Count, 3)
            for ($i = 0; $i -lt $maxFiles; $i++) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "+ " -Styles 'FgGreen' -NoNewline
                
                # Truncate filename if too long
                $file = $status.Staged[$i]
                if ($file.Length -gt $Width - 6) {
                    $file = "..." + $file.Substring($file.Length - ($Width - 9))
                }
                
                Write-Colored -Text $file -Styles 'FgGreen'
                $row++
            }
            
            if ($status.Staged.Count -gt $maxFiles) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "... and $($status.Staged.Count - $maxFiles) more" -Styles 'FgGreen'
                $row++
            }
        }
        
        if ($status.Modified.Count -gt 0) {
            Move-Cursor -Row $row -Column $X
            Write-Colored -Text "Modified files: " -Styles 'Bold' -NoNewline
            Write-Colored -Text $status.Modified.Count -Styles 'FgYellow'
            $row++
            
            $maxFiles = [Math]::Min($status.Modified.Count, 3)
            for ($i = 0; $i -lt $maxFiles; $i++) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "~ " -Styles 'FgYellow' -NoNewline
                
                # Truncate filename if too long
                $file = $status.Modified[$i]
                if ($file.Length -gt $Width - 6) {
                    $file = "..." + $file.Substring($file.Length - ($Width - 9))
                }
                
                Write-Colored -Text $file -Styles 'FgYellow'
                $row++
            }
            
            if ($status.Modified.Count -gt $maxFiles) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "... and $($status.Modified.Count - $maxFiles) more" -Styles 'FgYellow'
                $row++
            }
        }
        
        if ($status.Untracked.Count -gt 0) {
            Move-Cursor -Row $row -Column $X
            Write-Colored -Text "Untracked files: " -Styles 'Bold' -NoNewline
            Write-Colored -Text $status.Untracked.Count -Styles 'FgRed'
            $row++
            
            $maxFiles = [Math]::Min($status.Untracked.Count, 3)
            for ($i = 0; $i -lt $maxFiles; $i++) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "? " -Styles 'FgRed' -NoNewline
                
                # Truncate filename if too long
                $file = $status.Untracked[$i]
                if ($file.Length -gt $Width - 6) {
                    $file = "..." + $file.Substring($file.Length - ($Width - 9))
                }
                
                Write-Colored -Text $file -Styles 'FgRed'
                $row++
            }
            
            if ($status.Untracked.Count -gt $maxFiles) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "... and $($status.Untracked.Count - $maxFiles) more" -Styles 'FgRed'
                $row++
            }
        }
        
        if ($status.Deleted.Count -gt 0) {
            Move-Cursor -Row $row -Column $X
            Write-Colored -Text "Deleted files: " -Styles 'Bold' -NoNewline
            Write-Colored -Text $status.Deleted.Count -Styles 'FgMagenta'
            $row++
            
            $maxFiles = [Math]::Min($status.Deleted.Count, 3)
            for ($i = 0; $i -lt $maxFiles; $i++) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "- " -Styles 'FgMagenta' -NoNewline
                
                # Truncate filename if too long
                $file = $status.Deleted[$i]
                if ($file.Length -gt $Width - 6) {
                    $file = "..." + $file.Substring($file.Length - ($Width - 9))
                }
                
                Write-Colored -Text $file -Styles 'FgMagenta'
                $row++
            }
            
            if ($status.Deleted.Count -gt $maxFiles) {
                Move-Cursor -Row $row -Column ($X + 2)
                Write-Colored -Text "... and $($status.Deleted.Count - $maxFiles) more" -Styles 'FgMagenta'
                $row++
            }
        }
    }
    
    # Display action tips
    Move-Cursor -Row ($Y + $Height - 2) -Column $X
    Write-Colored -Text "Press 'R' to refresh status" -Styles 'FgCyan'
}
