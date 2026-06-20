@'
# Entra ID User Lifecycle Automation

Automates Active Directory user management in Microsoft Entra ID (Azure AD) using PowerShell and Microsoft Graph API.

## What it does
- Bulk onboards users from a CSV file with auto-generated temporary passwords
- Disables departed users instantly (offboarding)
- Generates audit reports of all users with account status, department, and role

## Tech Stack
- PowerShell
- Microsoft Graph API
- Microsoft Entra ID (Azure AD)
- Azure App Registration (OAuth2 client credentials)

## Setup

### Prerequisites
- Azure account with Microsoft Entra ID
- App Registration with the following API permissions:
  - `User.ReadWrite.All` (Application)
  - `Directory.ReadWrite.All` (Application)

### Configuration
1. Clone the repo
2. Copy `config.example.txt` to `config.txt`
3. Fill in your `TenantId`, `ClientId`, `ClientSecret`, and `Domain`
4. Set your client secret as an environment variable:
```powershell
$env:AZURE_CLIENT_SECRET = "your-secret-here"
```

### Run
```powershell
powershell -ExecutionPolicy Bypass -File ".\AD-Automation.ps1"
```

## Features

### 1. Bulk Onboarding
Reads from `users.csv` and creates all users in Entra ID with temporary passwords.

### 2. Offboarding
Disables a user account by UPN instantly via Graph API.

### 3. User Audit Report
Exports a CSV report of all users including:
- Display name
- UPN
- Department
- Job title
- Account status (enabled/disabled)

## Project Structure

## Author
Krithik Kotian
[LinkedIn](https://linkedin.com/in/krithikkotian) | [GitHub](https://github.com/krithik17-kk)
'@ | Out-File -FilePath "C:\Projects\AD-Automation\README.md" -Encoding UTF8
