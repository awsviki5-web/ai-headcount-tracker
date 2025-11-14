# PowerShell Script to Setup Python Environment and Run Streamlit App
# Handles existing repositories and installations gracefully

# Configuration
$VENV_NAME = "ai_venv"
$REPO_URL = "https://github.com/awsviki5-web/ai-headcount-tracker.git"
$REPO_NAME = "ai-headcount-tracker"
$ALIAS_NAME = "ai"
$WORKING_DIR = Join-Path $env:USERPROFILE "AIProjects"

# Color output functions
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) {
    Write-ColorOutput Green "✓ $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "ℹ $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "✗ $message"
}

# Error handling
$ErrorActionPreference = "Continue"

Write-Info "Starting Python environment setup..."
Write-Host ""

# Create and move to working directory
Write-Info "Setting up working directory: $WORKING_DIR"
if (!(Test-Path $WORKING_DIR)) {
    New-Item -ItemType Directory -Path $WORKING_DIR | Out-Null
    Write-Success "Created working directory"
} else {
    Write-Success "Working directory exists"
}

Set-Location $WORKING_DIR
Write-Success "Changed to working directory: $WORKING_DIR"
Write-Host ""

# 1. Check Python
Write-Info "Step 1: Checking Python installation..."

$pythonInstalled = $false
try {
    $pythonVersion = python --version 2>&1
    if ($pythonVersion -match "Python") {
        Write-Success "Python is installed: $pythonVersion"
        $pythonInstalled = $true
    }
} catch {
    Write-Info "Python not found"
}

if (-not $pythonInstalled) {
    Write-Info "Installing Python via winget..."
    try {
        $wingetCheck = winget --version 2>&1
        if ($wingetCheck) {
            winget install Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Start-Sleep -Seconds 3
            $pythonVersion = python --version 2>&1
            Write-Success "Python installed: $pythonVersion"
        }
    } catch {
        Write-Error "Could not install Python automatically"
        Write-Info "Please install Python from https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        pause
        exit 1
    }
}

# Verify pip
Write-Info "Verifying pip..."
try {
    python -m pip --version | Out-Null
    python -m pip install --upgrade pip --quiet
    Write-Success "pip is ready"
} catch {
    python -m ensurepip --upgrade
}
Write-Host ""

# 2. Create virtual environment
Write-Info "Step 2: Setting up virtual environment..."

$venvPath = Join-Path $WORKING_DIR $VENV_NAME

if (Test-Path $venvPath) {
    Write-Info "Virtual environment already exists, using existing one"
} else {
    Write-Info "Creating virtual environment '$VENV_NAME'..."
    python -m venv $VENV_NAME
    Write-Success "Virtual environment created"
}
Write-Host ""

# 3. Setup alias
Write-Info "Step 3: Setting up PowerShell alias '$ALIAS_NAME'..."

$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
$profilePath = $PROFILE.CurrentUserAllHosts

