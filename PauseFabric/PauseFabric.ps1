<#
*****************************************************************************
**  This script will loop through all azure resources in a subscription    **
**  Locate and Pause all Fabric resources                                  **
**                                                                         **
**  Created by Mark Moore                                                  **
**  Create date: 8/23/2024                                                 **
**                                                                         **
*****************************************************************************
#>

<#
**  Authenticate to Azure using a Service Principal
**  I wrote this intending for it to be run as a batch script in Azure Automate
**  If you are running this interactively, you can authetnicate interactively using
**  connect-azaccount
#>

$azureAplicationId ="<YourServicePrincipalID>"
$azureTenantId= "<YourTenantID>"
$azurePassword = ConvertTo-SecureString "<YourServicePrincipalSecret>" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
Connect-AzAccount -Credential $psCred -TenantId $azureTenantId -ServicePrincipal -SubscriptionID "<YourSubscriptionID>"

# *************** Pause Fabric Resource ***************************

$resources = get-azresource  #** Get all resource in the subscription and place them into an object called $resrouces

$fabricResources = $resources | Where-Object { $_.ResourceId -like "*Microsoft.Fabric*" }  #** Filter for just Fabric resources

#**  Loop through each filtered resource and pause them
foreach ($resource in $fabricResources) 
{
    Invoke-AzResourceAction -ResourceGroupName $resource.ResourceGroupName -ResourceType Microsoft.Fabric/capacities -ResourceName $resource.Name -Action suspend -ApiVersion 2023-11-01 -Force
}
