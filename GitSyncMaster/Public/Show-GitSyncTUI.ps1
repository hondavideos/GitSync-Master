function Show-GitSyncTUI {
    <#
    .SYNOPSIS
        Shows the Git Synchronization Terminal User Interface.
    
    .DESCRIPTION
        Displays an interactive terminal UI for Git synchronization with visual command building,
        learning aids, and cross-platform support.
    
    .PARAMETER Path
        The path to the Git repository. If not specified, the current directory will be used.
    
    .PARAMETER DryRun
        If specified, the application will run in dry run mode, showing what commands would execute
        without actually executing them.
    
    .PARAMETER Tutorial
        If specified, starts the application in tutorial mode with simulated repositories.
    
    .EXAMPLE
        Show-GitSyncTUI
        
        Shows the Git Sync TUI for the current directory.
    
    .EXAMPLE
        Show-GitSyncTUI -Path C:\Projects\MyRepo -DryRun
        
        Shows the Git Sync TUI for the specified repository in dry run mode.
    
    .EXAMPLE
        Show-GitSyncTUI -Tutorial
        
        Starts the Git Sync TUI in tutorial mode with simulated repositories.
    
    .NOTES
        Requires Git to be installed and available in PATH.
        Designed for PowerShell Core (7.0+) and works cross-platform.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path = (Get-Location).Path,
        
        [Parameter(ParameterSetName = 'Normal')]
        [switch]$DryRun,
        
        [Parameter(ParameterSetName = 'Tutorial')]
        [switch]$Tutorial
    )
    
    begin {
        # Check if Git is installed
        try {
            $null = & git --version
        }
        catch {
            Write-Error "Git command not found. Please ensure Git is installed and available in PATH."
            return
        }
        
        # Set up
        $originalLocation = Get-Location
        $originalEncoding = [System.Console]::OutputEncoding
        [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        
        # Hide the cursor
        Write-Host "$script:EscChar[?25l" -NoNewline
        
        # Set up app state
        $script:AppState = @{
            DryRun = $DryRun.IsPresent
            Path = $Path
            IsTutorial = $Tutorial.IsPresent
            CurrentAction = "Status"
            SelectedPane = "Status"
            GitStatus = $null
            CommandBuilderOptions = @()
            CommandParts = @()
            HelpText = @{}
            TerminalSize = Get-TerminalSize
            ExitRequested = $false
            Messages = @()
            ErrorMessage = $null
            SelectedIndex = 0
            ShowTooltips = $true
        }
        
        # Load help text database
        $script:AppState.HelpText = @{
            "Status" = "Shows the current status of your Git repository, including branch name, tracked/untracked files, and pending changes."
            "Pull" = "Downloads changes from a remote repository and integrates them into your local branch."
            "Push" = "Uploads your local branch commits to the remote repository."
            "Commit" = "Saves your changes to the local repository with a descriptive message."
            "Branch" = "Create, list, rename, or delete branches in your repository."
            "Checkout" = "Switch between branches or restore working tree files."
            "Merge" = "Combines changes from different branches together."
            "Fetch" = "Downloads objects and refs from another repository without merging."
            "Stash" = "Temporarily stores modified, tracked files to allow switching branches."
            "Reset" = "Resets current HEAD to the specified state (use with caution)."
            "Clone" = "Creates a copy of an existing repository."
            "Remote" = "Manages the set of repositories you track."
            "Log" = "Shows the commit logs with history information."
            "Diff" = "Shows changes between commits, commit and working tree, etc."
            "Init" = "Creates an empty Git repository or reinitializes an existing one."
        }
    }
    
    process {
        try {
            # Change to the specified directory if it exists
            if (-not $Tutorial.IsPresent -and (Test-Path -Path $Path -PathType Container)) {
                Set-Location -Path $Path
                
                # Check if this is a Git repository
                $isGitRepo = Test-Path -Path (Join-Path -Path $Path -ChildPath ".git") -PathType Container
                if (-not $isGitRepo) {
                    $isGitRepo = (git rev-parse --is-inside-work-tree 2>&1) -eq "true"
                }
                
                if (-not $isGitRepo) {
                    Write-Warning "The specified path is not a Git repository. Would you like to initialize one? (y/n)"
                    $init = Read-Host
                    if ($init -eq "y") {
                        git init
                        Write-Host "Git repository initialized."
                    }
                    else {
                        Write-Warning "Operation cancelled. A Git repository is required."
                        return
                    }
                }
            }
            
            if ($Tutorial.IsPresent) {
                Start-GitTutorial
                return
            }
            
            # Main UI loop
            Show-MainInterface
        }
        catch {
            Write-Error "An error occurred: $_"
        }
        finally {
            # Clean up
            Set-Location -Path $originalLocation
            [System.Console]::OutputEncoding = $originalEncoding
            
            # Show the cursor again
            Write-Host "$script:EscChar[?25h" -NoNewline
            
            # Clear the screen on exit
            Clear-Screen
        }
    }
}

