function Get-ComputerSystemInfo
{
<#
.SYNOPSIS
This function will gather computer system information using Get-WmiObject.

.DESCRIPTION
This function will gather computer system information, from multiple
computers and provide error logging information.

.PARAMETER ComputerName
This parameter supports multiple computer names to gather Data from. This parameter is Mandatory.

.EXAMPLE
Getting information from a local computer.

Get-ComputerSystemInfo

.EXAMPLE
Getting information from one or more remote computers.

Get-ComputerSystemInfo -ComputerName 'comp1','comp2'

.EXAMPLE
Getting information from remote computers and exporting the info to a csv excel file.

Get-ComputerSystemInfo -ComputerName (Get-Content -Path 'C:\Temp\ADComputers.txt') -ExportToCSV -ExportErrors -ExportOffline

.EXAMPLE
Export all Windows Computers from AD to a text file.  One computer name per line.

Get-ADComputer -Filter {(enabled -eq "true") -and (OperatingSystem -Like "*Windows 10*")} | Select-Object -ExpandProperty Name | Sort-Object Name | Out-File 'C:\Temp\ADComputers.txt'

$comps = Get-Content -Path 'C:\Temp\ADComputers.txt'
Get-ComputerSystemInfo -ComputerName $comps -ExportToCSV -ExportErrors -ExportOffline
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [String[]]$ComputerName,

        [Switch]$ExportToCSV,
        [Switch]$ExportErrors,
        [Switch]$ExportOffline
    )

    Begin
    {
        if ($ExportToCSV)
        {
            if (-not (Test-Path 'C:\Temp'))
            {
                New-Item -ItemType Directory -Path 'C:\Temp'
            }
        }

        if ($ExportErrors)
        {
            if (-not (Test-Path 'C:\Temp'))
            {
                New-Item -ItemType Directory -Path 'C:\Temp'
            }
        }

        if ($ExportOffline)
        {
            if (-not (Test-Path 'C:\Temp'))
            {
                New-Item -ItemType Directory -Path 'C:\Temp'
            }
        }

        Write-Host "Get Computer Info" -ForegroundColor Green
        Write-Host "Total Computer Count: $(($ComputerName).Count)"
    }

    Process
    {
        foreach($Computer in $ComputerName)
        {
            if (Test-Connection -ComputerName $computer -Count 1 -ErrorAction SilentlyContinue)
            {
                Write-Verbose "Connecting to computer: $computer" -Verbose
                Try
                {
                    $OS = Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem -ErrorAction Stop
                    $DiskC = Get-WmiObject -ComputerName $Computer -Class Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
                    $Proc = Get-WmiObject -Class Win32_Processor -ComputerName $Computer -ErrorAction Stop
                    $Sys = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -ErrorAction Stop
                    $Bios = Get-WmiObject -Class Win32_BIOS -ComputerName $Computer -ErrorAction Stop
                    $Bios2 = Get-WmiObject -Class Win32_SystemEnclosure -ComputerName $Computer -ErrorAction Stop
                    $Net = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $Computer -Filter "IpEnabled = TRUE" -ErrorAction Stop
                    $Process = Get-WmiObject -Class Win32_Process -filter "Name = 'explorer.exe'" -ComputerName $Computer -ErrorAction Stop

                    $ObjInfo = [PSCustomObject][ordered]@{
                        'ComputerName'                    = $computer
                        'Manufacturer'                    = $sys.Manufacturer
                        'Model'                           = $sys.Model
                        'Service Tag'                     = $bios.SerialNumber
                        'Asset Tag'                       = $bios2.SMBIOSAssetTag
                        'BIOS Version'                    = $bios.SMBIOSBIOSVersion
                        'OS Name'                         = $os.caption
                        'OS Architecture'                 = $os.OSArchitecture
                        'OS Version'                      = $os.Version
                        'OS Build'                        = $os.buildnumber
                        'OS Install Date'                 = $os.ConvertToDateTime($os.InstallDate)
                        'Last Boot Time'                  = $os.ConvertToDateTime($os.LastBootupTime)
                        'UserName'                        = $Process.GetOwner().User
                        'UserNameDomain'                  = $sys.UserName
                        'Domain'                          = $sys.domain
                        'IP Address'                      = $net.IPAddress[0]
                        'Subnet Mask'                     = $net.IPSubnet[0]
                        'Default Gateway'                 = $net.DefaultIPGateway
                        'DNS Servers'                     = $net.DNSServerSearchOrder
                        'MAC Address'                     = $net.MACAddress
                        'NIC Description'                 = $net.Description
                        'Processor'                       = $proc.name
                        'Number of Processors'            = $sys.NumberofProcessors
                        'Number of Logical Processors'    = $sys.NumberofLogicalProcessors
                        'Memory'                          = $sys.TotalPhysicalMemory / 1MB -as [int]
                        'Drive'                           = $DiskC.DeviceID
                        'Drive Total Size'                = $DiskC.Size / 1GB -as [int]
                        'Drive FreeSpace'                 = $DiskC.freespace / 1GB -as [int]
                        'Drive Percent Free'              = $DiskC.FreeSpace / $DiskC.Size * 100 -as [int]
                    }

                    if ($ExportToCSV)
                    {
                        $ObjInfo | Export-CSV 'C:\Temp\ComputerSystemInfo-Export.csv' -Append -NoTypeInformation
                        Write-Output "Information was exported to a csv file, it was saved here: ""C:\Temp"""
                    }
                    else
                    {
                        $ObjInfo
                    }
                }
                Catch
                {
                    if ($ExportErrors)
                    {
                        $ObjErrors = [PSCustomObject]@{
                            ComputerName = $Computer
                            Error = $PSItem.Exception.Message
                        }
                        $ObjErrors | Export-CSV 'C:\Temp\ComputerSystemInfo-Errors.csv' -Append -NoTypeInformation
                    }
                    Write-Error "ERROR: $($Computer) - $($PSItem.Exception.Message)"
                }
            }
            else
            {
                if ($ExportOffline)
                {
                    Write-Output "$Computer" | Out-File 'C:\Temp\ComputerSystemInfo-Offline.txt' -Append
                }
                Write-Warning "OFFLINE: $Computer"
            }
        }
    }

    End
    {
    }
}
