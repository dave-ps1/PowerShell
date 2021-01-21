Function Restart-LabComputer
{
<#
.SYNOPSIS
Uses the Restart-Computer cmdlet to reboot remote computers.

.DESCRIPTION
Will restart the remote computer and has switches for all computers or just the ones not currently logged on and in use.

.PARAMETER ComputerName
One or more computer names.

.EXAMPLE
Restart-LabComputer -ComputerName (Get-Content "C:\Temp\ComputerNames.txt") -NotLoggedOn

.EXAMPLE
Restart-LabComputer -ComputerName (Get-Content "C:\Temp\ComputerNames.txt") -All

.EXAMPLE
Get-Content "C:\Temp\ComputerNames.txt" | Restart-LabComputer -NotLoggedOn
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False,
                    ValueFromPipeline=$True,
                    ValueFromPipelinebyPropertyName=$True)]
        [string[]]$ComputerName,

        [Switch]$All,
        [Switch]$NotLoggedOn
    )

    BEGIN
    {
    }

    PROCESS
    {
        ForEach ($Computer in $ComputerName)
        {
            if ($All)
            {
                If ( Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue )
                {
                    Write-Host "$Computer is restarting..."
                    Restart-Computer -ComputerName $Computer -Force -WhatIf
                }
                else
                {
                    Write-Warning "$Computer is offline, skipping..."
                }
            }

            if ($NotLoggedOn)
            {
                If ( Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue )
                {
                    $user = (Get-WmiObject win32_computersystem -comp $computer).username

                    if ($user -eq $null)
                    {
                        Write-Host "$computer has no one logged on, restarting..."
                        Restart-Computer -ComputerName $Computer -Force -WhatIf
                    }
                    else
                    {
                        Write-Host "$computer is logged on by $user, skipping..." -ForegroundColor Yellow
                    }
                }
                else
                {
                    Write-Warning "$Computer is offline, skipping..."
                }
            }
        }
    }

    END
    {
        Write-Host ""
        Write-Host ""
        Write-Host "The script is complete!  Check over the output for any warnings."
        Write-Host ""
    }
}
