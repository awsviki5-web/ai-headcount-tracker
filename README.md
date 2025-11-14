# AI Headcount Tracker - Automated Setup Script

This PowerShell script automates the complete setup process for the AI Headcount Tracker application, including Python installation, virtual environment creation, Git repository cloning, and dependency installation.

## 🚀 Quick Start

### Prerequisites
- **Windows 10/11** with PowerShell 5.1 or later
- **Internet connection** (for downloading dependencies)
- **Administrator privileges** (may be required for initial setup)

### One-Command Setup

1. **Download the script** (`setup.ps1`)
2. **Open PowerShell** (right-click Start menu → Windows PowerShell)
3. **Navigate to the script location**:
   ```powershell
   cd C:\path\to\script
   ```
4. **Run the script**:
   ```powershell
   .\setup.ps1
   ```

That's it! The script handles everything automatically.

---

## 📋 What the Script Does

The script performs these steps automatically:

1. ✅ **Checks Python installation** (installs if missing via winget)
2. ✅ **Creates working directory** (`%USERPROFILE%\AIProjects`)
3. ✅ **Sets up virtual environment** (named `ai_venv`)
4. ✅ **Creates PowerShell alias** (`ai` command for easy activation)
5. ✅ **Clones Git repository** (or updates if already exists)
6. ✅ **Installs dependencies** from requirements.txt
7. ✅ **Launches Streamlit app** automatically

---

## 🔧 Detailed Instructions

### First-Time Setup

#### Step 1: Enable Script Execution
If you get an execution policy error, run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Step 2: Run the Setup Script
```powershell
.\setup.ps1
```

The script will:
- Install Python 3.12 if not present
- Create a virtual environment at `%USERPROFILE%\AIProjects\ai_venv`
- Clone the repository to `%USERPROFILE%\AIProjects\ai-headcount-tracker`
- Install all required packages
- Start the Streamlit application

#### Step 3: Access the Application
Once the script completes, your browser should automatically open to:
```
http://localhost:8501
```

---

## 🎯 Using the Virtual Environment

### Activating the Environment

After the initial setup, you can activate the virtual environment using the alias:

**Open a new PowerShell window and type:**
```powershell
ai
```

This activates the virtual environment. You'll see `(ai_venv)` in your prompt.

### Manual Activation (Alternative)
If the alias doesn't work, activate manually:
```powershell
cd %USERPROFILE%\AIProjects
.\ai_venv\Scripts\Activate.ps1
```

### Running the Application Manually
After activating the environment:
```powershell
cd %USERPROFILE%\AIProjects\ai-headcount-tracker
streamlit run app.py
```
*(Replace `app.py` with the actual main file name if different)*

---

## 📁 Directory Structure

After setup, your directory structure will look like:
```
%USERPROFILE%\AIProjects\
├── ai_venv\                    # Virtual environment
│   ├── Scripts\
│   ├── Lib\
│   └── ...
└── ai-headcount-tracker\       # Cloned repository
    ├── app.py                  # Main application file
    ├── requirements.txt        # Python dependencies
    └── ...
```

---

## 🔄 Re-running the Script

The script is **idempotent**, meaning you can run it multiple times safely:

- ✅ Won't reinstall Python if already present
- ✅ Won't recreate virtual environment if exists
- ✅ Won't duplicate alias in PowerShell profile
- ✅ Will update the Git repository (git pull)
- ✅ Will reinstall/update dependencies

**To update your installation:**
```powershell
.\setup.ps1
```

---

## ⚠️ Troubleshooting

### Python Not Found Error
**Problem:** Script can't find Python after installation

**Solution:**
1. Close and reopen PowerShell
2. Or manually refresh PATH:
   ```powershell
   $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
   ```

### Git Not Installed
**Problem:** "Git is not installed" error

**Solution:**
1. Download Git from https://git-scm.com/downloads
2. Install with default options
3. Restart PowerShell
4. Run the script again

### Execution Policy Error
**Problem:** "cannot be loaded because running scripts is disabled"

**Solution:**
Run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Port Already in Use
**Problem:** Streamlit can't start because port 8501 is in use

**Solution:**
Stop the existing Streamlit process or run on a different port:
```powershell
streamlit run app.py --server.port 8502
```

### Virtual Environment Won't Activate
**Problem:** Alias `ai` doesn't work

**Solution:**
1. Reload your PowerShell profile:
   ```powershell
   . $PROFILE
   ```
2. Or activate manually:
   ```powershell
   & "$env:USERPROFILE\AIProjects\ai_venv\Scripts\Activate.ps1"
   ```

### Repository Clone Fails
**Problem:** Git clone fails or repository is corrupted

**Solution:**
The script will automatically detect and fix this. If it persists:
1. Manually delete the repository folder:
   ```powershell
   Remove-Item -Recurse -Force "$env:USERPROFILE\AIProjects\ai-headcount-tracker"
   ```
2. Run the script again

---

## 🛠️ Manual Cleanup

To completely remove the installation:

```powershell
# Remove working directory
Remove-Item -Recurse -Force "$env:USERPROFILE\AIProjects"

# Remove alias from PowerShell profile
notepad $PROFILE
# Delete the lines containing 'function ai'
```

---

## 📝 Configuration

You can modify these variables at the top of the script:

```powershell
$VENV_NAME = "ai_venv"              # Virtual environment name
$REPO_URL = "https://github.com/awsviki5-web/ai-headcount-tracker.git"
$REPO_NAME = "ai-headcount-tracker" # Repository folder name
$ALIAS_NAME = "ai"                  # PowerShell alias command
$WORKING_DIR = Join-Path $env:USERPROFILE "AIProjects"  # Base directory
```

---

## 🤝 Support

### Common Commands Reference

| Task | Command |
|------|---------|
| Activate environment | `ai` |
| Deactivate environment | `deactivate` |
| Run Streamlit app | `streamlit run app.py` |
| Update repository | `cd %USERPROFILE%\AIProjects\ai-headcount-tracker` then `git pull` |
| Install new package | `pip install package-name` |
| List installed packages | `pip list` |

### Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Review the PowerShell output for error messages
3. Ensure you have a stable internet connection
4. Try running PowerShell as Administrator

---

## 📄 License

This setup script is provided as-is for the AI Headcount Tracker project.

---

## ✨ Features

- 🔄 **Automatic dependency management**
- 🎨 **Color-coded output** for easy reading
- 🛡️ **Error handling** with helpful messages
- 🔁 **Idempotent execution** (safe to run multiple times)
- 🚀 **One-command deployment**
- 🔗 **Persistent alias** for easy environment activation

---

**Happy Tracking! 🎉**