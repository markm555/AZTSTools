#********************************************************************************************************************
#**
#********************************************************************************************************************
#
#********************************************************************************************************************
#**  AZ Cost
#**  Developed 9/22/2024 - pull minimal information from API
#**  Modified 9/29/2024 - pull all available information from the API and split api calls to pull no more than 15
#**                       dimentions per call
#**  Author: Mark Moore
#**
#**  This script will make api calls to the Azure API to pull azure cost data for a given date range and
#**  Write the results to a SQL Database
#**
#********************************************************************************************************************
#$tenantID = "<TenantID>"
#$clientId = "<clientID>"
#$clientSecret = "<clientSecret>"
$subscriptionId = "<YoursubscriptionID>"
# SQL Server connection details
$serverName = "<YourSQLServer"
$databaseName = "AZCost" #Change this to another name if desired
$tableName = "History" #Change this to another name if desired
$startDate = "2024-01-01T00:00:00Z"  #Date format can be "2024-09-01T00:00:00Z" or "2024-09-01"
$endDate   = "2024-09-29T23:59:59Z"
$connectionString = "Server=$serverName;Database=master;User ID=<yourusername>;Password=<yourpassword>;TrustServerCertificate=True;"
$connectionString2 = "Server=$serverName;Database=AZCost;User ID=<yourusername>;Password=<yourpassword>;TrustServerCertificate=True;"

#********************************************************************************************************************
#**  Open a connection to the SQL Database
#********************************************************************************************************************

$SQLcon = New-Object System.Data.SqlClient.SqlConnection
$SQLcon.ConnectionString = $connectionString
$SQLcon.Open()

#********************************************************************************************************************
#**  Using the open connection to SQL Create a command structure to use to send T-SQL to the SQL Server
#**  and return results.
#********************************************************************************************************************

$SQLcmd = $SQLcon.CreateCommand()

#********************************************************************************************************************
#**  Using the new command structure.  Send a query to SQL to create the databse AZCost if it does not exist
#**  then close the cmd session and the connection.
#********************************************************************************************************************

$createDbQuery = @"
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$($databaseName)')
BEGIN
    CREATE DATABASE [$($databaseName)]
END
"@

$SQLcmd.CommandText = $createDbQuery
$SQLcmd.ExecuteNonQuery()
$SQLcmd.Close
$SQLcon.Close

#********************************************************************************************************************
#**  Using the same conenction and command structre send another query to create the table if it does not exist
#**  In this section I am using a new connection and command structure changing the database from master to create
#**  The database to AZCost to create and populate the table.
#********************************************************************************************************************

$SQLcon = New-Object System.Data.SqlClient.SqlConnection
$SQLcon.ConnectionString = $connectionString2
$SQLcon.Open()
$SQLcmd = $SQLcon.CreateCommand()


$createTableQuery = @"

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '$($tableName)')
BEGIN
    CREATE TABLE [$($tableName)] (
        Cost MONEY,
        Date DATETIME,
        ResourceID NVARCHAR(MAX),
        ResourceGroupName NVARCHAR(MAX),
        ResourceGroup NVARCHAR(MAX),
        ResourceType NVARCHAR(MAX),
        ResourceLocation NVARCHAR(MAX),
        SubscriptionId NVARCHAR(MAX),
        SubscriptionName NVARCHAR(MAX),
        MeterCategory NVARCHAR(MAX),
        MeterSubcategory NVARCHAR(MAX),
        Meter NVARCHAR(MAX),
        ServiceFamily NVARCHAR(MAX),
        UnitOfMeasure NVARCHAR(MAX),
        PartNumber NVARCHAR(MAX),
        BillingAccountName NVARCHAR(MAX),
        BillingProfileId NVARCHAR(MAX),
        BillingProfileName NVARCHAR(MAX),
        InvoiceSectionId NVARCHAR(MAX),
        InvoiceSectionName NVARCHAR(MAX),
        Product NVARCHAR(MAX),
        ResourceGuid NVARCHAR(MAX),
        ChargeType NVARCHAR(MAX),
        ServiceName NVARCHAR(MAX),
        ProductOrderId NVARCHAR(MAX),
        ProductOrderName NVARCHAR(MAX),
        PublisherType NVARCHAR(MAX),
        ReservationId NVARCHAR(MAX),
        ReservationName NVARCHAR(MAX),
        Frequency NVARCHAR(MAX),
        PricingModel NVARCHAR(MAX),
        CostAllocationRuleName NVARCHAR(MAX),
        Tags NVARCHAR(MAX)
    )
