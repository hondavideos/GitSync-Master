#region Module Imports
# Import all private functions
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue)
foreach ($Private in $PrivateFunctions) {
    try {
        . $Private.FullName
    }
    catch {
        Write-Error -Message "Failed to import private function $($Private.FullName): $_"
    }
}

# Import all public functions
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public -Filter "*.ps1" -ErrorAction SilentlyContinue)
foreach ($Public in $PublicFunctions) {
    try {
        . $Public.FullName
    }
    catch {
        Write-Error -Message "Failed to import public function $($Public.FullName): $_"
    }
}
#endregion

#region Exported Functions
# Export public functions
Export-ModuleMember -Function (($PublicFunctions | Select-Object -ExpandProperty BaseName) -join ', ')
#endregion

#region Module Variables
# Module-level variables
$script:GitSyncTUIVersion = "1.0.0"
$script:IsWindowsPlatform = $PSVersionTable.Platform -eq 'Win32NT' -or $null -eq $PSVersionTable.Platform
$script:EscChar = [char]27
$script:ModuleRoot = $PSScriptRoot
#endregion

#region ANSI Escape Code Functions
function script:Get-ANSIEscape {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Reset', 'Bold', 'Underline', 'FgBlack', 'FgRed', 'FgGreen', 'FgYellow', 'FgBlue', 'FgMagenta', 'FgCyan', 'FgWhite', 'BgBlack', 'BgRed', 'BgGreen', 'BgYellow', 'BgBlue', 'BgMagenta', 'BgCyan', 'BgWhite', 'Clear', 'ClearLine')]
        [string]$Code
    )

    $codeMap = @{
        'Reset'     = "$script:EscChar[0m"
        'Bold'      = "$script:EscChar[1m"
        'Underline' = "$script:EscChar[4m"
        'FgBlack'   = "$script:EscChar[30m"
        'FgRed'     = "$script:EscChar[31m"
        'FgGreen'   = "$script:EscChar[32m"
        'FgYellow'  = "$script:EscChar[33m"
        'FgBlue'    = "$script:EscChar[34m"
        'FgMagenta' = "$script:EscChar[35m"
        'FgCyan'    = "$script:EscChar[36m"
        'FgWhite'   = "$script:EscChar[37m"
        'BgBlack'   = "$script:EscChar[40m"
        'BgRed'     = "$script:EscChar[41m"
        'BgGreen'   = "$script:EscChar[42m"
        'BgYellow'  = "$script:EscChar[43m"
        'BgBlue'    = "$script:EscChar[44m"
        'BgMagenta' = "$script:EscChar[45m"
        'BgCyan'    = "$script:EscChar[46m"
        'BgWhite'   = "$script:EscChar[47m"
        'Clear'     = "$script:EscChar[2J$script:EscChar[H"
        'ClearLine' = "$script:EscChar[2K$script:EscChar[G"
    }

    return $codeMap[$Code]
}

function script:Write-Colored {
    param(
        [Parameter(Position = 0)] # Removed Mandatory=$true and AllowEmptyString=$true
        [string]$Text,
        
        [Parameter(Position = 1)]
        [ValidateSet('Reset', 'Bold', 'Underline', 'FgBlack', 'FgRed', 'FgGreen', 'FgYellow', 'FgBlue', 'FgMagenta', 'FgCyan', 'FgWhite', 'BgBlack', 'BgRed', 'BgGreen', 'BgYellow', 'BgBlue', 'BgMagenta', 'BgCyan', 'BgWhite')]
        [string[]]$Styles = @('Reset'),
        
        [switch]$NoNewline
    )
    
    # Ensure Text is not null or empty for Write-Host
    if ([string]::IsNullOrEmpty($Text)) {
        $Text = ""
    }
    
    $styleString = ""
    foreach ($style in $Styles) {
        $styleString += (Get-ANSIEscape -Code $style)
    }
    
    $resetString = Get-ANSIEscape -Code 'Reset'
    
    if ($NoNewline) {
        Write-Host "$styleString$Text$resetString" -NoNewline
    }
    else {
        Write-Host "$styleString$Text$resetString"
    }
}

function script:Move-Cursor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Row,
        
        [Parameter(Mandatory)]
        [int]$Column
    )
    
    Write-Host "$script:EscChar[$Row;${Column}H" -NoNewline
}

function script:Clear-Screen {
    [CmdletBinding()]
    param()
    
    Write-Host (Get-ANSIEscape -Code 'Clear') -NoNewline
}

function script:Clear-Line {
    [CmdletBinding()]
    param()
    
    Write-Host (Get-ANSIEscape -Code 'ClearLine') -NoNewline
}

function script:Draw-Box {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$X,
        
        [Parameter(Mandatory)]
        [int]$Column
    )
    
    Write-Host "$script:EscChar[$Row;${Column}H" -NoNewline
}

function script:Clear-Screen {
    [CmdletBinding()]
    param()
    
    Write-Host (Get-ANSIEscape -Code 'Clear') -NoNewline
}

function script:Clear-Line {
    [CmdletBinding()]
    param()
    
    Write-Host (Get-ANSIEscape -Code 'ClearLine') -NoNewline
}

function script:Draw-Box {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$X,
        
        [Parameter(Mandatory)]
        [int]$Y,
        
        [Parameter(Mandatory)]
        [int]$Width,
        
        [Parameter(Mandatory)]
        [int]$Height,
        
        [string]$Title = "",
        
        [ValidateSet('Reset', 'Bold', 'Underline', 'FgBlack', 'FgRed', 'FgGreen', 'FgYellow', 'FgBlue', 'FgMagenta', 'FgCyan', 'FgWhite', 'BgBlack', 'BgRed', 'BgGreen', 'BgYellow', 'BgBlue', 'BgMagenta', 'BgCyan', 'BgWhite')]
        [string[]]$Styles = @('Reset')
    )
    
    $horizontalBorder = "─" * ($Width - 2)
    $topBorder = "┌$horizontalBorder┐"
    $bottomBorder = "└$horizontalBorder┘"
    $space = " " * ($Width - 2)
    
    # Draw the box
    Move-Cursor -Row $Y -Column $X
    Write-Colored -Text $topBorder -Styles $Styles -NoNewline
    
    for ($i = 1; $i -lt $Height - 1; $i++) {
        Move-Cursor -Row ($Y + $i) -Column $X
        Write-Colored -Text "│$space│" -Styles $Styles -NoNewline
    }
    # This is the correct closing brace for the for loop
} # This is the correct closing brace for the function
#endregion

#region Module Init
# Check if Git is installed
try {
    $gitVersion = & git --version
    Write-Verbose "Git found: $gitVersion"
}
catch {
    Write-Warning "Git command not found. Please ensure Git is installed and available in PATH."
}

# Set up console encoding for special characters
if ($script:IsWindowsPlatform) {
    try {
        [console]::OutputEncoding = [System.Text.Encoding]::UTF8
    }
    catch {
        Write-Warning "Unable to set console encoding to UTF-8. Box characters may not display correctly."
    }
}
#endregion
