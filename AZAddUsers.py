# Sample CSV file used as input to this script

#displayName,mailNickname,userPrincipalName,password
#john.doe,john.doe,john.doe@MngEnvMCAP331330.onmicrosoft.com,YourPassword
#jane.smith,jane.smith,jane.smith@MngEnvMCAP331330.onmicrosoft.com,YourPassword

Python Script
Python

import csv
import requests

# Variables
tenant_id = "your-tenant-id"
client_id = "your-client-id"
client_secret = "your-client-secret"
csv_file_path = "path-to-your-csv-file.csv"

# Authenticate using the service principal
token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
token_data = {
    'grant_type': 'client_credentials',
    'client_id': client_id,
    'client_secret': client_secret,
    'scope': 'https://graph.microsoft.com/.default'
}
token_response = requests.post(token_url, data=token_data)
token_response.raise_for_status()
token = token_response.json().get('access_token')

# Read users from CSV file
with open(csv_file_path, mode='r') as file:
    csv_reader = csv.DictReader(file)
    users = [row for row in csv_reader]

# Loop through each user and create them in Entra ID
for user in users:
    user_body = {
        "accountEnabled": True,
        "displayName": user['displayName'],
        "mailNickname": user['mailNickname'],
        "userPrincipalName": user['userPrincipalName'],
        "passwordProfile": {
            "forceChangePasswordNextSignIn": True,
            "password": user['password']
        }
    }

    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }

    response = requests.post("https://graph.microsoft.com/v1.0/users", headers=headers, json=user_body)

    if response.status_code == 201:
        print(f"User {user['userPrincipalName']} created successfully.")
    else:
        print(f"Failed to create user {user['userPrincipalName']}. Response: {response.text}")
