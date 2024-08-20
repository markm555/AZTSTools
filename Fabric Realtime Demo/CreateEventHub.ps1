
function NewEH {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $eventHub = [PSCustomObject]@{
        Namespace = ""
        ehName = ""
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Event Hub Input'
    $form.Size = New-Object System.Drawing.Size (300,225)
    $form.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point (75,140)
    $okButton.Size = New-Object System.Drawing.Size (75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point (150,140)
    $cancelButton.Size = New-Object System.Drawing.Size (75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $textBoxNS = New-Object System.Windows.Forms.TextBox
    $textBoxNS.Location = New-Object System.Drawing.Point (10,20)
    $textBoxNS.Size = New-Object System.Drawing.Size (260,20)
    $form.Controls.Add($textBoxNS)

    $nameSpace = New-Object System.Windows.Forms.Label
    $nameSpace.Location = New-Object System.Drawing.Point (10,40)
    $nameSpace.Size = New-Object System.Drawing.Size (280,20)
    $nameSpace.Text = "New Eventhub Namespace Name"
    $form.Controls.Add($nameSpace)

    $textBoxEH = New-Object System.Windows.Forms.TextBox
    $textBoxEH.Location = New-Object System.Drawing.Point (10,60)
    $textBoxEH.Size = New-Object System.Drawing.Size (260,20)
    $form.Controls.Add($textBoxEH)

    $EH = New-Object System.Windows.Forms.Label
    $EH.Location = New-Object System.Drawing.Point (10,80)
    $EH.Size = New-Object System.Drawing.Size (280,20)
    $EH.Text = "New Eventhub Name"
    $form.Controls.Add($EH)

    $form.Topmost = $true
    $form.Add_Shown({$textBoxEH.Select()})

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $eventHub.Namespace = $textBoxNS.Text
        $eventHub.ehName = $textBoxEH.Text
        return $eventHub
    }
}

Function NewRG
{

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $rvalues =@{}
    [void] [System.Windows.Forms.Application]::EnableVisualStyles() 

    $Form                 = New-Object system.Windows.Forms.Form
    $Form.Size            = New-Object System.Drawing.Size(500,300)
    $Form.MaximizeBox     = $false
    $Form.StartPosition   = "CenterScreen"
    $Form.FormBorderStyle = 'Fixed3D'
    $Form.Text            = "NEW RESOURCE GROUP INPUT"

    #application Drop down list
    $LabelDropDown          = New-Object System.Windows.Forms.Label
    $LabelDropDown.Text     = "Please Select a Region"
    $LabelDropDown.AutoSize = $true
    $LabelDropDown.Location = New-Object System.Drawing.Size(300,10)
    $Form.Controls.Add($LabelDropDown)

    # list of applications
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(300,30)
    $listBox.Size = New-Object System.Drawing.Size(150,60)
    $listBox.Height = 200
    # add the items to the listbox
    $null = $listBox.Items.AddRange(@('centralus','eastus','eastus2','northcentralus','southcentralus','westcentralus','westus','westus2','westus3','asia','asiapacific','australia','brazil','canada','europe','france','germany','india','japan','korea','norway','singapore','southafrica','switzerland','uae','uk','southafricanorth','southafricawest','australiacentral','australiacentral2','australiaeast','australiasoutheast','centralindia','eastasia'))
    $listBox.SelectedIndex = 0
    # add functionality to react on index changed
    $listBox.Add_SelectedIndexChanged({    

    $rvalues.Region=$($($this.SelectedItem))

    })

    $Form.Controls.Add($listBox)

    # File path of previous months file
    $LabelPrevious          = New-Object System.Windows.Forms.Label
    $LabelPrevious.Text     = "Enter New Resource Group Name"
    $LabelPrevious.AutoSize = $true
    $LabelPrevious.Location = New-Object System.Drawing.Size(20,80)
    $Form.Controls.Add($LabelPrevious) 

    # first Input file path
    #$textBoxFile1.Text     = "New Resource Group Name"
    $textBoxFile1          = New-Object System.Windows.Forms.TextBox
    $textBoxFile1.Location = New-Object System.Drawing.Point(20,60)
    $textBoxFile1.Size     = New-Object System.Drawing.Size(250,20)
    $Form.Controls.Add($textBoxFile1)


    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,175)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,175)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)



    $Okbutton.Add_Click({

        $rvalues.Name=$($textBoxFile1.Text)

    }) 
    $Form.Controls.Add($Okbutton) 

    $Form.ShowDialog() 
    return $rvalues
    # important! dispose of the form when done
    $Form.Dispose()

}


