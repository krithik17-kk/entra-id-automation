# ============================================================
# AD Automation System - Microsoft Entra ID via Graph API
# Author: Krithik Kotian
# ============================================================

# --- Load Config ---
$TenantId     = "7bfc0556-5173-4dda-90e3-51327e7a0922"
$ClientId     = "bb37988f-1883-46e3-b96a-5716cdee2d37"
$Domain       = "kotiankrithik3gmail.onmicrosoft.com"
$ClientSecret = $env:AZURE_CLIENT_SECRET

# --- Authenticate ---
function Connect-GraphAPI {
    $body = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }
    $token = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method POST -Body $body
    return $token.access_token
}

# --- Create User ---
function New-EntraUser {
    param($Token, $FirstName, $LastName, $Department, $JobTitle)
    $username  = "$($FirstName.ToLower()).$($LastName.ToLower())"
    $upn       = "$username@$Domain"
    $password  = "Welcome@$(Get-Random -Minimum 1000 -Maximum 9999)!"
    $body = @{
        accountEnabled    = $true
        displayName       = "$FirstName $LastName"
        givenName         = $FirstName
        surname           = $LastName
        userPrincipalName = $upn
        mailNickname      = $username
        department        = $Department
        jobTitle          = $JobTitle
        passwordProfile   = @{
            forceChangePasswordNextSignIn = $true
            password = $password
        }
    } | ConvertTo-Json
    try {
        $result = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Method POST -Headers @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" } -Body $body
        Write-Host "OK Created: $($result.displayName) | UPN: $upn | Temp Password: $password" -ForegroundColor Green
        Add-Content "C:\Projects\AD-Automation\logs\log.txt" "$(Get-Date) | CREATED | $upn"
    } catch {
        Write-Host "FAIL Could not create $upn : $_" -ForegroundColor Red
        Add-Content "C:\Projects\AD-Automation\logs\log.txt" "$(Get-Date) | FAILED | $upn | $_"
    }
}

# --- Disable User ---
function Disable-EntraUser {
    param($Token, $UPN)
    $body = @{ accountEnabled = $false } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$UPN" -Method PATCH -Headers @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" } -Body $body
        Write-Host "DISABLED: $UPN" -ForegroundColor Yellow
        Add-Content "C:\Projects\AD-Automation\logs\log.txt" "$(Get-Date) | DISABLED | $UPN"
    } catch {
        Write-Host "FAIL Could not disable $UPN : $_" -ForegroundColor Red
    }
}

# --- Generate Report ---
function Get-UserReport {
    param($Token)
    $users = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users?`$select=displayName,userPrincipalName,department,jobTitle,accountEnabled" -Headers @{ Authorization = "Bearer $Token" }
    $date = Get-Date -Format 'yyyyMMdd_HHmm'
    $reportPath = "C:\Projects\AD-Automation\reports\UserReport_$date.csv"
    $users.value | Select-Object displayName, userPrincipalName, department, jobTitle, accountEnabled | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "Report saved: $reportPath" -ForegroundColor Cyan
    Write-Host "Total : $($users.value.Count)"
    Write-Host "Active  : $(($users.value | Where-Object accountEnabled -eq $true).Count)"
    Write-Host "Disabled: $(($users.value | Where-Object accountEnabled -eq $false).Count)"
}

# --- Bulk Onboard ---
function Start-BulkOnboarding {
    param($Token)
    $csv = Import-Csv "C:\Projects\AD-Automation\users.csv"
    Write-Host "Starting bulk onboarding for $($csv.Count) users..." -ForegroundColor Cyan
    foreach ($user in $csv) {
        New-EntraUser -Token $Token -FirstName $user.FirstName -LastName $user.LastName -Department $user.Department -JobTitle $user.JobTitle
        Start-Sleep -Milliseconds 500
    }
}

# ============================================================
# MAIN
# ============================================================
$token = Connect-GraphAPI
Write-Host "Connected to Microsoft Entra ID" -ForegroundColor Green

do {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "   AD Automation System - Krithik Kotian"
    Write-Host "========================================"
    Write-Host "1. Bulk Onboard Users from CSV"
    Write-Host "2. Disable a User (Offboarding)"
    Write-Host "3. Generate User Report"
    Write-Host "4. Exit"
    Write-Host "----------------------------------------"
    $choice = Read-Host "Select option"
    switch ($choice) {
        "1" { Start-BulkOnboarding -Token $token }
        "2" {
            $upn = Read-Host "Enter UPN to disable"
            Disable-EntraUser -Token $token -UPN $upn
        }
        "3" { Get-UserReport -Token $token }
        "4" { Write-Host "Exiting..." }
        default { Write-Host "Invalid option" -ForegroundColor Red }
    }
} while ($choice -ne "4")
