# PSDotEnv.psm1
# A PowerShell module that mimics python-dotenv functionality
# Safely parses .env files and injects key-value pairs into $env:

<#
.SYNOPSIS
    Imports environment variables from a .env file into the current PowerShell session.

.DESCRIPTION
    Import-DotEnv reads a .env file and sets the key-value pairs as environment variables
    in the current PowerShell process. It supports:
    - Single and double quoted values
    - Inline comments (stripped before parsing)
    - Full-line comments (lines starting with #)
    - Blank lines (ignored)
    - Values containing equals signs

.PARAMETER Path
    The path to the .env file. Defaults to ".env" in the current working directory.

.PARAMETER Clobber
    If specified, existing environment variables will be overwritten. 
    If not specified (default), keys that already exist in the environment are skipped.

.PARAMETER PassThru
    If specified, returns a hashtable containing the loaded keys and values.

.EXAMPLE
    Import-DotEnv
    # Loads variables from .env in the current directory

.EXAMPLE
    Import-DotEnv -Path "C:\myapp\.env" -Clobber
    # Loads variables from specific path, overwriting existing vars

.EXAMPLE
    $vars = Import-DotEnv -PassThru
    # Returns hashtable of loaded variables
#>
function Import-DotEnv {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = ".env",

        [Parameter()]
        [switch]$Clobber,

        [Parameter()]
        [switch]$PassThru
    )

    # Resolve the path to an absolute path
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    # Check if file exists
    if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
        Write-Error "The file '$resolvedPath' does not exist."
        return
    }

    # Initialize hashtable for PassThru output
    $loadedVars = @{}

    # Regular expression to parse key-value pairs
    # - ^\s*#: Matches full-line comments (optional leading whitespace, then #)
    # - ^\s*$: Matches blank lines (optional whitespace only)
    # - ^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$: Matches KEY=VALUE pattern
    #   - Group 1: Key (starts with letter or underscore, followed by alphanumeric/underscore)
    #   - Group 2: Value (everything after the =)

    # Regex pattern for key: starts with letter or underscore, followed by word characters
    $keyPattern = '^[A-Za-z_][A-Za-z0-9_]*$'

    # Read file line by line
    $lines = Get-Content -Path $resolvedPath -Encoding UTF8

    foreach ($line in $lines) {
        # Trim the line for processing
        $trimmedLine = $line.Trim()

        # Skip blank lines (lines that are empty or whitespace only)
        if ($trimmedLine -eq '') {
            continue
        }

        # Skip full-line comments (lines starting with # after trimming)
        if ($trimmedLine -match '^#') {
            continue
        }

        # Parse the key-value pair
        # First, extract everything before the first = as the key
        # Everything after the first = is the value (may contain more = signs)
        $equalsIndex = $line.IndexOf('=')
        
        if ($equalsIndex -gt 0) {
            $key = $line.Substring(0, $equalsIndex).Trim()
            $value = $line.Substring($equalsIndex + 1)

            # Validate key matches pattern (alphanumeric and underscore only, must start with letter or underscore)
            if ($key -match $keyPattern) {
                # Strip inline comments from value
                # Find the first non-quoted # and remove everything from it onwards
                $value = Remove-InlineComment -Value $value

                # Strip surrounding quotes (single or double)
                $value = Strip-SurroundingQuotes -Value $value

                # Check if we should set this variable
                $shouldSet = $true
                if (-not $Clobber) {
                    # Check if environment variable already exists
                    $shouldSet = -not (Test-Path "env:$key")
                }

                if ($shouldSet) {
                    # Set the environment variable
                    Set-Item -Path "env:$key" -Value $value -ErrorAction Stop
                    
                    # Add to loaded vars hashtable
                    $loadedVars[$key] = $value
                    
                    Write-Verbose "Set environment variable: $key = $value"
                }
                else {
                    Write-Verbose "Skipped (already exists): $key"
                }
            }
            else {
                Write-Warning "Invalid key format: '$key'. Keys must start with a letter or underscore and contain only alphanumeric characters and underscores."
            }
        }
    }

    if ($PassThru) {
        return $loadedVars
    }
}

<#
.SYNOPSIS
    Removes environment variables defined in a .env file from the current session.

.DESCRIPTION
    Clear-DotEnv reads a .env file, extracts the keys, and removes them from 
    the current PowerShell session. This is useful for testing/unloading env vars.

.PARAMETER Path
    The path to the .env file. Defaults to ".env" in the current working directory.

.EXAMPLE
    Clear-DotEnv
    # Removes all variables defined in .env from current session

.EXAMPLE
    Clear-DotEnv -Path "C:\myapp\.env"
    # Removes variables from specific .env file
