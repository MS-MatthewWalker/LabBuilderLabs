

function ShowMenu 

{
 [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        # Title for Selection box
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Title,

        # Informational Title 
        [Parameter(Mandatory=$true,Position=1)]
        [String]$Message,

        # Source of Text file to import to Selction box.
        [Parameter(Mandatory=$true,Position=1)]
        [String]$ListSource
    )
    
# $Title = "Choose Configuration"
# $Message = "Choose the appropriate configuration for the lab you want to build"
# $ListSource = ".\Configurations\MenuList.txt"

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = $Title
$objForm.Size = New-Object System.Drawing.Size(500,300) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(250,220)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(175,220)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$objListBox.SelectedItem;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(400,20) 
$objLabel.Text = $message
$objForm.Controls.Add($objLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,40) 
$objListBox.Size = New-Object System.Drawing.Size(400,20) 
$objListBox.Height = 175

Get-Content $ListSource | ForEach-Object {[void] $objListBox.Items.Add($_)}

$objForm.Controls.Add($objListBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$selected = $objListBox.Selecteditem
    
} 

ShowMenu -Title "Choose Configuration" -Message "Choose the appropriate configuration for the lab you want to build" -ListSource ".\Configurations\MenuList.txt"