function Show-MainInterface {
    [CmdletBinding()]
    param()
    
    # Initialize
    $script:AppState.GitStatus = Get-RepositoryStatus
    
    # Main loop
    while (-not $script:AppState.ExitRequested) {
        # Get terminal size
        $script:AppState.TerminalSize = Get-TerminalSize
        
        # Redraw UI
        Render-Interface
        
        # Handle input
        Handle-UserInput
        
        # Refresh status periodically or after commands
        if ($script:AppState.RefreshStatus) {
            $script:AppState.GitStatus = Get-RepositoryStatus
            $script:AppState.RefreshStatus = $false
        }
    }
}

function Render-Interface {
    [CmdletBinding()]
    param()
    
    # Clear screen
    Clear-Screen
    
    # Get dimensions
    $width = $script:AppState.TerminalSize.Width
    $height = $script:AppState.TerminalSize.Height
    
    # Calculate layout
    $headerHeight = 3
    $footerHeight = 2
    $contentHeight = $height - $headerHeight - $footerHeight
    
    # Header
    Move-Cursor -Row 1 -Column 1
    $headerText = "GitSync Terminal UI"
    $centerPos = [Math]::Max(1, [Math]::Floor(($width - $headerText.Length) / 2))
    Move-Cursor -Row 1 -Column $centerPos
    Write-Colored -Text $headerText -Styles 'Bold', 'FgCyan'
    
    # Show repository info
    if ($script:AppState.GitStatus.RepoName) {
        $repoInfo = "Repository: $($script:AppState.GitStatus.RepoName) | Branch: $($script:AppState.GitStatus.CurrentBranch)"
        $centerPos = [Math]::Max(1, [Math]::Floor(($width - $repoInfo.Length) / 2))
        Move-Cursor -Row 2 -Column $centerPos
        Write-Colored -Text $repoInfo -Styles 'FgYellow'
    }
    
    # Main content layout - Three panes
    $paneWidth = [Math]::Floor($width / 3)
    
    # Status pane
    Draw-Box -X 1 -Y $headerHeight -Width $paneWidth -Height $contentHeight -Title "Status" -Styles $(if ($script:AppState.SelectedPane -eq "Status") { 'Bold', 'FgGreen' } else { 'FgWhite' })
    Show-StatusPane -X 2 -Y ($headerHeight + 1) -Width ($paneWidth - 2) -Height ($contentHeight - 2)
    
    # Command builder pane
    Draw-Box -X ($paneWidth + 1) -Y $headerHeight -Width $paneWidth -Height $contentHeight -Title "Command Builder" -Styles $(if ($script:AppState.SelectedPane -eq "CommandBuilder") { 'Bold', 'FgGreen' } else { 'FgWhite' })
    Show-CommandBuilder -X ($paneWidth + 2) -Y ($headerHeight + 1) -Width ($paneWidth - 2) -Height ($contentHeight - 2)
    
    # Help tips pane
    Draw-Box -X ($paneWidth * 2 + 1) -Y $headerHeight -Width ($width - $paneWidth * 2 - 1) -Height $contentHeight -Title "Help & Tips" -Styles $(if ($script:AppState.SelectedPane -eq "Help") { 'Bold', 'FgGreen' } else { 'FgWhite' })
    Show-HelpTips -X ($paneWidth * 2 + 2) -Y ($headerHeight + 1) -Width ($width - $paneWidth * 2 - 3) -Height ($contentHeight - 2)
    
    # Footer
    $footerY = $height - $footerHeight + 1
    Move-Cursor -Row $footerY -Column 1
    $footerText = "F1: Help | Tab: Switch Pane | Q: Quit | Enter: Execute Command" + $(if ($script:AppState.DryRun) { " | DRY RUN MODE" } else { "" })
    Write-Colored -Text $footerText -Styles 'FgCyan'
    
    # Display system message if any
    if ($script:AppState.ErrorMessage) {
        Move-Cursor -Row ($footerY + 1) -Column 1
        Write-Colored -Text "ERROR: $($script:AppState.ErrorMessage)" -Styles 'FgRed', 'Bold'
    }
    elseif ($script:AppState.Messages.Count -gt 0) {
        Move-Cursor -Row ($footerY + 1) -Column 1
        Write-Colored -Text $script:AppState.Messages[-1] -Styles 'FgGreen'
    }
}

