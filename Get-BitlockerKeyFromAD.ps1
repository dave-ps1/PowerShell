﻿function Get-BitlockerKeyFromAD {

<#
.DESCRIPTION
This script will prompt for the computer name. It will then display the
bitlocker recovery key. In order for this to work correctly, you will 
need to install Remote Server Administration Tools and activate the
following features: Remote Server Administration Tools,
Role Administration Tools, AD DS and AD LDS Tools,
Active Directory Module for Windows PowerShell.

.EXAMPLE
Get-BitlockerRecoveryKey
#>

Function Get-ComputerName {
    #Declare Local Variables
    Set-Variable -Name ComputerName -Scope Local -Force

    Write-Host ""
    $ComputerName = Read-Host "Enter the computer name"
    Return $ComputerName

    #Cleanup Local Variables
    Remove-Variable -Name ComputerName -Scope Local -Force
}


Function Get-BitlockerRecoveryKey {
    param ([String]$ComputerName)

    #Declare Local Variables
    Set-Variable -Name BitLockerObjects -Scope Local -Force
    Set-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Set-Variable -Name Computer -Scope Local -Value $null -Force
    Set-Variable -Name System -Scope Local -Force

    $BitLockerObjects = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' }
    foreach ($System in $BitLockerObjects) {
        $System = $System.DistinguishedName
        $System = $System.Split(',')
        $System = $System[1]
        $System = $System.Split('=')
        $System = $System[1]
        If ($System -eq $ComputerName) {
            $Computer = Get-ADComputer -Filter {Name -eq $System}
            $BitLockerRecoveryKey = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $Computer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
            Write-Host "Computer Name:"$System
            Write-Host "Bitlocker Password ID:"$BitLockerRecoveryKey.Name.Split("{")[1].split("}")[0]
            Write-Host "Bitlocker Recovery Key:"$BitLockerRecoveryKey.'msFVE-RecoveryPassword'
        }
    }
    If ($Computer -eq $null) {
        Write-Host "No recovery key exists" -ForegroundColor Red
    }

    #Cleanup Local Variables
    Remove-Variable -Name BitLockerObjects -Scope Local -Force
    Remove-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Remove-Variable -Name Computer -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name SystemName -Scope Local -Force

cls
Import-Module ActiveDirectory -Scope Global -Force
$SystemName = Get-ComputerName
Get-BitlockerRecoveryKey -ComputerName $SystemName

#Cleanup Local Variables
Remove-Variable -Name SystemName -Scope Local -Force


} # End main function Get-BitlockerKeyFromAD
