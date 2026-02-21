# PSDotEnv

![PSDotenv Banner](psdotenv-logo.jpg)

[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/baldator/PSDotenv/main.svg)](https://github.com/baldator/PSDotenv/commits/main)
[![Build Status](https://github.com/baldator/PSDotenv/actions/workflows/ci.yml/badge.svg)](https://github.com/baldator/PSDotenv/actions)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/PSDotenv.svg)](https://www.powershellgallery.com/packages/PSDotenv)


A lightweight, robust PowerShell module that mimics the functionality of Python's [python-dotenv](https://pypi.org/project/python-dotenv/) package. Safely parses `.env` files and injects the key-value pairs into the current PowerShell process environment (`$env:KEY = "value"`).

## Features

- **Import-DotEnv**: Load environment variables from a `.env` file into the current PowerShell session
- **Clear-DotEnv**: Remove environment variables defined in a `.env` file from the current session
- Supports single and double-quoted values
- Handles inline comments (e.g., `KEY=value # comment`)
- Ignores full-line comments
- Handles values containing equals signs
- Configurable overwrite behavior (Clobber parameter)
- PassThru support for programmatic use
- Cross-platform compatible (Windows, Linux, macOS)

## Installation

### From PowerShell Gallery

```powershell
Install-Module -Name PSDotEnv -Scope CurrentUser
```

### Manual Installation

1. Clone this repository or download the latest release
2. Copy `PSDotEnv.psm1` (and optionally `PSDotEnv.psd1`) to your PowerShell modules folder:
   - Windows: `C:\Users\<YourUser>\Documents\PowerShell\Modules\PSDotEnv\`
   - Linux/macOS: `~/.local/share/powershell/Modules/PSDotEnv/`

## Usage

### Basic Usage

Create a `.env` file in your project:

```env
# Database Configuration
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb

# API Keys
API_KEY=abc123 # Don't share this!
SECRET_KEY='super-secret-key'

# Application Settings
DEBUG=true
PORT=8080
```

Import the environment variables:

```powershell
Import-DotEnv
# or specify a custom path
Import-DotEnv -Path "C:\myapp\.env"
```

The variables are now available in `$env:`:

```powershell
$env:DATABASE_URL
# postgresql://user:pass@localhost:5432/mydb

$env:API_KEY
# abc123
```

### Using Clobber Parameter

By default, existing environment variables are not overwritten:

```powershell
$env:EXISTING_VAR = "original"
Import-DotEnv -Path ".env"  # Contains EXISTING_VAR=new_value
$env:EXISTING_VAR  # Returns "original"
```

Use `-Clobber` to overwrite existing variables:

```powershell
Import-DotEnv -Path ".env" -Clobber
$env:EXISTING_VAR  # Returns "new_value"
```

### Using PassThru Parameter

Get a hashtable of loaded variables:

```powershell
$vars = Import-DotEnv -Path ".env" -PassThru
$vars["API_KEY"]
# abc123
```

### Clearing Environment Variables

Remove variables loaded from a `.env` file:

```powershell
Clear-DotEnv
# or specify a custom path
Clear-DotEnv -Path "C:\myapp\.env"
```

## Supported .env File Formats

### Basic Key-Value Pairs

```env
KEY=value
ANOTHER_KEY=another_value
```

### Quoted Values

```env
MESSAGE="Hello World"
SINGLE_QUOTED='Hello World'
```

### Inline Comments

```env
KEY=value # This is a comment
```

The comment is stripped, and `KEY` is set to `value`.

### Values with Equals Signs

```env
CONNECTION_STRING=Server=myServer;Database=myDB;User=myUser;Password=myPass;
```

Only the first `=` is used as the delimiter; the rest becomes part of the value.

### Preserving Hash Inside Quotes

```env
HASH_VALUE="value#with#hash"  # Preserves # inside quotes
HASH_VALUE='value#with#hash'  # Same for single quotes
```

### Blank Lines and Comments

```env
# This is a full-line comment

KEY=value

# Another comment
ANOTHER_KEY=value
```

## Cmdlets

### Import-DotEnv

Imports environment variables from a `.env` file into the current PowerShell session.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| Path | string | `.env` | Path to the .env file |
| Clobber | switch | false | Overwrite existing environment variables |
| PassThru | switch | false | Return a hashtable of loaded keys and values |

**Examples:**

```powershell
# Load from default .env file
Import-DotEnv

# Load from custom path
Import-DotEnv -Path "C:\myapp\.env"

# Overwrite existing variables
Import-DotEnv -Path ".env" -Clobber

# Get loaded variables as hashtable
$vars = Import-DotEnv -PassThru
```

### Clear-DotEnv

Removes environment variables defined in a `.env` file from the current session.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| Path | string | `.env` | Path to the .env file |

**Examples:**

```powershell
# Clear variables from default .env
Clear-DotEnv

# Clear variables from custom path
Clear-DotEnv -Path "C:\myapp\.env"
```

## Development

### Running Tests

The project uses [Pester](https://pester.dev/) for testing.

```powershell
# Install Pester if needed
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck

# Run tests
Invoke-Pester -Path "./PSDotEnv.tests.ps1"

# Run tests with code coverage
Invoke-Pester -Path "./PSDotEnv.tests.ps1" -Output Detailed
```

### Project Structure

```
PSDotEnv/
├── PSDotEnv.psm1       # Main module file
├── PSDotEnv.psd1       # Module manifest
├── PSDotEnv.tests.ps1 # Pester tests
├── README.md          # This file
└── .github/
    └── workflows/
        └── ci.yml     # GitHub Actions CI/CD pipeline
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
