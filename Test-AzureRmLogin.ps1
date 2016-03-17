<#
.Synopsis
   Test to verify if you are signed into Azure Rm PowerShell.
.DESCRIPTION
   Test to verify if you are signed into Azure Rm PowerShell.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 3/15/2016 08:42:05 PM 

   Version 1.0
.EXAMPLE
   Test-AzureRmLogin

   $True
#>
#Requires -Modules AzureRm.Profile
function Test-AzureRmLogin
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
    )

    Begin
    {
    }
    Process
    {
         # Verify we are signed into an Azure account
        try {
            Write-Verbose 'Checking if logged into Azure'
            $isLoggedIn = Get-AzureRmContext -ErrorAction Stop
            }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Write-Verbose 'Not logged into Azure. Login now.'
            $isLoggedIn = Login-AzureRmAccount
            }
        catch {
            Write-Error $Error[0].Exception
            }
        [bool]$isLoggedIn
    }
    End
    {
    }
}