END
"@

$SQLcmd.CommandText = $createTableQuery
$SQLcmd.ExecuteNonQuery()

#********************************************************************************************************************
#**  Get a Bearer Token to make Azure API calls so this script can run unattended
#********************************************************************************************************************

$body = @{
    grant_type    = "client_credentials"
    client_id     = $clientId
    client_secret = $clientSecret
    resource      = "https://management.azure.com/"
}
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $tokenResponse.access_token

#********************************************************************************************************************
#**  Construct the header and the body for the AZ Cost managment API and make the call the first call and populate
#**  The History table with the values for each row.  This will require more than one call to the API becuse
#**  The max number of diminsions per call are 15.
#********************************************************************************************************************

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Set the URI for the first API call
$costDetailsUri1 = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2021-10-01"

# Set the body for the first API call
$costDetailsBody1 = @{
    type = "Usage"
    timeframe = "Custom"
    timePeriod = @{
        from = $startDate
        to = $endDate
    }
    dataset = @{
        granularity = "Daily"
        aggregation = @{
            totalCost = @{
                name = "Cost"
                function = "Sum"
            }
        }
        grouping = @(
            @{ type = "Dimension"; name = "ResourceID" },
            @{ type = "Dimension"; name = "ResourceGroupName" },
            @{ type = "Dimension"; name = "ResourceGroup" },
            @{ type = "Dimension"; name = "ResourceType" },
            @{ type = "Dimension"; name = "ResourceLocation" },
            @{ type = "Dimension"; name = "SubscriptionId" },
            @{ type = "Dimension"; name = "SubscriptionName" },
            @{ type = "Dimension"; name = "MeterCategory" },
            @{ type = "Dimension"; name = "MeterSubcategory" },
            @{ type = "Dimension"; name = "Meter" },
            @{ type = "Dimension"; name = "ServiceFamily" },
            @{ type = "Dimension"; name = "UnitOfMeasure" },
            @{ type = "Dimension"; name = "PartNumber" },
            @{ type = "Dimension"; name = "BillingAccountName" },
            @{ type = "Dimension"; name = "BillingProfileId" }
        )
    }
} | ConvertTo-Json -Depth 10

# Make the first API call
$costDetailsResponse1 = Invoke-RestMethod -Method Post -Uri $costDetailsUri1 -Headers $headers -Body $costDetailsBody1
$costDetails1 = $costDetailsResponse1.properties.rows

# Loop through each row from the first API call
foreach ($row in $costDetails1) {
    $cost = $row[0]
    $date = $row[1]
    $resourceId = $row[2]
    $resourceGroupName = $row[3]
    $resourceGroup = $row[4]
    $resourceType = $row[5]
    $resourceLocation = $row[6]
    $subscriptionId = $row[7]
    $subscriptionName = $row[8]
    $meterCategory = $row[9]
    $meterSubcategory = $row[10]
    $meter = $row[11]
    $serviceFamily = $row[12]
    $unitOfMeasure = $row[13]
    $partNumber = $row[14]
    $billingAccountName = $row[15]
    $billingProfileId = $row[16]
    #write-host($row)
    $tags = get-aztag -ResourceId $resourceId
    
    try
    {
        $jtags = $tags.properties |ConvertTo-Json 2>$null
    }
    catch{}
    $rowquery = @" 
    INSERT INTO [$tableName] (Cost, Date, ResourceID, ResourceGroupName, ResourceGroup, ResourceType, ResourceLocation, SubscriptionId, SubscriptionName, MeterCategory, MeterSubcategory, Meter, ServiceFamily, UnitOfMeasure, PartNumber, BillingAccountName, BillingProfileId, Tags)    
    VALUES                  ($cost, '$date', '$resourceId', '$resourceGroupName', '$resourceGroup', '$resourceType', '$resourceLocation', '$subscriptionId', '$subscriptionName', '$meterCategory', '$meterSubcategory', '$meter', '$serviceFamily', '$unitOfMeasure', '$partNumber', '$billingAccountName', '$billingProfileId', '$jtags')
"@
    
    $SQLcmd.CommandText = $rowQuery
    $SQLcmd.ExecuteNonQuery()

}