function Handle-UserInput {
    [CmdletBinding()]
    param()
    
    if (-not [System.Console]::KeyAvailable) {
        Start-Sleep -Milliseconds 100
        return
    }
    
    $key = [System.Console]::ReadKey($true)
    
    # Global keys
    switch ($key.Key) {
        'Q' {
            if ($key.Modifiers -band [System.ConsoleModifiers]::Alt) {
                $script:AppState.ExitRequested = $true
            }
        }
        'Escape' {
            $script:AppState.ExitRequested = $true
        }
        'F1' {
            Show-Help
        }
        'Tab' {
            # Cycle through panes
            switch ($script:AppState.SelectedPane) {
                'Status' { $script:AppState.SelectedPane = 'CommandBuilder' }
                'CommandBuilder' { $script:AppState.SelectedPane = 'Help' }
                'Help' { $script:AppState.SelectedPane = 'Status' }
                default { $script:AppState.SelectedPane = 'Status' }
            }
        }
        'T' {
            if ($key.Modifiers -band [System.ConsoleModifiers]::Alt) {
                # Start tutorial mode
                Start-GitTutorial
            }
            else {
                # Toggle tooltips
                if (-not [bool]($script:AppState.PSObject.Properties.Name -match "ShowTooltips")) {
                    $script:AppState | Add-Member -NotePropertyName ShowTooltips -NotePropertyValue $true
                }
                $script:AppState.ShowTooltips = -not $script:AppState.ShowTooltips
                $message = if ($script:AppState.ShowTooltips) { "Tooltips enabled" } else { "Tooltips disabled" }
                $script:AppState.Messages += $message
            }
        }
    }
    
    # Pane-specific keys
    switch ($script:AppState.SelectedPane) {
        'Status' {
            # Status pane navigation
            switch ($key.Key) {
                'R' {
                    # Refresh status
                    $script:AppState.GitStatus = Get-RepositoryStatus
                    $script:AppState.Messages += "Repository status refreshed."
                }
            }
        }
        'CommandBuilder' {
            # Command builder actions
            switch ($key.Key) {
                'UpArrow' {
                    if ($script:AppState.SelectedIndex -gt 0) {
                        $script:AppState.SelectedIndex--
                    }
                }
                'DownArrow' {
                    if ($script:AppState.SelectedIndex -lt ($script:AppState.CommandBuilderOptions.Count - 1)) {
                        $script:AppState.SelectedIndex++
                    }
                }
                'Enter' {
                    # Execute or add command part
                    if ($script:AppState.CommandBuilderOptions.Count -gt 0 -and 
                        $script:AppState.SelectedIndex -ge 0 -and 
                        $script:AppState.SelectedIndex -lt $script:AppState.CommandBuilderOptions.Count) {
                        
                        $selectedOption = $script:AppState.CommandBuilderOptions[$script:AppState.SelectedIndex]
                        
                        if ($selectedOption -eq "Execute") {
                            # Execute the built command
                            $command = $script:AppState.CommandParts -join " "
                            
                            if ($script:AppState.DryRun) {
                                $script:AppState.Messages += "DRY RUN: Would execute 'git $command'"
                            }
                            else {
                                try {
                                    $result = Invoke-GitCommand -Command $command
                                    $script:AppState.Messages += "Executed: git $command"
                                    if ($result) {
                                        $script:AppState.Messages += $result
                                    }
                                }
                                catch {
                                    $script:AppState.ErrorMessage = "Command failed: $_"
                                }
                                $script:AppState.RefreshStatus = $true
                            }
                            
                            # Reset command parts
                            $script:AppState.CommandParts = @()
                            $script:AppState.SelectedIndex = 0
                            Update-CommandBuilderOptions
                        }
                        elseif ($selectedOption -eq "Clear") {
                            # Clear the command
                            $script:AppState.CommandParts = @()
                            $script:AppState.SelectedIndex = 0
                            Update-CommandBuilderOptions
                        }
                        else {
                            # Add to command parts
                            $script:AppState.CommandParts += $selectedOption
                            $script:AppState.SelectedIndex = 0
                            Update-CommandBuilderOptions
                        }
                    }
                }
                'Backspace' {
                    # Remove last command part
                    if ($script:AppState.CommandParts.Count -gt 0) {
                        $script:AppState.CommandParts = $script:AppState.CommandParts[0..($script:AppState.CommandParts.Count-2)]
                        $script:AppState.SelectedIndex = 0
                        Update-CommandBuilderOptions
                    }
                }
            }
        }
        'Help' {
            # Help pane navigation
            switch ($key.Key) {
                'UpArrow' {
                    # Scroll up in help
                }
                'DownArrow' {
                    # Scroll down in help
                }
            }
        }
    }
}

