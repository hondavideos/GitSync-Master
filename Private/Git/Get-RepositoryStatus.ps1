function Get-RepositoryStatus {
    <#
    .SYNOPSIS
        Gets the current Git repository status.
    
    .DESCRIPTION
        Retrieves detailed status information from the current Git repository,
        including branch name, tracking branch, modified files, and more.
    
    .EXAMPLE
        $status = Get-RepositoryStatus
        Write-Host "Current branch: $($status.CurrentBranch)"
    
    .OUTPUTS
        Returns a custom object with repository status information.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    try {
        # Check if we're in a git repository
        $isRepo = $false
        try {
            $isRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
        }
        catch {
            # Not a git repository
        }
        
        if (-not $isRepo) {
            return [PSCustomObject]@{
                IsGitRepository = $false
                RepoName = $null
                CurrentBranch = "Not a Git repository"
                Tracking = $null
                Ahead = 0
                Behind = 0
                Modified = @()
                Untracked = @()
                Staged = @()
                Deleted = @()
            }
        }
        
        # Get repo name
        $repoPath = git rev-parse --show-toplevel 2>$null
        $repoName = if ($repoPath) { Split-Path -Path $repoPath -Leaf } else { "Unknown" }
        
        # Get current branch
        $branchName = git symbolic-ref --short HEAD 2>$null
        if (-not $branchName) {
            $branchName = git rev-parse --short HEAD 2>$null
            if ($branchName) {
                $branchName = "detached at $branchName"
            }
            else {
                $branchName = "Unknown"
            }
        }
        
        # Get remote tracking information
        $trackingBranch = $null
        $ahead = 0
        $behind = 0
        
        $trackingInfo = git for-each-ref --format='%(upstream:short)' refs/heads/$branchName 2>$null
        if ($trackingInfo) {
            $trackingBranch = $trackingInfo
            
            # Get ahead/behind counts
            $aheadBehind = git rev-list --count --left-right $trackingBranch...HEAD 2>$null
            if ($aheadBehind -and $aheadBehind -match "(\d+)\s+(\d+)") {
                $behind = [int]$Matches[1]
                $ahead = [int]$Matches[2]
            }
        }
        
        # Get file status
        $modified = @()
        $untracked = @()
        $staged = @()
        $deleted = @()
        
        $status = git status --porcelain 2>$null
        if ($status) {
            $status | ForEach-Object {
                $line = $_
                $statusCode = $line.Substring(0, 2)
                $file = $line.Substring(3)
                
                # Staged files (including renamed and copied)
                if ($statusCode[0] -ne ' ' -and $statusCode[0] -ne '?') {
                    $staged += $file
                }
                
                # Modified but not staged
                if ($statusCode[1] -eq 'M') {
                    $modified += $file
                }
                
                # Untracked
                if ($statusCode -eq '??') {
                    $untracked += $file
                }
                
                # Deleted but not staged
                if ($statusCode[1] -eq 'D') {
                    $deleted += $file
                }
            }
        }
        
        return [PSCustomObject]@{
            IsGitRepository = $true
            RepoName = $repoName
            CurrentBranch = $branchName
            Tracking = $trackingBranch
            Ahead = $ahead
            Behind = $behind
            Modified = $modified
            Untracked = $untracked
            Staged = $staged
            Deleted = $deleted
        }
    }
    catch {
        Write-Verbose "Error getting repository status: $_"
        return [PSCustomObject]@{
            IsGitRepository = $false
            RepoName = $null
            CurrentBranch = "Error: $_"
            Tracking = $null
            Ahead = 0
            Behind = 0
            Modified = @()
            Untracked = @()
            Staged = @()
            Deleted = @()
        }
    }
}