#********************************************************************************************************************
#**  Make the second call to the API to get the second group of Dimensions from the API and update the existing
#**  Rows in the database with the additional columns.  If you can think of a more efficient way to do this I would
#**  Love to hear from you.  markm@msn.com
#**
#**  The subscription I am using to test does not have the ability to create reserved instances of any resource and
#**  As a result The API will return an error if I try to pull information about resrved instances.  I have included
#**  Those demensions in the code and have commented them out to get the test working.
#********************************************************************************************************************

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Set the URI for the first API call
$costDetailsUri2 = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.CostManagement/query?api-version=2021-10-01"

# Set the body for the first API call
$costDetailsBody2 = @{
    type = "Usage"
    timeframe = "Custom"
    timePeriod = @{
        from = $startDate
        to = $endDate
    }
    dataset = @{
        granularity = "Daily"
        aggregation = @{
            totalCost = @{
                name = "Cost"
                function = "Sum"
            }
        }
        grouping = @(
            @{ type = "Dimension"; name = "ResourceID" },
            @{ type = "Dimension"; name = "BillingProfileName" },
            @{ type = "Dimension"; name = "InvoiceSectionId" },
            @{ type = "Dimension"; name = "InvoiceSectionName" },
            @{ type = "Dimension"; name = "Product" },
            @{ type = "Dimension"; name = "ResourceGuid" },
            @{ type = "Dimension"; name = "ChargeType" },
            @{ type = "Dimension"; name = "ServiceName" },
            @{ type = "Dimension"; name = "ProductOrderId" },
            @{ type = "Dimension"; name = "Frequency" },
            @{ type = "Dimension"; name = "PricingModel" },
            @{ type = "Dimension"; name = "CostAllocationRuleName" }
 #           @{ type = "Dimension"; name = "ProductOrderName" },
 #           @{ type = "Dimension"; name = "PublisherType" },
 #           @{ type = "Dimension"; name = "ReservationId" },
 #           @{ type = "Dimension"; name = "ReservationName" }
        )
    }
} | ConvertTo-Json -Depth 10

# Make the first API call
$costDetailsResponse2 = Invoke-RestMethod -Method Post -Uri $costDetailsUri1 -Headers $headers -Body $costDetailsBody2
$costDetails2 = $costDetailsResponse2.properties.rows

foreach ($row in $costDetails2) 
{
    $cost = $row[0]
    $date = $row[1]
    $resourceId = $row[2]
    $billingProfileName = $row[3]
    $InvoiceSectionId = $row[4]
    $InvoiceSectionName = $row[5]
    $Product = $row[6]
    $ChargeType = $row[7]
    $ServiceName = $row[8]
    $ProductOrderId = $row[9]
    $Frequency = $row[10]
    $PricingModel = $row[11]
    $CostAllocationRuleName = $row[12]
    #$unitOfMeasure = $row[13]
    #$partNumber = $row[14]
    #$billingAccountName = $row[15]
    #$billingProfileId = $row[16]
    #write-host($row)


    $rowquery2 = @" 
    UPDATE History
    SET 
        BillingProfileName = '$billingProfileName',
        InvoiceSectionId = '$InvoiceSectionId',
        InvoiceSectionName = '$InvoiceSectionName',
        Product = '$Product',
        ChargeType = '$ChargeType',
        ServiceName = '$ServiceName',
        ProductOrderId = '$ProductOrderId',
        Frequency = '$Frequency',
        PricingModel = '$PricingModel',
        CostAllocationRuleName = '$CostAllocationRuleName'
    WHERE 
        Cost = $cost
        AND Date = '$date'
        AND ResourceID = '$resourceId';
"@
    
    $SQLcmd.CommandText = $rowQuery2
    $SQLcmd.ExecuteNonQuery()

}
$SQLcmd.Close
$SQLcon.Close

