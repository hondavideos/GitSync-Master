function Get-GitCommandTooltip {
    <#
    .SYNOPSIS
        Gets contextual help information for Git commands.
    
    .DESCRIPTION
        Provides detailed tooltips and help information based on the current
        command parts selected in the command builder. The tooltips include
        descriptions, examples, and warnings specific to each Git command
        and its options.
    
    .PARAMETER CommandParts
        The array of command parts currently in the command builder.
    
    .EXAMPLE
        Get-GitCommandTooltip -CommandParts @("push", "origin")
    
    .OUTPUTS
        A custom object with Title, Description, Examples, and Warning properties.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$CommandParts
    )
    
    # Create tooltip object
    $tooltip = [PSCustomObject]@{
        Title = ""
        Description = ""
        Examples = @()
        Warning = ""
    }
    
    # If no command parts, return empty tooltip
    if ($CommandParts.Count -eq 0) {
        $tooltip.Title = "Git Commands"
        $tooltip.Description = "Select a Git command to see detailed help."
        return $tooltip
    }
    
    # Get primary command
    $primaryCommand = $CommandParts[0].ToLower()
    
    # Set tooltip properties based on command
    switch ($primaryCommand) {
        "status" {
            $tooltip.Title = "About: git status"
            $tooltip.Description = "Shows the current state of your working directory and staging area."
            $tooltip.Examples = @(
                "git status (show full status)",
                "git status -s (show short status)",
                "git status -b (show branch info)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "-s" {
                        $tooltip.Title = "About: git status -s"
                        $tooltip.Description = "Show status in short format, with file status codes."
                    }
                    "--short" {
                        $tooltip.Title = "About: git status --short"
                        $tooltip.Description = "Show status in short format, with file status codes."
                    }
                    "-b" {
                        $tooltip.Title = "About: git status -b"
                        $tooltip.Description = "Show the branch name and tracking information."
                    }
                    "--branch" {
                        $tooltip.Title = "About: git status --branch"
                        $tooltip.Description = "Show the branch name and tracking information."
                    }
                }
            }
        }
        "pull" {
            $tooltip.Title = "About: git pull"
            $tooltip.Description = "Fetch changes from a remote repository and merge them into your current branch."
            $tooltip.Examples = @(
                "git pull (fetch & merge from tracked upstream)",
                "git pull origin main (pull from specific branch)",
                "git pull --rebase (rebase local commits on top)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "--rebase" {
                        $tooltip.Title = "About: git pull --rebase"
                        $tooltip.Description = "Instead of merging, rebase your local commits on top of the remote changes."
                        $tooltip.Warning = "Rewrites commit history. Don't use on shared branches."
                    }
                    "--no-rebase" {
                        $tooltip.Title = "About: git pull --no-rebase"
                        $tooltip.Description = "Explicitly use merge strategy instead of rebasing."
                    }
                    "origin" {
                        $tooltip.Title = "About: git pull origin"
                        $tooltip.Description = "Pull changes from the 'origin' remote repository."
                    }
                }
            }
        }
        "push" {
            $tooltip.Title = "About: git push"
            $tooltip.Description = "Upload local repository changes to a remote repository."
            $tooltip.Examples = @(
                "git push (push to tracked upstream)",
                "git push origin main (specify remote/branch)",
                "git push -u origin feature (set upstream)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "-u" {
                        $tooltip.Title = "About: git push -u"
                        $tooltip.Description = "Set upstream tracking reference for the current branch."
                    }
                    "--force" {
                        $tooltip.Title = "About: git push --force"
                        $tooltip.Description = "Force push changes, even if it results in a non-fast-forward merge."
                        $tooltip.Warning = "Can overwrite remote changes. Use with extreme caution."
                    }
                    "origin" {
                        $tooltip.Title = "About: git push origin"
                        $tooltip.Description = "Push changes to the 'origin' remote repository."
                    }
                }
            }
        }
        "commit" {
            $tooltip.Title = "About: git commit"
            $tooltip.Description = "Record changes to the repository with a message describing the changes."
            $tooltip.Examples = @(
                'git commit -m "message" (with inline message)',
                "git commit -a (stage all modified files)",
                "git commit --amend (modify previous commit)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "-m" {
                        $tooltip.Title = "About: git commit -m"
                        $tooltip.Description = "Use the given message as the commit message."
                    }
                    "-a" {
                        $tooltip.Title = "About: git commit -a"
                        $tooltip.Description = "Automatically stage all modified files before committing."
                    }
                    "-am" {
                        $tooltip.Title = "About: git commit -am"
                        $tooltip.Description = "Combine -a and -m options. Stage all modified files and use the provided message."
                    }
                    "--amend" {
                        $tooltip.Title = "About: git commit --amend"
                        $tooltip.Description = "Replace the tip of the current branch by creating a new commit."
                        $tooltip.Warning = "Changes commit history. Don't amend published commits."
                    }
                }
            }
        }
        "branch" {
            $tooltip.Title = "About: git branch"
            $tooltip.Description = "List, create, or delete branches in your repository."
            $tooltip.Examples = @(
                "git branch (list local branches)",
                "git branch new-branch (create branch)",
                "git branch -d branch-name (delete branch)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "-a" {
                        $tooltip.Title = "About: git branch -a"
                        $tooltip.Description = "List all branches, both local and remote."
                    }
                    "-r" {
                        $tooltip.Title = "About: git branch -r"
                        $tooltip.Description = "List only remote-tracking branches."
                    }
                    "-d" {
                        $tooltip.Title = "About: git branch -d"
                        $tooltip.Description = "Delete a branch. The branch must be fully merged in its upstream branch."
                    }
                    "-D" {
                        $tooltip.Title = "About: git branch -D"
                        $tooltip.Description = "Force delete a branch, even if it has unmerged changes."
                        $tooltip.Warning = "Can result in data loss if branch has unique commits."
                    }
                    "--list" {
                        $tooltip.Title = "About: git branch --list"
                        $tooltip.Description = "List branches. Same as running git branch with no arguments."
                    }
                }
            }
        }
        "checkout" {
            $tooltip.Title = "About: git checkout"
            $tooltip.Description = "Switch branches or restore working tree files."
            $tooltip.Examples = @(
                "git checkout branch-name (switch branch)",
                "git checkout -b new-branch (create & switch)",
                "git checkout -- file.txt (discard changes)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "-b" {
                        $tooltip.Title = "About: git checkout -b"
                        $tooltip.Description = "Create a new branch and switch to it."
                    }
                    "--track" {
                        $tooltip.Title = "About: git checkout --track"
                        $tooltip.Description = "Set up tracking mode when checking out a remote branch."
                    }
                }
            }
        }
        "merge" {
            $tooltip.Title = "About: git merge"
            $tooltip.Description = "Join two or more development histories together."
            $tooltip.Examples = @(
                "git merge branch-name (merge into current)",
                "git merge --abort (cancel merge)",
                "git merge --no-ff branch (create merge commit)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "--abort" {
                        $tooltip.Title = "About: git merge --abort"
                        $tooltip.Description = "Abort the current conflict resolution process and restore pre-merge state."
                    }
                    "--no-ff" {
                        $tooltip.Title = "About: git merge --no-ff"
                        $tooltip.Description = "Create a merge commit even when fast-forward is possible."
                    }
                }
            }
        }
        "fetch" {
            $tooltip.Title = "About: git fetch"
            $tooltip.Description = "Download objects and refs from another repository, without merging."
            $tooltip.Examples = @(
                "git fetch (fetch from all remotes)",
                "git fetch origin (fetch from origin)",
                "git fetch --all (fetch from all remotes)"
            )
        }
        "stash" {
            $tooltip.Title = "About: git stash"
            $tooltip.Description = "Save your local modifications away and revert to a clean working directory."
            $tooltip.Examples = @(
                "git stash (stash changes)",
                "git stash pop (apply and remove stash)",
                "git stash list (show stashed changes)"
            )
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "pop" {
                        $tooltip.Title = "About: git stash pop"
                        $tooltip.Description = "Apply the stashed changes and remove them from the stash list."
                    }
                    "apply" {
                        $tooltip.Title = "About: git stash apply"
                        $tooltip.Description = "Apply the stashed changes but keep them in the stash list."
                    }
                    "list" {
                        $tooltip.Title = "About: git stash list"
                        $tooltip.Description = "List all stashed changes."
                    }
                    "drop" {
                        $tooltip.Title = "About: git stash drop"
                        $tooltip.Description = "Remove a single stashed state from the stash list."
                    }
                    "clear" {
                        $tooltip.Title = "About: git stash clear"
                        $tooltip.Description = "Remove all stashed states."
                        $tooltip.Warning = "This deletes all stashed changes permanently."
                    }
                }
            }
        }
        "reset" {
            $tooltip.Title = "About: git reset"
            $tooltip.Description = "Reset current HEAD to the specified state."
            $tooltip.Examples = @(
                "git reset HEAD file.txt (unstage file)",
                "git reset --soft HEAD~1 (undo last commit)",
                "git reset --hard HEAD (discard all changes)"
            )
            $tooltip.Warning = "Can result in data loss, especially with --hard option."
            
            # Add option-specific details
            if ($CommandParts.Count -gt 1) {
                $option = $CommandParts[1].ToLower()
                switch ($option) {
                    "--soft" {
                        $tooltip.Title = "About: git reset --soft"
                        $tooltip.Description = "Reset to a commit but keep changes staged."
                    }
                    "--mixed" {
                        $tooltip.Title = "About: git reset --mixed"
                        $tooltip.Description = "Reset to a commit and unstage changes."
                    }
                    "--hard" {
                        $tooltip.Title = "About: git reset --hard"
                        $tooltip.Description = "Reset to a commit and discard all changes in working directory."
                        $tooltip.Warning = "DANGER: This will permanently delete all uncommitted changes."
                    }
                }
            }
        }
        "clone" {
            $tooltip.Title = "About: git clone"
            $tooltip.Description = "Clone a repository into a new directory."
            $tooltip.Examples = @(
                "git clone https://github.com/user/repo.git",
                "git clone --depth 1 url (shallow clone)",
                "git clone url dir-name (specify dir)"
            )
        }
        "remote" {
            $tooltip.Title = "About: git remote"
            $tooltip.Description = "Manage the set of repositories tracked in your local repository."
            $tooltip.Examples = @(
                "git remote -v (show remote details)",
                "git remote add name url (add remote)",
                "git remote remove name (remove remote)"
            )
        }
        "log" {
            $tooltip.Title = "About: git log"
            $tooltip.Description = "Show commit logs with history information about your repository."
            $tooltip.Examples = @(
                "git log (show commit history)",
                "git log --oneline (compact format)",
                "git log -p file (show changes in file)"
            )
        }
        "diff" {
            $tooltip.Title = "About: git diff"
            $tooltip.Description = "Show changes between commits, commit and working tree, etc."
            $tooltip.Examples = @(
                "git diff (unstaged changes)",
                "git diff --staged (staged changes)",
                "git diff branch1 branch2 (between branches)"
            )
        }
        "init" {
            $tooltip.Title = "About: git init"
            $tooltip.Description = "Create an empty Git repository or reinitialize an existing one."
            $tooltip.Examples = @(
                "git init (in current directory)",
                "git init project-name (create directory)",
                "git init --bare (create bare repository)"
            )
        }
        default {
            # For other commands or unrecognized options
            $tooltip.Title = "About: git $primaryCommand"
            $tooltip.Description = "Use 'git $primaryCommand --help' to learn more about this command."
        }
    }
    
    return $tooltip
}
