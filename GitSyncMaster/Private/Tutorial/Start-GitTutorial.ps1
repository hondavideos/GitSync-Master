function Start-GitTutorial {
    <#
    .SYNOPSIS
        Starts the interactive Git tutorial mode.
    
    .DESCRIPTION
        Provides a guided tutorial experience for learning Git concepts
        using simulated repositories and interactive examples.
    
    .EXAMPLE
        Start-GitTutorial
        
        Launches the Git tutorial mode.
    #>
    [CmdletBinding()]
    param()
    
    # Temporary directory for tutorial repository
    $tutorialRepoPath = Join-Path ([System.IO.Path]::GetTempPath()) "GitSyncTUI_Tutorial"
    
    # Terminal properties
    $terminalSize = Get-TerminalSize
    $width = $terminalSize.Width
    $height = $terminalSize.Height
    
    # Tutorial state tracking
    $tutorialState = @{
        CurrentStep = 0
        TotalSteps = 7
        RepoPath = $tutorialRepoPath
        ExitRequested = $false
    }
    
    # Steps content: Title, Description, and Action to perform
    $tutorialSteps = @(
        @{
            Title = "Welcome to Git Tutorial"
            Description = @"
This tutorial will guide you through basic Git concepts and commands.
We'll create a temporary repository and practice common Git workflows.

You'll learn:
• Creating a repository
• Making changes and commits
• Viewing repository status
• Branching and merging
• Remote repositories concepts

Press Enter to continue or Esc to exit at any time.
"@
            Action = { 
                # Initial setup - Create temporary directory
                if (Test-Path $tutorialState.RepoPath) {
                    Remove-Item -Path $tutorialState.RepoPath -Recurse -Force -ErrorAction SilentlyContinue
                }
                New-Item -Path $tutorialState.RepoPath -ItemType Directory -Force | Out-Null
            }
        },
        @{
            Title = "Step 1: Creating a Git Repository"
            Description = @"
Let's start by creating a new Git repository.

When you create a repository, Git initializes a hidden .git directory
that stores all the version history and configuration.

Press Enter to initialize a Git repository in our tutorial folder.
"@
            Action = {
                # Initialize Git repository
                Set-Location -Path $tutorialState.RepoPath
                if (-not (Test-Path (Join-Path $tutorialState.RepoPath ".git"))) {
                    $output = Invoke-Expression "git init" 2>&1
                    $script:AppState.Messages += "Repository initialized: $tutorialState.RepoPath"
                }
            }
        },
        @{
            Title = "Step 2: Creating Your First File"
            Description = @"
Now let's create a file in our repository.

For version control to be useful, we need files to track.
We'll create a simple README.md file for our project.

Press Enter to create this file.
"@
            Action = {
                # Create README.md file
                $readmePath = Join-Path $tutorialState.RepoPath "README.md"
                $readmeContent = @"
# Tutorial Project

This is a sample project for the Git tutorial.

## Features
- Learning Git basics
- Understanding version control
"@
                Set-Content -Path $readmePath -Value $readmeContent
                $script:AppState.Messages += "Created README.md file"
                $script:AppState.RefreshStatus = $true
            }
        },
        @{
            Title = "Step 3: Staging and Committing Changes"
            Description = @"
Let's stage and commit the README.md file.

In Git, you first 'stage' changes (git add) to prepare them for commit,
then you 'commit' (git commit) to save them in the repository history.

Press Enter to stage and commit the README.md file.
"@
            Action = {
                # Stage and commit README
                try {
                    Invoke-Expression "git add README.md" 2>&1 | Out-Null
                    Invoke-Expression 'git commit -m "Initial commit: Add README.md"' 2>&1 | Out-Null
                    $script:AppState.Messages += "Changes staged and committed"
                    $script:AppState.RefreshStatus = $true
                }
                catch {
                    $script:AppState.ErrorMessage = "Error committing: $_"
                }
            }
        },
        @{
            Title = "Step 4: Working with Branches"
            Description = @"
Branches allow you to work on different features or fixes independently.

Let's create a new branch called 'feature' and make a change in that branch.

Press Enter to create a branch and switch to it.
"@
            Action = {
                # Create and switch to feature branch
                try {
                    Invoke-Expression "git checkout -b feature" 2>&1 | Out-Null
                    
                    # Make changes in the feature branch
                    $readmePath = Join-Path $tutorialState.RepoPath "README.md"
                    $readmeContent = Get-Content -Path $readmePath
                    $readmeContent += @"

## New Feature
- This line was added in the feature branch
"@
                    Set-Content -Path $readmePath -Value $readmeContent
                    
                    $script:AppState.Messages += "Created and switched to 'feature' branch"
                    $script:AppState.Messages += "Modified README.md in feature branch"
                    $script:AppState.RefreshStatus = $true
                }
                catch {
                    $script:AppState.ErrorMessage = "Error creating branch: $_"
                }
            }
        },
        @{
            Title = "Step 5: Committing Branch Changes"
            Description = @"
Now let's commit the changes we made in the feature branch.

This will save our feature branch changes to the Git history.

Press Enter to stage and commit these changes.
"@
            Action = {
                # Commit changes in feature branch
                try {
                    Invoke-Expression "git add README.md" 2>&1 | Out-Null
                    Invoke-Expression 'git commit -m "Add feature details to README"' 2>&1 | Out-Null
                    $script:AppState.Messages += "Changes committed to feature branch"
                    $script:AppState.RefreshStatus = $true
                }
                catch {
                    $script:AppState.ErrorMessage = "Error committing: $_"
                }
            }
        },
        @{
            Title = "Step 6: Merging Branches"
            Description = @"
Now that our feature is complete, let's merge it back to the main branch.

Merging combines the changes from one branch into another.

Press Enter to switch back to main and merge the feature branch.
"@
            Action = {
                # Switch to main and merge feature branch
                try {
                    # Determine main branch name (main or master)
                    $mainBranch = "main"
                    $branches = Invoke-Expression "git branch" 2>&1
                    if ($branches -match "master") {
                        $mainBranch = "master"
                    }
                    
                    Invoke-Expression "git checkout $mainBranch" 2>&1 | Out-Null
                    Invoke-Expression "git merge feature" 2>&1 | Out-Null
                    $script:AppState.Messages += "Switched to $mainBranch and merged feature branch"
                    $script:AppState.RefreshStatus = $true
                }
                catch {
                    $script:AppState.ErrorMessage = "Error merging: $_"
                }
            }
        },
        @{
            Title = "Tutorial Complete!"
            Description = @"
Congratulations! You've completed the Git basics tutorial.

Here's what you've learned:
• Creating a Git repository
• Staging and committing changes
• Creating and switching branches
• Making changes in a branch
• Merging branches

In a real project, you would also work with remote repositories
using commands like 'git clone', 'git pull', and 'git push'.

Press Enter to return to the main GitSyncTUI interface.
"@
            Action = {
                # Clean up tutorial repository
                Set-Location -Path $originalLocation
                
                try {
                    if (Test-Path $tutorialState.RepoPath) {
                        Remove-Item -Path $tutorialState.RepoPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Error cleaning up tutorial repo: $_"
                }
                
                $tutorialState.ExitRequested = $true
                $script:AppState.RefreshStatus = $true
            }
        }
    )
    
    # Store original location to return to after tutorial
    $originalLocation = Get-Location
    
    try {
        # Main tutorial loop
        while (-not $tutorialState.ExitRequested) {
            # Get current step
            $currentStep = $tutorialSteps[$tutorialState.CurrentStep]
            
            # Clear screen
            Clear-Screen
            
            # Draw tutorial container
            $boxWidth = [Math]::Min($width - 6, 76)
            $boxHeight = [Math]::Min($height - 4, 22)
            $boxX = [Math]::Floor(($width - $boxWidth) / 2)
            $boxY = [Math]::Floor(($height - $boxHeight) / 2)
            
            Draw-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight -Title "Git Tutorial" -Styles 'Bold', 'FgCyan'
            
            # Draw progress bar
            $progressBarWidth = $boxWidth - 10
            $progressPercent = $tutorialState.CurrentStep / ($tutorialState.TotalSteps - 1)
            $progressFilled = [Math]::Floor($progressBarWidth * $progressPercent)
            
            Move-Cursor -Row ($boxY + 1) -Column ($boxX + 5)
            Write-Colored -Text "Step $($tutorialState.CurrentStep + 1)/$($tutorialState.TotalSteps): " -Styles 'Bold' -NoNewline
            
            # Step title
            Write-Colored -Text $currentStep.Title -Styles 'FgYellow'
            
            Move-Cursor -Row ($boxY + 2) -Column ($boxX + 5)
            Write-Host "["  -NoNewline
            Write-Colored -Text ("=" * $progressFilled) -Styles 'FgGreen' -NoNewline
            Write-Host (" " * ($progressBarWidth - $progressFilled)) -NoNewline
            Write-Host "]" -NoNewline
            Write-Host " $([Math]::Floor($progressPercent * 100))%" -NoNewline
            
            # Step description
            $descLines = $currentStep.Description -split "`n"
            for ($i = 0; $i -lt [Math]::Min($descLines.Count, $boxHeight - 7); $i++) {
                Move-Cursor -Row ($boxY + 4 + $i) -Column ($boxX + 3)
                Write-Host $descLines[$i]
            }
            
            # Command preview (if applicable)
            if ($tutorialState.CurrentStep -gt 0 -and $tutorialState.CurrentStep -lt ($tutorialState.TotalSteps - 1)) {
                Move-Cursor -Row ($boxY + $boxHeight - 4) -Column ($boxX + 3)
                Write-Colored -Text "Repository Status:" -Styles 'Bold'
                
                if (Test-Path (Join-Path $tutorialState.RepoPath ".git")) {
                    try {
                        # Show simplified status
                        Set-Location -Path $tutorialState.RepoPath
                        $branch = Invoke-Expression "git branch --show-current" 2>&1
                        
                        Move-Cursor -Row ($boxY + $boxHeight - 3) -Column ($boxX + 5)
                        Write-Colored -Text "Branch: " -NoNewline
                        Write-Colored -Text $branch -Styles 'FgGreen'
                        
                        # Get status
                        $status = Invoke-Expression "git status --porcelain" 2>&1
                        if ($status) {
                            Move-Cursor -Row ($boxY + $boxHeight - 2) -Column ($boxX + 5)
                            Write-Colored -Text "Changes: " -NoNewline
                            Write-Colored -Text "Pending changes in repository" -Styles 'FgYellow'
                        }
                        else {
                            Move-Cursor -Row ($boxY + $boxHeight - 2) -Column ($boxX + 5)
                            Write-Colored -Text "Changes: " -NoNewline
                            Write-Colored -Text "Working directory clean" -Styles 'FgGreen'
                        }
                    }
                    catch {
                        Move-Cursor -Row ($boxY + $boxHeight - 3) -Column ($boxX + 5)
                        Write-Colored -Text "Error checking status: $_" -Styles 'FgRed'
                    }
                }
                else {
                    Move-Cursor -Row ($boxY + $boxHeight - 3) -Column ($boxX + 5)
                    Write-Colored -Text "No Git repository initialized yet" -Styles 'FgYellow'
                }
            }
            
            # Footer
            Move-Cursor -Row ($boxY + $boxHeight - 1) -Column ($boxX + 3)
            Write-Colored -Text "Press Enter to continue or Esc to exit tutorial" -Styles 'FgCyan'
            
            # Wait for user input
            $key = [Console]::ReadKey($true)
            
            if ($key.Key -eq 'Enter') {
                # Execute step action
                if ($currentStep.Action) {
                    & $currentStep.Action
                }
                
                # Move to next step
                $tutorialState.CurrentStep++
                if ($tutorialState.CurrentStep -ge $tutorialState.TotalSteps) {
                    $tutorialState.ExitRequested = $true
                }
            }
            elseif ($key.Key -eq 'Escape') {
                # Exit tutorial
                $tutorialState.ExitRequested = $true
                
                # Clean up tutorial repository
                Set-Location -Path $originalLocation
                
                try {
                    if (Test-Path $tutorialState.RepoPath) {
                        Remove-Item -Path $tutorialState.RepoPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
                catch {
                    Write-Verbose "Error cleaning up tutorial repo: $_"
                }
            }
        }
    }
    catch {
        Write-Error "Error during tutorial: $_"
    }
    finally {
        # Ensure we're back at the original location
        Set-Location -Path $originalLocation
    }
}

