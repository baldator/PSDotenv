# PSDotEnv.psd1
# Module manifest for PSDotEnv module

@{
    RootModule = 'PSDotEnv.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'Baldator'
    Copyright = 'MIT License'
    Description = 'A PowerShell module that mimics python-dotenv functionality. Safely parses .env files and injects key-value pairs into the current PowerShell process environment.'
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @('Import-DotEnv', 'Clear-DotEnv')
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Required modules
    RequiredModules = @()

    # Module capabilities
    PrivateData = @{
        PSData = @{
            Tags = @('dotenv', 'environment', 'env', 'configuration', 'python-dotenv')
            ProjectUri = 'https://github.com/baldator/PSDotEnv'
            ReleaseNotes = @'
## 1.0.0
- Initial release
- Import-DotEnv cmdlet to load .env files
- Clear-DotEnv cmdlet to remove loaded variables
- Support for quoted values, inline comments, and values with equals signs
'@
        }
    }
}