#>
function Clear-DotEnv {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = ".env"
    )

    # Resolve the path to an absolute path
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    # Check if file exists
    if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
        Write-Error "The file '$resolvedPath' does not exist."
        return
    }

    # Regular expression pattern for valid key
    $keyPattern = '^[A-Za-z_][A-Za-z0-9_]*$'

    # Read file line by line
    $lines = Get-Content -Path $resolvedPath -Encoding UTF8

    $removedCount = 0

    foreach ($line in $lines) {
        # Trim the line for processing
        $trimmedLine = $line.Trim()

        # Skip blank lines
        if ($trimmedLine -eq '') {
            continue
        }

        # Skip full-line comments
        if ($trimmedLine -match '^#') {
            continue
        }

        # Extract key (everything before the first =)
        $equalsIndex = $line.IndexOf('=')
        
        if ($equalsIndex -gt 0) {
            $key = $line.Substring(0, $equalsIndex).Trim()

            # Validate key format
            if ($key -match $keyPattern) {
                # Check if environment variable exists and remove it
                if (Test-Path "env:$key") {
                    Remove-Item -Path "env:$key" -ErrorAction Stop
                    Write-Verbose "Removed environment variable: $key"
                    $removedCount++
                }
            }
        }
    }

    Write-Verbose "Removed $removedCount environment variable(s)."
}

<#
.SYNOPSIS
    Removes inline comments from a .env value.

.DESCRIPTION
    Parses a value string and removes any inline comments (text after # that is not inside quotes).

.PARAMETER Value
    The value string to process.

.EXAMPLE
    Remove-InlineComment -Value "12345 # This is the key"
    # Returns: "12345"
#>
function Remove-InlineComment {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Value
    )

    # If null, return empty string
    if ($null -eq $Value) {
        return ''
    }

    # Get raw value (don't trim yet, we need to check quotes first)
    $value = $Value

    # If empty after trimming, return empty
    if ($value.Trim() -eq '') {
        return ''
    }

    # Check if the value is quoted (single or double)
    $isSingleQuoted = $value.Trim().StartsWith("'") -and $value.Trim().Length -gt 1
    $isDoubleQuoted = $value.Trim().StartsWith('"') -and $value.Trim().Length -gt 1

    if ($isSingleQuoted -or $isDoubleQuoted) {
        # Get trimmed for processing
        $trimmedValue = $value.Trim()
        $quoteChar = if ($isSingleQuoted) { "'" } else { '"' }
        
        # Find the closing quote (not escaped)
        $closingIndex = -1
        for ($i = 1; $i -lt $trimmedValue.Length; $i++) {
            if ($trimmedValue[$i] -eq $quoteChar) {
                # Check if it's escaped
                $backslashes = 0
                for ($j = $i - 1; $j -ge 0 -and $trimmedValue[$j] -eq '\'; $j--) {
                    $backslashes++
                }
                
                # If even number of backslashes (or zero), quote is not escaped
                if ($backslashes % 2 -eq 0) {
                    $closingIndex = $i
                    break
                }
            }
        }

        if ($closingIndex -gt 0) {
            # Return everything inside quotes (without the quotes)
            return $trimmedValue.Substring(1, $closingIndex - 1)
        }
        else {
            # No closing quote found - return trimmed value without the opening quote
            return $trimmedValue.Substring(1).TrimEnd()
        }
    }

    # Not quoted - use trimmed value
    $value = $value.Trim()

    # Find first unquoted # and remove everything after it
    for ($i = 0; $i -lt $value.Length; $i++) {
        if ($value[$i] -eq '#') {
            # Check if # is preceded by whitespace (indicating it's a comment)
            if ($i -gt 0 -and $value[$i - 1] -match '\s') {
                return $value.Substring(0, $i).Trim()
            }
        }
    }

    return $value
}

<#
.SYNOPSIS
    Strips surrounding quotes from a .env value.

.DESCRIPTION
    Removes surrounding single or double quotes from a value string,
    handling escaped quotes within the value.

.PARAMETER Value
    The value string to process.

.EXAMPLE
    Strip-SurroundingQuotes -Value '"Hello World"'
    # Returns: Hello World

.EXAMPLE
    Strip-SurroundingQuotes -Value "'Hello World'"
    # Returns: Hello World
#>
function Strip-SurroundingQuotes {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    # Handle empty or null value
    if ([string]::IsNullOrEmpty($value)) {
        return $value
    }

    $value = $Value

    # Check for single-quoted string: 'value'
    if ($value.StartsWith("'") -and $value.Length -gt 1) {
        # Find closing single quote
        $closingQuote = $value.IndexOf("'", 1)
        
        if ($closingQuote -eq ($value.Length - 1)) {
            # Return value without quotes (preserve internal spaces)
            return $value.Substring(1, $value.Length - 2)
        }
        elseif ($closingQuote -gt 0) {
            # There's a quote in the middle, assume it's the closing quote
            return $value.Substring(1, $closingQuote - 1)
        }
        else {
            # No closing quote - return as is
            return $value
        }
    }

    # Check for double-quoted string: "value"
    if ($value.StartsWith('"') -and $value.Length -gt 1) {
        # Find closing double quote
        $closingQuote = $value.IndexOf('"', 1)
        
        if ($closingQuote -eq ($value.Length - 1)) {
            # Return value without quotes (preserve internal spaces)
            return $value.Substring(1, $value.Length - 2)
        }
        elseif ($closingQuote -gt 0) {
            # There's a quote in the middle, check if it's the closing quote
            return $value.Substring(1, $closingQuote - 1)
        }
        else {
            # No closing quote - return as is
            return $value.Trim()
        }
    }

    # No surrounding quotes - trim unquoted values
    return $value.Trim()
}

# Export module members (helper functions are exported for testing purposes)
Export-ModuleMember -Function Import-DotEnv, Clear-DotEnv, Remove-InlineComment, Strip-SurroundingQuotes
