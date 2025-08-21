function Invoke-GitCommand {
    <#
    .SYNOPSIS
        Safely executes Git commands and handles errors.
    
    .DESCRIPTION
        Executes Git commands with error handling and returns the command output.
        Can perform validation before executing potentially destructive commands.
    
    .PARAMETER Command
        The Git command to execute (without the 'git' prefix).
    
    .PARAMETER ValidateDestructive
        If specified, shows a confirmation prompt for potentially destructive commands.
    
    .EXAMPLE
        $output = Invoke-GitCommand -Command "status -s"
        
        Executes 'git status -s' and returns the output.
    
    .EXAMPLE
        $output = Invoke-GitCommand -Command "push origin main" -ValidateDestructive
        
        Shows a confirmation prompt before executing 'git push origin main'.
    
    .OUTPUTS
        Returns the command output as a string array.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory)]
        [string]$Command,
        
        [Parameter()]
        [switch]$ValidateDestructive
    )
    
    # Determine if this is a potentially destructive command
    $destructiveCommands = @(
        "push --force", "push -f",
        "reset --hard", 
        "clean -f", 
        "branch -D",
        "checkout -f"
    )
    
    $isDestructive = $false
    foreach ($dc in $destructiveCommands) {
        if ($Command -like "$dc*") {
            $isDestructive = $true
            break
        }
    }
    
    # Ask for confirmation if destructive and validation requested
    if ($isDestructive -and $ValidateDestructive) {
        # Save cursor position
        Write-Host "$script:EscChar[s" -NoNewline
        
        # Clear the screen temporarily to show warning
        Clear-Screen
        
        Write-Colored -Text "WARNING: Potentially Destructive Command" -Styles 'Bold', 'FgRed'
        Write-Host ""
        Write-Host "You are about to execute: git $Command"
        Write-Host ""
        Write-Colored -Text "This command may cause permanent changes or data loss." -Styles 'FgYellow'
        Write-Host ""
        Write-Host "Are you sure you want to proceed? (y/N): " -NoNewline
        
        $response = [Console]::ReadKey($true)
        Write-Host ""
        
        # Restore screen
        Write-Host "$script:EscChar[u" -NoNewline
        
        if ($response.Key -ne 'Y' -and $response.Key -ne 'y') {
            throw "Command execution cancelled by user."
        }
    }
    
    # Execute the command
    try {
        # Split the command into arguments for proper shell handling
        $commandArgs = @()
        $currentArg = ""
        $inQuotes = $false
        $quoteChar = ""
        
        for ($i = 0; $i -lt $Command.Length; $i++) {
            $char = $Command[$i]
            
            if (($char -eq '"' -or $char -eq "'") -and ($i -eq 0 -or $Command[$i-1] -ne '\')) {
                if ($inQuotes -and $char -eq $quoteChar) {
                    # Closing quote
                    $inQuotes = $false
                    $quoteChar = ""
                }
                elseif (-not $inQuotes) {
                    # Opening quote
                    $inQuotes = $true
                    $quoteChar = $char
                }
                else {
                    # Different quote inside quotes (e.g. " inside ')
                    $currentArg += $char
                }
            }
            elseif ($char -eq ' ' -and -not $inQuotes) {
                # Space outside quotes - end of argument
                if ($currentArg) {
                    $commandArgs += $currentArg
                    $currentArg = ""
                }
            }
            else {
                # Normal character
                $currentArg += $char
            }
        }
        
        # Add final argument if any
        if ($currentArg) {
            $commandArgs += $currentArg
        }
        
        # Execute Git command
        $output = & git $commandArgs 2>&1
        
        # Check if command executed successfully
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            # Command failed
            throw "Git command failed with exit code ${exitCode}: $output"
        }
        
        return $output
    }
    catch {
        # Handle errors
        throw "Error executing Git command: $_"
    }
}
