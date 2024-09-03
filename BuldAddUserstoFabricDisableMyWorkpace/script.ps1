# Sample CSV file with users to be added to Entra ID

#displayName,mailNickname,userPrincipalName,password,phoneNumber
#John Doe,johndoe,johndoe@example.com,Password123!,+1234567890
#Jane Smith,janesmith,janesmith@example.com,Password123!,+0987654321


#Modified PowerShell Script
# Variables
$tenantId = "<YourTenantID>"
$clientId = "<YourClientID"
$clientSecret = "<YourClientSecret>"
$csvFilePath = "<YourFullCSVFilePath.csv"
$fabricCapacityId = "YourCapacityID" 

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

    try {
        $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users" -Method Post -Headers $headers -Body ($userBody | ConvertTo-Json)
        Write-Output "User $($user.userPrincipalName) created successfully."
    } catch {
        Write-Output "Failed to create user $($user.userPrincipalName). Error: $_.Exception.Response.StatusDescription"
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Output $responseBody
        continue
    }
<#
    # Enable MFA for the user in a PATCH request
    $mfaBody = @{
        authentication = @{
            methods = @(
                @{
                    type = "phone"
                    phoneNumber = $user.phoneNumber
                    phoneType = "mobile"
                }
            )
        }
    }

    try {
        $mfaResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$($user.userPrincipalName)" -Method Patch -Headers $headers -Body ($mfaBody | ConvertTo-Json)
        Write-Output "MFA enabled for user $($user.userPrincipalName)."
    } catch {
        Write-Output "Failed to enable MFA for user $($user.userPrincipalName). Error: $_.Exception.Response.StatusDescription"
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Output $responseBody
    }
#>
    # Assign Power BI MyWorkspace to Fabric Capacity
    try {
        $workspaceId = (Invoke-RestMethod -Uri "https://api.powerbi.com/v1.0/myorg/groups" -Method Get -Headers $headers).value | Where-Object { $_.name -eq "$($user.displayName) MyWorkspace" } | Select-Object -ExpandProperty id

        $capacityBody = @{
            capacityMigrationAssignments = @(
                @{
                    sourceWorkspaceId = $workspaceId
                    targetCapacityId = $fabricCapacityId
                }
            )
        }

        $capacityResponse = Invoke-RestMethod -Uri "https://api.powerbi.com/v1.0/myorg/admin/capacities/assignWorkspaces" -Method Post -Headers $headers -Body ($capacityBody | ConvertTo-Json)
        Write-Output "Workspace for user $($user.userPrincipalName) assigned to Fabric Capacity."
    } catch {
        Write-Output "Failed to assign workspace for user $($user.userPrincipalName) to Fabric Capacity. Error: $_.Exception.Response.StatusDescription"
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Output $responseBody
    }
}
