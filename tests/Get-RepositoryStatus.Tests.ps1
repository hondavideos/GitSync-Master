$ErrorActionPreference = 'Stop'

Describe 'Get-RepositoryStatus' {
    BeforeAll {
        $moduleRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' 'GitSyncMaster')).Path
        . (Join-Path $moduleRoot 'Private/Git/Get-RepositoryStatus.ps1')
        $script:repoPath = Join-Path $moduleRoot 'TestRepo'
        if (-not (Test-Path (Join-Path $script:repoPath '.git'))) {
            Push-Location $script:repoPath
            git init -b main | Out-Null
            Pop-Location
        }
        $script:nonRepoPath = Join-Path ([System.IO.Path]::GetTempPath()) 'TempNonRepo'
        if (Test-Path $script:nonRepoPath) { Remove-Item $script:nonRepoPath -Recurse -Force }
        New-Item -ItemType Directory -Path $script:nonRepoPath | Out-Null
    }
    AfterAll {
        if (Test-Path $script:nonRepoPath) { Remove-Item $script:nonRepoPath -Recurse -Force }
    }

    Context 'inside a git repository' {
        It 'returns repository details' {
            Push-Location $script:repoPath
            $result = Get-RepositoryStatus
            Pop-Location

            $result.IsGitRepository | Should -BeTrue
            $result.RepoName | Should -Be 'TestRepo'
            $result.CurrentBranch | Should -Be 'main'
        }
    }

    Context 'outside a git repository' {
        It 'indicates not a git repository' {
            Push-Location $script:nonRepoPath
            $result = Get-RepositoryStatus
            Pop-Location

            $result.IsGitRepository | Should -BeFalse
            $result.RepoName | Should -Be $null
            $result.CurrentBranch | Should -Be 'Not a Git repository'
        }
    }
}