Function RGPicker{
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $RGs = Get-AzResourceGroup |Sort-Object ResourceGroupName 

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select a Resource Group'
    $form.Size = New-Object System.Drawing.Size(650,400)
    $form.StartPosition = 'CenterScreen'

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,275)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(150,275)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $newButton = New-Object System.Windows.Forms.Button
    $newButton.Location = New-Object System.Drawing.Point(225,275)
    $newButton.Size = New-Object System.Drawing.Size(75,23)
    $newButton.Text = 'NEW RG'
    $newButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $form.AcceptButton = $newButton
    $form.Controls.Add($newButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(80,20)
    $label.Text = 'Please select a Subscription:'

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(300,25)
    $listBox.Height = 230

    $textline = "                                                                                                                           "
    foreach ($RG in $RGs)
    {
        [void] $listbox.items.add($RG.ResourceGroupName)
    }

    $form.Controls.Add($listBox)
    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes)
    {
        #$r = getValues "New Resource Group" "Enter RG Name"
        #write-Host($r)
        #$NRG = NewRG
        return "New"

    }   
    

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        $x = $listBox.SelectedIndex
        #$subs[$x]
        return $RGs[$x]   
    }

}

# -- Main Program Starts Here -- #

# Login to Azure
#Connect-AzAccount

Clear-Host

write-host("*****************************************************************************************")
write-host("**                         Loading Forms Please Wait                                   **")
write-host("*****************************************************************************************")

$RGInfo = RGPicker

if($RGInfo -eq "New")
{
    $NRGInfo = NewRG
    $resourceGroupName = $NRGInfo.Name
    $location = $NRGInfo.Region
    New-AzResourceGroup -Name $resourceGroupName -Location $location
}
else
{
    $resourceGroupName = $RGInfo.ResourceGroupName
    $location = (get-azresourcegroup -Name $resourceGroupName).Location

}

# Variables
#$resourceGroupName = "markm-fabric2"
#$location = "SouthCentralUS"

$EHInfo = NewEH
$namespaceName = $EHInfo.Namespace
$eventHubName = $EhInfo.ehName
$keyName = $EHInfo.keyName
$keyName = "RootManageSharedAccessKey"



# Create a resource group


#$RG = RGPicker

#$RG

# Create an Event Hub namespace
$namespace = New-AzEventHubNamespace -ResourceGroupName $resourceGroupName -Name $namespaceName -Location $location

# Create an Event Hub
$eventHub = New-AzEventHub -ResourceGroupName $resourceGroupName -NamespaceName $namespaceName -Name $eventHubName

# Get the key
$key = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -NamespaceName $namespaceName -AuthorizationRuleName $keyName

# Output the details
#$namespaceName
#$eventHubName
#$key.KeyName
#$key.PrimaryKey

Write-host("Copy the following lines of code and replace Lines 21 through 24 in the C# program with them")
Write-host("--------------------------------------------------------------------------")
write-host("--                                C#                                    --")
Write-host("--------------------------------------------------------------------------")
write-host(" ")
write-host('private static readonly string EHNamespace = "' + $namespaceName + '";') 
write-host('private static readonly string EHName = "' + $eventHubName + '";') 
write-host('private static readonly string EHKeyname = "' + $key.Keyname + '";') 
write-host('private static readonly string EHKey = "' + $key.PrimaryKey + '";') 
write-host(" ")
write-host(" ")
Write-host("--------------------------------------------------------------------------")
write-host("--                              Python                                  --")
Write-host("--------------------------------------------------------------------------")
write-host(" ")
write-host('EHNamespace = "' + $namespaceName + '"') 
write-host('EHName = "' + $eventHubName + '"') 
write-host('EHKeyname = "' + $key.Keyname + '"') 
write-host('EHKey = "' + $key.PrimaryKey + '"') 

