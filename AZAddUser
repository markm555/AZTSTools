# Sample CSV file with users to be added to Entra ID

# displayName,mailNickname,userPrincipalName,password
# john.doe,john.doe,john.doe@MngEnvMCAP331330.onmicrosoft.com,YourPassword
# jane.smith,jane.smith,jane.smith@MngEnvMCAP331330.onmicrosoft.com,YourPassword

Modified PowerShell Script
# Variables
$tenantId = "your-tenant-id"
$clientId = "your-client-id"
$clientSecret = "your-client-secret"
$csvFilePath = "path-to-your-csv-file.csv"

# Authenticate using the service principal
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
}

$response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token

# Read users from CSV file
$users = Import-Csv -Path $csvFilePath

# Loop through each user and create them in Entra ID
foreach ($user in $users) {
    $userBody = @{
        accountEnabled = $true
        displayName = $user.displayName
        mailNickname = $user.mailNickname
        userPrincipalName = $user.userPrincipalName
        passwordProfile = @{
            forceChangePasswordNextSignIn = $true
            password = $user.password
        }
    }

    $headers = @{
        Authorization = "Bearer $token"
        "Content-Type"  = "application/json"
    }

    $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Method Post -Headers $headers -Body ($userBody | ConvertTo-Json)

    if ($response) {
        Write-Output "User $($user.userPrincipalName) created successfully."
    } else {
        Write-Output "Failed to create user $($user.userPrincipalName)."
    }
}
