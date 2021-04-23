#Add RSATADTools
$state = Get-WindowsCapability -name “Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0” -online
if ($state.state -ne "Installed") {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name "UseWUServer" -Value 0
    Get-Service -Name wuauserv | Restart-Service
    Add-WindowsCapability –online –Name “Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0”
    Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name "UseWUServer" -Value 1
    Get-Service -Name wuauserv | Restart-Service
    Import-Module -Name ActiveDirectory
    }

#Get list of profiles
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
[pscustomobject[]]$finalresults = $null
cd $HKLM
$profilelist = dir

#Parse each profile in list
foreach ($item in $profilelist) {
    $pieces = $($item.Name).Split('\')
    $HKLMlocation = -join ($HKLM, "\$($pieces[6])")
    $path = Get-ItemProperty -Path $HKLMlocation | select profileimagepath
    $path = $($path.ProfileImagePath).Split('\')
    #If ProfileImagePath belongs to a user, pull ADUser data
    if ( $($path[2]) -match "\d\d\d\d\d\d") {
        $name = Get-ADUser -Filter "samaccountname -eq $($path[2])" | select name, Enabled
        #If ADUser is disabled, place in table
        if ($name.enabled -eq "False") {
            $results = '' | select name, EIN, SID, Enabled
            $results.name = $name.name
            $results.EIN = $($path[2])
            $results.SID = $($pieces[6])
            $results.enabled = $name.Enabled
            $finalresults += $results
            }
        }
    }
cd C:
out-Host -InputObject $finalresults