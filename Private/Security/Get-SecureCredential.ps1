function Get-SecureCredential {
    <#
    .SYNOPSIS
        Securely prompts for and retrieves Git credentials.
    
    .DESCRIPTION
        Provides a secure way to input and store Git credentials (username/token)
        with masked input for sensitive information.
    
    .PARAMETER CredentialName
        The name or identifier for the credential, usually for the repository.
    
    .PARAMETER UseCredentialManager
        If specified, uses the system credential manager for storing credentials.
    
    .EXAMPLE
        $cred = Get-SecureCredential -CredentialName "github.com"
        
        Securely prompts for GitHub credentials and returns a PSCredential object.
    
    .OUTPUTS
        Returns a PSCredential object.
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    param (
        [Parameter(Mandatory)]
        [string]$CredentialName,
        
        [Parameter()]
        [switch]$UseCredentialManager
    )
    
    try {
        # Get terminal size
        $terminalSize = Get-TerminalSize
        $width = $terminalSize.Width
        $height = $terminalSize.Height
        
        # Calculate dimensions
        $boxWidth = [Math]::Min($width - 4, 60)
        $boxHeight = 8
        $boxX = [Math]::Floor(($width - $boxWidth) / 2)
        $boxY = [Math]::Floor(($height - $boxHeight) / 2)
        
        # Save cursor position
        Write-Host "$script:EscChar[s" -NoNewline
        
        # Draw the credential prompt
        Clear-Screen
        Draw-Box -X $boxX -Y $boxY -Width $boxWidth -Height $boxHeight -Title "Git Credentials" -Styles 'Bold', 'FgBlue'
        
        # Show instructions
        Move-Cursor -Row ($boxY + 1) -Column ($boxX + 2)
        Write-Host "Enter credentials for: " -NoNewline
        Write-Colored -Text $CredentialName -Styles 'Bold', 'FgYellow'
        
        Move-Cursor -Row ($boxY + 2) -Column ($boxX + 2)
        Write-Host "For GitHub, use a Personal Access Token instead of password."
        
        # Prompt for username
        Move-Cursor -Row ($boxY + 4) -Column ($boxX + 2)
        Write-Host "Username: " -NoNewline
        $username = Read-Host
        
        # Prompt for password/token (masked)
        Move-Cursor -Row ($boxY + 5) -Column ($boxX + 2)
        Write-Host "Password/Token: " -NoNewline
        
        # Mask password input
        $password = ""
        while ($true) {
            $key = [Console]::ReadKey($true)
            
            if ($key.Key -eq 'Enter') {
                break
            }
            elseif ($key.Key -eq 'Backspace') {
                if ($password.Length -gt 0) {
                    $password = $password.Substring(0, $password.Length - 1)
                    Write-Host "`b `b" -NoNewline
                }
            }
            else {
                $password += $key.KeyChar
                Write-Host "*" -NoNewline
            }
        }
        
        Write-Host ""
        
        # Create secure string for password
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        
        # Create credential object
        $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)
        
        # Store in credential manager if requested
        if ($UseCredentialManager) {
            try {
                # Different approaches based on OS
                if ($script:IsWindowsPlatform) {
                    # Windows
                    if (Get-Command -Name 'cmdkey.exe' -ErrorAction SilentlyContinue) {
                        & cmdkey.exe /add:$CredentialName /user:$username /pass:$password
                    }
                }
                else {
                    # Linux/macOS - store in git credential helper
                    $credentialInput = "url=$CredentialName`nusername=$username`npassword=$password`n"
                    $credentialInput | git credential approve 2>$null
                }
                
                Move-Cursor -Row ($boxY + 6) -Column ($boxX + 2)
                Write-Colored -Text "Credentials stored successfully." -Styles 'FgGreen'
            }
            catch {
                Move-Cursor -Row ($boxY + 6) -Column ($boxX + 2)
                Write-Colored -Text "Failed to store credentials: $_" -Styles 'FgRed'
            }
        }
        
        # Pause briefly to show message
        Start-Sleep -Seconds 1
        
        # Restore cursor position
        Write-Host "$script:EscChar[u" -NoNewline
        
        # Clear screen
        Clear-Screen
        
        return $credential
    }
    catch {
        Write-Error "Error getting credentials: $_"
        
        # Ensure screen is restored
        Write-Host "$script:EscChar[u" -NoNewline
        Clear-Screen
        
        return $null
    }
}
