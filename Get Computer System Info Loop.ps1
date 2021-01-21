Clear-Host
Write-Host "`nGet Computer Info Loop`n" -ForegroundColor Blue





# Start Loop
$Counter = 0
$Total = 100
do {
$Counter = $Counter+=1
Write-Host "Executing loop $Counter of $Total" -ForegroundColor Green
##########





function makecomputerlist {
# Get AD Computers and save to a text file.
Get-ADComputer -Filter { (OperatingSystem -like "*Windows 10*") -and (Enabled -eq "True") } -SearchBase "DC=domain,DC=org" -Server "domain.org" | Where-Object { $_.DNSHostName -like "*domain.org" } | Select-Object -ExpandProperty Name | Sort-Object | Out-File -FilePath "C:\Temp\ADComputers-ComputerInfo.txt" -Append
}
makecomputerlist





function makenewcomputerlist {
# Compare the ADComputers.txt and the ComputerInfo.csv and make a new ADComputers.txt
# file for only the computers that are not in the ComputerInfo.csv file.
if (-not (Test-Path -Path "C:\Temp\ComputerInfo.csv") ) { New-Item -ItemType 'File' -Path "C:\Temp\ComputerInfo.csv" }
$Csv = Import-Csv -Path "C:\Temp\ComputerInfo.csv"
$Array = @()
foreach ($Item in (Get-Content -Path "C:\Temp\ADComputers-ComputerInfo.txt")) {
    if ($Csv.ComputerName -contains $Item) {
        #"$Item info has already been collected"
    }
    else {
        $Array += $Item
    }
}
if (Test-Path -Path "C:\Temp\ADComputers-ComputerInfo.txt") { Remove-Item -Path "C:\Temp\ADComputers-ComputerInfo.txt" -Force }
$Array | Select-Object -Unique | Sort-Object | Out-File -FilePath "C:\Temp\ADComputers-ComputerInfo.txt"
}
makenewcomputerlist





# Get the total count from ADComputers.txt and ComputerInfo.csv
Write-Host "ADComputers.txt  computer count: $((Get-Content -Path "C:\Temp\ADComputers-ComputerInfo.txt").Count)"
Write-Host "ComputerInfo.csv computer count: $((Import-Csv -Path "C:\Temp\ComputerInfo.csv").Count)"





function runpsremoting {
# PsRemoting
$ComputerName = Get-Content -Path "C:\Temp\ADComputers-ComputerInfo.txt"
$Success = Invoke-Command -ComputerName $ComputerName -ErrorVariable Failed -SessionOption (New-PSSessionOption -NoMachineProfile) -ErrorAction SilentlyContinue -ScriptBlock {

$OS = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop
$DiskC = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
$Proc = Get-WmiObject -Class Win32_Processor -ErrorAction Stop
$Sys = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
$Bios = Get-WmiObject -Class Win32_BIOS -ErrorAction Stop
$Bios2 = Get-WmiObject -Class Win32_SystemEnclosure -ErrorAction Stop
$Net = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'IpEnabled = True' -ErrorAction Stop

$Process = Get-WmiObject -Class Win32_Process -filter "Name = 'explorer.exe'" -ErrorAction Stop
#$Lenovo = Get-WmiObject Win32_ComputerSystemProduct | Select Vendor, Version, Name, IdentifyingNumber

[PSCustomObject][ordered]@{
ComputerName                 = $env:COMPUTERNAME
Manufacturer                 = $sys.Manufacturer
Model                        = $sys.Model
SerialNumber                 = $bios.SerialNumber
AssetTag                     = $bios2.SMBIOSAssetTag
BIOSVersion                  = $bios.SMBIOSBIOSVersion
OSName                       = $os.caption
OSArchitecture               = $os.OSArchitecture
OSVersion                    = $os.Version
OSBuild                      = $os.buildnumber
OSInstallDate                = $os.ConvertToDateTime($os.InstallDate)
LastBootTime                 = $os.ConvertToDateTime($os.LastBootupTime)
LogonTime                    = ($Process.ConvertToDateTime($Process.CreationDate))
UserName                     = $Process.GetOwner().User
DomainUserName               = $sys.UserName
Domain                       = $sys.domain
IPAddress                    = $net.IPAddress[0]
SubnetMask                   = $net.IPSubnet[0]
DefaultGateway               = $net.DefaultIPGateway
DNSServers                   = $net.DNSServerSearchOrder
MACAddress                   = $net.MACAddress
NICDescription               = $net.Description
Processor                    = $proc.name
NumberOfProcessors           = $sys.NumberofProcessors
NumberOfLogicalProcessors    = $sys.NumberofLogicalProcessors
Memory                       = $sys.TotalPhysicalMemory / 1MB -as [int]
Drive                        = $DiskC.DeviceID
DriveTotalSize               = $DiskC.Size / 1GB -as [int]
DriveFreeSpace               = $DiskC.freespace / 1GB -as [int]
DrivePercentFree             = $DiskC.FreeSpace / $DiskC.Size * 100 -as [int]
}

} # End ScriptBlock

# Display results to screen and out to file.
$Success | Select-Object -Property * | Export-Csv -Path 'C:\Temp\ComputerInfo.csv' -Append -NoTypeInformation

# Display failures to screen and out to file.
$Failed.TargetObject | Out-File -FilePath 'C:\Temp\Failed.txt' -Append
}
runpsremoting





##########
# End Loop
}
Until ( $Counter -eq $Total )
