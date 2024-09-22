# Documentation for the Cost API used in this example can be found here:
# https://learn.microsoft.com/en-us/rest/api/cost-management/generate-cost-details-report/create-operation?view=rest-cost-management-2023-11-01&tabs=HTTP
# There are many options that can be used to pull cost data back based on what you require refer to the documentation to customer what is returned from the API.

# Define variables
$tenantId = "<YourTenant>"
$clientId = "<YourClientID>"
$clientSecret = "<YourClientSecret>"
$subscriptionId = "<YourSubscriptionID>"
$databaseServer = "<YourSQLServer>"
$databaseName = "AzureCost"
$databaseUser = "<YourSQLLogin>"
#$databasePassword = "<YourSQLPassword>"
$tableName = "History"


$con = new-object System.Data.SqlClient.SqlConnection "Server=db;Pooling=false;Integrated Security=true"
$con.Open()

$cmd = $con.CreateCommand()

# If the database does not exist, create it

$cmd.CommandText = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'AZCost')
BEGIN
    CREATE DATABASE AZCost
END
"@

# Execute the command
$cmd.ExecuteNonQuery()

#If the table does not exist create it.

$cmd.CommandText = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'AZCost')
BEGIN
    CREATE DATABASE AZCost
END
"@
$cmd.ExecuteNonQuery()

# Switch to the AZCost database
$con.ChangeDatabase("AZCost")

# Create the SQL command to create the table if it doesn't exist
$cmd.CommandText = @"
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'History')
BEGIN
    CREATE TABLE History (
        Date DATETIME,
        Subscription NVARCHAR(255),
        RG NVARCHAR(255),
        Name NVARCHAR(255),
        Location NVARCHAR(255),
        Cost NVARCHAR(255),
        Resource NVARCHAR(255),
        Provider1 NVARCHAR(255),
        Provider2 NVARCHAR(255),
        Tags NVARCHAR(255),
        Currency NVARCHAR(255)
    )
END
"@
$cmd.ExecuteNonQuery()

# Close the connection
$con.Close()


# Get Azure AD token
$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = "https://management.azure.com/"
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $tokenResponse.access_token

# Get cost details from Azure Cost Management API
$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}
$costDetailsUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2021-10-01"
$costDetailsBody = @{
    type = "Usage"
    timeframe = "YearToDate"
    dataset = @{
        granularity = "Daily"
        aggregation = @{
            totalCost = @{
                name = "Cost"
                function = "Sum"
            }
        }
        grouping = @(
            @{
                type = "Dimension"
                name = "ResourceID"
            }
        )
    }
} | ConvertTo-Json -Depth 10

$costDetailsResponse = Invoke-RestMethod -Method Post -Uri $costDetailsUri -Headers $headers -Body $costDetailsBody
$costDetails = $costDetailsResponse.properties.rows
#$costDetails |Format-Table

$con = New-Object System.Data.SqlClient.SqlConnection "Server=db;Pooling=false;Integrated Security=true"
$con.Open()

# Switch to the AZCost database
$con.ChangeDatabase("AZCost")


$i = 0
foreach($row in $costDetails)
{
    $Cost = $row[0]

    $date = [datetime]::ParseExact($row[1], "yyyyMMdd", $null)
    $Date = $date.ToString("yyyy-MM-dd")

       #$resource = $row[2]
       #write-host("Resource; ",$row)
       $Resource = Get-AzResource -ResourceId $row[2] -ErrorAction SilentlyContinue

    if ($null -eq $resource) 
    {
        #Write-Output "Resource not found."
        $Location = "Deleted"
        $Name = ($row[2] -split '/')[ -1 ]
        $subscription = $row[2].split("/")[2]
        $RG = $row[2].split("/")[4]
        $Provider1 = $row[2].split("/")[6]
        $Provider2 = $row[2].split("/")[7]

    } 
    else 
    {
        #Write-Output "Resource found."
        $Location = $resource.Location
        $Name = $resource.Name
        $RG = $resource.ResourceGroupName
        $subscription = $row[2].split("/")[2]
        $Provider1 = $row[2].split("/")[6]
        $Provider2 = $row[2].split("/")[7]
       }

    if($Tag -eq $Null)
    {
    }
    else
    {
    $Tags = $resource.Tags | ConvertTo-Json
    write-host("API: ",$resource.Tags)
    write-host("JSON: ",$Tags)
    }
    $Currency = $row[3]

    #write-host($Date, "  ", $resource, "  ", $cost, "  ", $Name, "   ", $RG, "  ", $Location, "  ", $Tags, $currency)
    #write-host("----------")

# Create the SQL command to insert data into the History table
    $cmd = $con.CreateCommand()
            $cmd.CommandText = " 
                INSERT INTO [dbo].[History] 
                ([Date],
                [Subscription],
                [RG],
    	    	[Name],
	    	    [Location],
    	    	[Cost],
	    	    [Resource],
    		    [Provider1],
        		[Provider2],
	        	[Tags],
                [Currency]
                ) 
            VALUES 
               ('$Date',
                '$Subscription',
                '$RG',
                '$Name',
                '$Location',
                '$Cost',
                '$Resource',
                '$Provider1',
                '$Provider2',
                '$Tags',
                '$Currency')  "
                    
# Execute the command
   $cmd.ExecuteNonQuery()

    Write-Host($Date)

}