if (!(Test-Path $profilePath)) {
    $profileDir = Split-Path $profilePath -Parent
    if (!(Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
    New-Item -Path $profilePath -Type File -Force | Out-Null
    Write-Info "Created PowerShell profile"
}

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
$aliasCommand = "function $ALIAS_NAME { & '$activateScript' }"

if ($profileContent -notmatch [regex]::Escape("function $ALIAS_NAME")) {
    Add-Content $profilePath "`n# Alias for AI virtual environment"
    Add-Content $profilePath $aliasCommand
    Write-Success "Alias '$ALIAS_NAME' added to PowerShell profile"
} else {
    Write-Success "Alias '$ALIAS_NAME' already exists"
}
Write-Host ""

# 4. Activate virtual environment
Write-Info "Step 4: Activating virtual environment..."

$executionPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($executionPolicy -eq "Restricted") {
    Write-Info "Setting execution policy..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}

try {
    & $activateScript
    Write-Success "Virtual environment activated"
} catch {
    Write-Error "Could not activate virtual environment"
    Write-Info "Trying alternative activation method..."
    $env:VIRTUAL_ENV = $venvPath
    $env:PATH = "$venvPath\Scripts;$env:PATH"
}
Write-Host ""

# 5. Handle Git repository
Write-Info "Step 5: Setting up Git repository..."

$repoPath = Join-Path $WORKING_DIR $REPO_NAME

# Check if git is available
try {
    $gitVersion = git --version 2>&1
    Write-Success "Git is available: $gitVersion"
} catch {
    Write-Error "Git is not installed"
    Write-Info "Please install Git from https://git-scm.com/downloads"
    Write-Info "After installing Git, run this script again"
    pause
    exit 1
}

# Handle existing repository
if (Test-Path $repoPath) {
    Write-Info "Repository already exists at: $repoPath"
    Write-Info "Checking for updates..."
    
    Push-Location $repoPath
    try {
        $gitStatus = git status 2>&1
        if ($gitStatus -match "fatal") {
            Write-Info "Repository is corrupted, removing and re-cloning..."
            Pop-Location
            Remove-Item -Recurse -Force $repoPath
            git clone $REPO_URL 2>&1 | Out-Null
            Write-Success "Repository cloned fresh"
        } else {
            git pull 2>&1 | Out-Null
            Write-Success "Repository updated"
        }
    } catch {
        Write-Info "Using existing repository as-is"
    }
    Pop-Location
} else {
    Write-Info "Cloning repository..."
    $cloneOutput = git clone $REPO_URL 2>&1
    if (Test-Path $repoPath) {
        Write-Success "Repository cloned successfully"
    } else {
        Write-Error "Failed to clone repository"
        Write-Info "Clone output: $cloneOutput"
        pause
        exit 1
    }
}

Set-Location $repoPath
Write-Success "Navigated to repository: $repoPath"
Write-Host ""

# 6. Install dependencies
Write-Info "Step 6: Installing dependencies..."

if (!(Test-Path "requirements.txt")) {
    Write-Error "requirements.txt not found in repository!"
    Write-Info "Current directory: $(Get-Location)"
    Get-ChildItem | Select-Object Name
    pause
    exit 1
}

Write-Info "Installing packages from requirements.txt..."
python -m pip install -r requirements.txt
Write-Success "Dependencies installed"
Write-Host ""

# 7. Start Streamlit
Write-Info "Step 7: Finding and starting Streamlit application..."
Write-Host ""

# Find Python files
$pythonFiles = Get-ChildItem -Filter "*.py" | Select-Object -ExpandProperty Name

if ($pythonFiles.Count -eq 0) {
    Write-Error "No Python files found in repository"
    pause
    exit 1
}

Write-Info "Available Python files:"
$pythonFiles | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

# Try common Streamlit file names
$streamlitFile = $null
$commonNames = @("app.py", "main.py", "streamlit_app.py", "Home.py", "home.py", "App.py", "Main.py")

foreach ($name in $commonNames) {
    if ($pythonFiles -contains $name) {
        $streamlitFile = $name
        break
    }
}

# If not found by name, check file contents
if (-not $streamlitFile) {
    Write-Info "Checking file contents for Streamlit import..."
    foreach ($file in $pythonFiles) {
        $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
        if ($content -match "import streamlit|from streamlit") {
            $streamlitFile = $file
            break
        }
    }
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host "Working Directory: $repoPath" -ForegroundColor Cyan
Write-Host "Virtual Environment: $venvPath" -ForegroundColor Cyan
Write-Host "Alias Command: $ALIAS_NAME (use in new PowerShell sessions)" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Yellow
Write-Host ""

if ($streamlitFile) {
    Write-Success "Found Streamlit app: $streamlitFile"
    Write-Info "Starting Streamlit..."
    Write-Info "Press Ctrl+C to stop the application"
    Write-Host ""
    
    python -m streamlit run $streamlitFile
} else {
    Write-Info "Could not automatically determine the main Streamlit file"
    Write-Host ""
    Write-Info "To start the app manually, run:"
    Write-Host "  streamlit run <filename>.py" -ForegroundColor Yellow
    Write-Host ""
    Write-Info "For example:"
    $pythonFiles | ForEach-Object { 
        Write-Host "  streamlit run $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Info "Setup script completed"