function Update-CommandBuilderOptions {
    [CmdletBinding()]
    param()
    
    # Based on current command parts, update available options
    if ($script:AppState.CommandParts.Count -eq 0) {
        # First level - Git commands
        $script:AppState.CommandBuilderOptions = @(
            "status", "pull", "push", "commit", "branch", 
            "checkout", "merge", "fetch", "stash", "reset", 
            "clone", "remote", "log", "diff", "init"
        )
    }
    else {
        # Second level and beyond - Command-specific options
        $primaryCommand = $script:AppState.CommandParts[0]
        
        switch ($primaryCommand) {
            "status" {
                $script:AppState.CommandBuilderOptions = @("-s", "--short", "-b", "--branch", "Execute", "Clear")
            }
            "pull" {
                if ($script:AppState.CommandParts.Count -eq 1) {
                    $script:AppState.CommandBuilderOptions = @("origin", "--rebase", "--no-rebase", "Execute", "Clear")
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and $script:AppState.CommandParts[1] -eq "origin") {
                    # Get branches
                    $branches = (git branch --format="%(refname:short)" 2>$null) | Where-Object { $_ -match "\S+" }
                    if ($branches) {
                        $script:AppState.CommandBuilderOptions = @($branches) + @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("main", "master", "Execute", "Clear")
                    }
                }
                else {
                    $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                }
            }
            "push" {
                if ($script:AppState.CommandParts.Count -eq 1) {
                    $script:AppState.CommandBuilderOptions = @("origin", "-u", "--force", "Execute", "Clear")
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and $script:AppState.CommandParts[1] -eq "origin") {
                    # Get branches
                    $branches = (git branch --format="%(refname:short)" 2>$null) | Where-Object { $_ -match "\S+" }
                    if ($branches) {
                        $script:AppState.CommandBuilderOptions = @($branches) + @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("main", "master", "Execute", "Clear")
                    }
                }
                else {
                    $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                }
            }
            "commit" {
                if ($script:AppState.CommandParts.Count -eq 1) {
                    $script:AppState.CommandBuilderOptions = @("-m", "-a", "-am", "--amend", "Execute", "Clear")
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and ($script:AppState.CommandParts[1] -eq "-m" -or 
                                                                        $script:AppState.CommandParts[1] -eq "-am")) {
                    # Need to get commit message from user
                    $message = Read-Host "Enter commit message"
                    if ($message) {
                        $script:AppState.CommandParts += "`"$message`""
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                }
                else {
                    $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                }
            }
            "branch" {
                if ($script:AppState.CommandParts.Count -eq 1) {
                    $script:AppState.CommandBuilderOptions = @("-a", "-r", "-d", "-D", "--list", "newbranch", "Execute", "Clear")
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and ($script:AppState.CommandParts[1] -eq "-d" -or 
                                                                        $script:AppState.CommandParts[1] -eq "-D")) {
                    # Get branches for deletion
                    $branches = (git branch --format="%(refname:short)" 2>$null) | Where-Object { $_ -match "\S+" }
                    if ($branches) {
                        $script:AppState.CommandBuilderOptions = @($branches) + @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and $script:AppState.CommandParts[1] -eq "newbranch") {
                    # Need to get branch name from user
                    $branchName = Read-Host "Enter new branch name"
                    if ($branchName) {
                        $script:AppState.CommandParts[1] = $branchName
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                }
                else {
                    $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                }
            }
            "checkout" {
                if ($script:AppState.CommandParts.Count -eq 1) {
                    $script:AppState.CommandBuilderOptions = @("-b", "--track")
                    
                    # Get branches
                    $branches = (git branch --format="%(refname:short)" 2>$null) | Where-Object { $_ -match "\S+" }
                    if ($branches) {
                        $script:AppState.CommandBuilderOptions += $branches
                    }
                    $script:AppState.CommandBuilderOptions += @("Execute", "Clear")
                }
                elseif ($script:AppState.CommandParts.Count -eq 2 -and $script:AppState.CommandParts[1] -eq "-b") {
                    # Need to get new branch name
                    $branchName = Read-Host "Enter new branch name"
                    if ($branchName) {
                        $script:AppState.CommandParts += $branchName
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                    else {
                        $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                    }
                }
                else {
                    $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
                }
            }
            default {
                $script:AppState.CommandBuilderOptions = @("Execute", "Clear")
            }
        }
    }
}
