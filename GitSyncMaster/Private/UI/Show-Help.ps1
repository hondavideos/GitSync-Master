function Show-Help {
    <#
    .SYNOPSIS
        Shows context-sensitive help for Git operations.
    
    .DESCRIPTION
        Displays help information based on the current context or selected Git command.
        The help is displayed in a modal window that overlays the UI.
    
    .EXAMPLE
        Show-Help
        
        Shows help for the currently selected command or context.
    #>
    [CmdletBinding()]
    param()
    
    # Get terminal size
    $termSize = $script:AppState.TerminalSize
    
    # Calculate help window dimensions
    $helpWidth = [Math]::Min(70, $termSize.Width - 4)
    $helpHeight = [Math]::Min(20, $termSize.Height - 4)
    $helpX = [Math]::Floor(($termSize.Width - $helpWidth) / 2)
    $helpY = [Math]::Floor(($termSize.Height - $helpHeight) / 2)
    
    # Determine help content based on context
    $helpTitle = "Git Help"
    $helpContent = @()
    
    if ($script:AppState.SelectedPane -eq "CommandBuilder" -and $script:AppState.CommandParts.Count -gt 0) {
        # Show help for current command
        $command = $script:AppState.CommandParts[0]
        $helpTitle = "Git '$command' Command Help"
        
        if ($script:AppState.HelpText.ContainsKey($command)) {
            $helpContent += $script:AppState.HelpText[$command]
            $helpContent += ""
        }
        
        # Add command-specific help
        switch ($command) {
            "status" {
                $helpContent += "Purpose: Check the status of your working directory"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  -s, --short   : Give output in short format"
                $helpContent += "  -b, --branch  : Show branch information"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git status          : Show full status"
                $helpContent += "  git status -s       : Show short status"
                $helpContent += "  git status -b       : Show branch info"
            }
            "pull" {
                $helpContent += "Purpose: Fetch changes from a remote repository and integrate them"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  origin            : The remote repository name (usually 'origin')"
                $helpContent += "  <branch>          : The branch to pull from"
                $helpContent += "  --rebase          : Rebase local commits on top of pulled changes"
                $helpContent += "  --no-rebase       : Merge remote changes into local branch"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git pull                : Pull from tracking branch"
                $helpContent += "  git pull origin main    : Pull from origin/main"
                $helpContent += "  git pull --rebase       : Pull and rebase"
            }
            "push" {
                $helpContent += "Purpose: Send local commits to a remote repository"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  origin            : The remote repository name (usually 'origin')"
                $helpContent += "  <branch>          : The branch to push to"
                $helpContent += "  -u                : Set upstream tracking"
                $helpContent += "  --force           : Force push (USE WITH CAUTION!)"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git push                : Push to tracking branch"
                $helpContent += "  git push origin main    : Push to origin/main"
                $helpContent += "  git push -u origin feature : Push and set upstream"
            }
            "commit" {
                $helpContent += "Purpose: Record changes to the repository"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += '  -m "message"      : Commit message'
                $helpContent += "  -a                : Automatically stage all modified files"
                $helpContent += '  -am "message"     : Stage all modified files and commit with message'
                $helpContent += "  --amend           : Amend previous commit"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += '  git commit -m "Fix bug"    : Commit staged changes with message'
                $helpContent += '  git commit -am "Update"    : Stage all modified files and commit'
                $helpContent += ""
                $helpContent += "Note: You must stage changes first with 'git add' before commit,"
                $helpContent += "      unless you use the -a option."
            }
            "branch" {
                $helpContent += "Purpose: List, create, or delete branches"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  -a                : List all branches (local and remote)"
                $helpContent += "  -r                : List remote branches only"
                $helpContent += "  -d <branch>       : Delete a branch"
                $helpContent += "  -D <branch>       : Force delete a branch"
                $helpContent += "  <name>            : Create a new branch"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git branch               : List local branches"
                $helpContent += "  git branch feature       : Create branch 'feature'"
                $helpContent += "  git branch -d feature    : Delete branch 'feature'"
            }
            "checkout" {
                $helpContent += "Purpose: Switch branches or restore working files"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  <branch>          : Switch to this branch"
                $helpContent += "  -b <new-branch>   : Create and switch to a new branch"
                $helpContent += "  <file>            : Restore file from last commit"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git checkout main       : Switch to main branch"
                $helpContent += "  git checkout -b feature : Create and switch to feature branch"
                $helpContent += "  git checkout -- file.txt : Discard changes in file.txt"
            }
            "merge" {
                $helpContent += "Purpose: Join two or more development histories together"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  <branch>          : Branch to merge into current branch"
                $helpContent += "  --no-ff           : Create a merge commit even if fast-forward is possible"
                $helpContent += "  --abort           : Abort current merge"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git merge feature       : Merge feature branch into current branch"
                $helpContent += "  git merge --no-ff feature : Merge with merge commit"
                $helpContent += "  git merge --abort       : Abort conflicted merge"
            }
            "fetch" {
                $helpContent += "Purpose: Download objects and refs from another repository"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  origin            : Remote to fetch from (usually 'origin')"
                $helpContent += "  --all             : Fetch from all remotes"
                $helpContent += "  --prune           : Remove remote-tracking refs that no longer exist"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git fetch                : Fetch from origin"
                $helpContent += "  git fetch origin         : Fetch from origin"
                $helpContent += "  git fetch --all --prune  : Fetch from all remotes and prune"
            }
            "stash" {
                $helpContent += "Purpose: Temporarily stores modified, tracked files"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  push              : Save changes to stash (default if no args)"
                $helpContent += "  pop               : Apply and remove most recent stash"
                $helpContent += "  apply             : Apply but keep stash"
                $helpContent += "  list              : List stashes"
                $helpContent += "  drop              : Remove a stash"
                $helpContent += "  clear             : Remove all stashes"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git stash             : Stash changes"
                $helpContent += "  git stash pop         : Apply and remove most recent stash"
                $helpContent += "  git stash list        : List stashes"
            }
            "reset" {
                $helpContent += "Purpose: Reset current HEAD to specified state"
                $helpContent += ""
                $helpContent += "Common options:"
                $helpContent += "  --soft             : Keep changes in working directory and staging"
                $helpContent += "  --mixed            : Keep changes in working directory (default)"
                $helpContent += "  --hard             : Discard all changes (DESTRUCTIVE!)"
                $helpContent += "  HEAD~1             : Go back 1 commit"
                $helpContent += ""
                $helpContent += "Examples:"
                $helpContent += "  git reset --soft HEAD~1  : Undo last commit, keep changes staged"
                $helpContent += "  git reset HEAD file.txt  : Unstage file.txt"
                $helpContent += "  git reset --hard HEAD    : Discard all uncommitted changes"
                $helpContent += ""
                $helpContent += "WARNING: --hard will permanently delete your changes!"
            }
            default {
                $helpContent += "Basic help information for git $command"
                $helpContent += ""
                $helpContent += "For detailed help, run: git $command --help"
            }
        }
    }
    else {
        # Show general help
        $helpContent += "GitSync Terminal UI Help"
        $helpContent += "======================="
        $helpContent += ""
        $helpContent += "Navigation:"
        $helpContent += "  Tab            : Switch between panes"
        $helpContent += "  F1             : Show context-sensitive help"
        $helpContent += "  Arrow keys     : Navigate options"
        $helpContent += "  Enter          : Select option"
        $helpContent += "  Backspace      : Remove last command part"
        $helpContent += "  Esc/Alt+Q      : Exit application"
        $helpContent += "  Alt+T          : Start tutorial mode"
        $helpContent += ""
        $helpContent += "Panes:"
        $helpContent += "  Status         : Shows repository status"
        $helpContent += "  Command Builder: Build Git commands"
        $helpContent += "  Help & Tips    : Context-sensitive help"
        $helpContent += ""
        $helpContent += "Press any key to close help..."
    }
    
    # Draw help window
    Draw-Box -X $helpX -Y $helpY -Width $helpWidth -Height $helpHeight -Title $helpTitle -Styles 'Bold', 'FgBlue'
    
    # Display help content
    $contentX = $helpX + 2
    $contentY = $helpY + 1
    $contentWidth = $helpWidth - 4
    $contentHeight = $helpHeight - 2
    
    $maxLines = [Math]::Min($helpContent.Count, $contentHeight)
    
    for ($i = 0; $i -lt $maxLines; $i++) {
        $line = $helpContent[$i]
        
        # Truncate line if too long
        if ($line.Length -gt $contentWidth) {
            $line = $line.Substring(0, $contentWidth - 3) + "..."
        }
        
        Move-Cursor -Row ($contentY + $i) -Column $contentX
        Write-Host $line
        
        # Clear rest of line
        if ($line.Length -lt $contentWidth) {
            Write-Host " " * ($contentWidth - $line.Length) -NoNewline
        }
    }
    
    # Wait for any key press
    $null = [Console]::ReadKey($true)
}
