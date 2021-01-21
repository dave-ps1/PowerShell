function Get-ServiceStopStart
{
<#
.SYNOPSIS
This function will get, stop, start, or restart a service.
 
.DESCRIPTION
This function will get, stop, start, or restart a service, on local or remote computer(s).

.PARAMETER ComputerName
One or more computer names. This parameter is Mandatory.

.PARAMETER ServiceName
The Service can be the actual name or a partial name using wildcards, ex: "*LAN*"

.EXAMPLE
Get-ServiceStopStart -ComputerName 'Comp1' -ServiceName 'LANrev Server' -Get
Get-ServiceStopStart -ComputerName 'Comp1' -ServiceName 'LANrev Server' -Stop
Get-ServiceStopStart -ComputerName 'Comp1' -ServiceName 'LANrev Server' -Start
Get-ServiceStopStart -ComputerName 'Comp1' -ServiceName 'LANrev Server' -Restart

.EXAMPLE
Get-Content 'C:\Temp\Computers.txt' | Get-ServiceStopStart -ServiceName 'LANrev Server' -Get
'Comp1','Comp2' | Get-ServiceStopStart -ServiceName 'LANrev Server' -Get
#>
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [String[]]$ComputerName,

        [Parameter(Mandatory=$True)]
        #[ValidateSet("LANrev Server","LANrev Agent")] # will only run the services that are listed here.
        [String]$ServiceName,

        [Switch]$Get,
        [Switch]$Stop,
        [Switch]$Start,
        [Switch]$Restart
)

    BEGIN
    {
    }

    PROCESS
    {
        foreach ($Computer in $ComputerName)
        {
            if ( Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue )
            {
                Write-Verbose "Now connecting to: $Computer" -Verbose
                $GetService = Get-Service -Name $ServiceName -ComputerName $Computer

                if ($Get)
                {
                    if ($GetService -like $ServiceName)
                    {
                        Write-Output "Getting the service..."
                        $GetService
                    }
                    else
                    {
                        Write-Warning " Service name $ServiceName not found..."
                    }
                }
                if ($Stop)
                {
                    if ($GetService.Status -eq 'Running')
                    {
                        Write-Output 'Stopping the service...'
                        $GetService | Stop-Service -Force
                    }
                    else
                    {
                        Write-Output 'Service is already stopped...'
                    }
                }
                if ($Start)
                {
                    if ($GetService.Status -ne 'Running')
                    {
                        Write-Output 'Starting the service...'
                        $GetService | Start-Service
                    }
                    else
                    {
                        Write-Output 'Service is already running...'
                    }
                }
                if ($Restart)
                {
                    if ($GetService.Status -eq 'Running' -or $GetService.Status -ne 'Running')
                    {
                        Write-Output 'Restarting the service...'
                        $GetService | Restart-Service -Force
                    }
                    else
                    {
                        Write-Output 'Service is already running...'
                    }
                }
            }
            else
            {
                Write-Warning "OFFLINE: $Computer"
            }
        }
    }

    END
    {
    }
}
