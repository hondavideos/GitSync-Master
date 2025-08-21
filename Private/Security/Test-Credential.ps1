function Test-Credential {
    <#
    .SYNOPSIS
        Tests if Git credentials are valid.
    
    .DESCRIPTION
        Verifies if the provided Git credentials are valid by attempting
        to authenticate with the remote repository.
    
    .PARAMETER Credential
        The PSCredential object containing username and password/token.
    
    .PARAMETER RemoteUrl
        The URL of the remote Git repository to test against.
    
    .EXAMPLE
        $credential = Get-SecureCredential -CredentialName "github.com"
        Test-Credential -Credential $credential -RemoteUrl "https://github.com/user/repo.git"
        
        Tests if the credentials are valid for the specified GitHub repository.
    
    .OUTPUTS
        Returns a boolean indicating if the credentials are valid.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory)]
        [string]$RemoteUrl
    )
    
    try {
        # Extract username and password from credential
        $username = $Credential.UserName
        $password = $Credential.GetNetworkCredential().Password
        
        # Format URL with credentials
        $uri = [System.Uri]$RemoteUrl
        $scheme = $uri.Scheme
        $host = $uri.Host
        $path = $uri.PathAndQuery
        
        # Normalize the URL
        if ($RemoteUrl -match "^https?://") {
            # Build URL with embedded credentials
            $testUrl = "${scheme}://${username}:${password}@${host}${path}"
        }
        elseif ($RemoteUrl -match "^git@") {
            # SSH URL, can't easily test with embedded credentials
            # Just check if the SSH key is available
            $testUrl = $RemoteUrl
        }
        else {
            throw "Unsupported URL format: $RemoteUrl"
        }
        
        # Try to perform a git operation that requires authentication
        $output = & git ls-remote --quiet --exit-code $testUrl 2>&1
        
        # Check if the command was successful
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        else {
            Write-Verbose "Authentication failed: $output"
            return $false
        }
    }
    catch {
        Write-Verbose "Error testing credentials: $_"
        return $false
    }
}
