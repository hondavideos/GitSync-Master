function Sync-Repository {
    <#
    .SYNOPSIS
        Synchronizes a Git repository with remote.
    
    .DESCRIPTION
        Performs a complete synchronization workflow including fetching, 
        pulling changes, and pushing local commits.
    
    .PARAMETER Path
        The path to the Git repository. Defaults to current directory.
    
    .PARAMETER Remote
        The remote repository name. Defaults to 'origin'.
    
    .PARAMETER Branch
        The branch to synchronize. If not specified, uses the current branch.
    
    .PARAMETER PullOnly
        If specified, only pulls changes without pushing.
    
    .PARAMETER DryRun
        If specified, shows what commands would be executed without actually executing them.
    
    .EXAMPLE
        Sync-Repository
        
        Synchronizes the current directory's repository with its remote.
    
    .EXAMPLE
        Sync-Repository -Path C:\Projects\MyRepo -Branch feature-branch -DryRun
        
        Shows what commands would be executed to synchronize the specified repository and branch.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,
        
        [Parameter()]
        [string]$Remote = "origin",
        
        [Parameter()]
        [string]$Branch,
        
        [Parameter()]
        [switch]$PullOnly,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    try {
        # Store original location
        $originalLocation = Get-Location
        
        # Change to repository path
        if (Test-Path -Path $Path -PathType Container) {
            Set-Location -Path $Path
        }
        else {
            throw "The specified path does not exist: $Path"
        }
        
        # Check if this is a Git repository
        $isRepo = $false
        try {
            $isRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
        }
        catch {
            # Not a git repository
        }
        
        if (-not $isRepo) {
            throw "The specified path is not a Git repository: $Path"
        }
        
        # Get current branch if not specified
        if (-not $Branch) {
            $Branch = git symbolic-ref --short HEAD 2>$null
            if (-not $Branch) {
                throw "Could not determine current branch. You may be in a detached HEAD state."
            }
        }
        
        # Get repository status
        $status = Get-RepositoryStatus
        
        # Check for uncommitted changes
        if ($status.Modified.Count -gt 0 -or $status.Staged.Count -gt 0) {
            $uncommittedChanges = $true
            Write-Warning "There are uncommitted changes in the repository."
            
            if (-not $DryRun) {
                Write-Host "Options:"
                Write-Host "1. Stash changes (temporarily store changes)"
                Write-Host "2. Continue anyway (may cause conflicts)"
                Write-Host "3. Abort sync"
                
                $choice = Read-Host "Enter choice (1-3)"
                
                switch ($choice) {
                    "1" {
                        Write-Host "Stashing changes..."
                        Invoke-GitCommand -Command "stash save `"Auto-stashed during Sync-Repository`""
                    }
                    "2" {
                        Write-Warning "Continuing with uncommitted changes. This may cause conflicts."
                    }
                    "3" {
                        throw "Sync aborted due to uncommitted changes."
                    }
                    default {
                        throw "Invalid choice. Sync aborted."
                    }
                }
            }
        }
        
        # Perform fetch to get remote changes
        if ($DryRun) {
            Write-Host "Would execute: git fetch $Remote"
        }
        else {
            Write-Host "Fetching from $Remote..."
            Invoke-GitCommand -Command "fetch $Remote"
        }
        
        # Check if remote branch exists
        $remoteBranchExists = $false
        if ($DryRun) {
            $remoteBranchExists = $true # Assume exists in dry run
        }
        else {
            $remoteBranchExists = (git ls-remote --heads $Remote $Branch 2>$null) -ne $null
        }
        
        if (-not $remoteBranchExists) {
            if ($DryRun) {
                Write-Host "Would execute: git push -u $Remote $Branch"
            }
            else {
                Write-Host "Remote branch '$Branch' does not exist. Creating and pushing..."
                Invoke-GitCommand -Command "push -u $Remote $Branch"
            }
        }
        else {
            # Pull changes
            if ($DryRun) {
                Write-Host "Would execute: git pull $Remote $Branch"
            }
            else {
                Write-Host "Pulling changes from $Remote/$Branch..."
                Invoke-GitCommand -Command "pull $Remote $Branch"
            }
            
            # Push changes if not pull-only
            if (-not $PullOnly) {
                if ($DryRun) {
                    Write-Host "Would execute: git push $Remote $Branch"
                }
                else {
                    Write-Host "Pushing changes to $Remote/$Branch..."
                    try {
                        Invoke-GitCommand -Command "push $Remote $Branch" -ValidateDestructive
                    }
                    catch {
                        # Handle push errors, such as non-fast-forward
                        if ($_ -match "non-fast-forward" -or $_ -match "rejected") {
                            Write-Warning "Push failed. Remote has changes that you don't have locally."
                            
                            Write-Host "Options:"
                            Write-Host "1. Pull with rebase and try again"
                            Write-Host "2. Force push (CAUTION: overwrites remote changes!)"
                            Write-Host "3. Abort push"
                            
                            $choice = Read-Host "Enter choice (1-3)"
                            
                            switch ($choice) {
                                "1" {
                                    Write-Host "Pulling with rebase..."
                                    Invoke-GitCommand -Command "pull --rebase $Remote $Branch"
                                    Write-Host "Pushing again..."
                                    Invoke-GitCommand -Command "push $Remote $Branch"
                                }
                                "2" {
                                    Write-Warning "Force pushing will OVERWRITE remote changes!"
                                    Invoke-GitCommand -Command "push --force $Remote $Branch" -ValidateDestructive
                                }
                                "3" {
                                    Write-Host "Push aborted."
                                }
                                default {
                                    Write-Host "Invalid choice. Push aborted."
                                }
                            }
                        }
                        else {
                            # Re-throw other errors
                            throw $_
                        }
                    }
                }
            }
        }
        
        # Success message
        if ($DryRun) {
            Write-Host "Dry run complete. No changes were made."
        }
        else {
            Write-Host "Repository synchronized successfully." -ForegroundColor Green
            
            # Pop stashed changes if we stashed them
            if ($uncommittedChanges -and $choice -eq "1") {
                Write-Host "Restoring stashed changes..."
                Invoke-GitCommand -Command "stash pop"
            }
        }
    }
    catch {
        Write-Error "Error synchronizing repository: $_"
    }
    finally {
        # Restore original location
        Set-Location -Path $originalLocation
    }
}
