<#
.Synopsis
   Install-AzureRmVmExtension simplifies the process of installing 
   VM extensions on Azure IaaS resource manager VM's.
.DESCRIPTION
   Install-AzureRmVmExtension simplifies the process of installing 
   VM extensions on Azure IaaS resource manager VM's.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 3/14/2016 11:53:40 AM 

   Version 1.0

.EXAMPLE
   Install-AzureRmVmExtension -VMName server01 -ResourceGroupName rg01 -Location eastus -Extension bginfo
   
   RequestId IsSuccessStatusCode StatusCode ReasonPhrase
    --------- ------------------- ---------- ------------
                             True         OK OK

   Installs the bginfo extension on server01 in resource group rg01 located in the East US Azure Datacenter.
.EXAMPLE
   Install-AzureRmVmExtension -VMName server01 -ResourceGroupName rg01 -Location eastus

   Opens a grid view of available extensions that you can install on server01.
#>
#Requires -module Azure,AzureRM.profile,AzureRM.Compute
function Install-AzureRmVMExtensionLegacy
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$VMName,
        $ResourceGroupName = 'we-use-rg-prd',
        $Location = 'eastus',
        [string[]]$ExtensionName
        
    )

    Begin
    {
        
        # Verify we are signed into an Azure account
        try {
            $Subscriptions = Get-AzureRmSubscription -ErrorAction Stop
            }
        catch [System.Management.Automation.PSInvalidOperationException] {
            Login-AzureRmAccount
            }
        catch {
            Write-Error $Error[0].Exception
            }
        
        # Get All Extensions
        $AzureVMAvailableExtensions = Get-AzureVMAvailableExtension

        # If an extension was provided as a parameter, filter by the provided paramater extension name.
        if ($ExtensionName) {
            $Extensions = $AzureVMAvailableExtensions | Where-Object -FilterScript {$_.ExtensionName -like $ExtensionName}
            }
        # Else pop up a gridview of all of the available extensions to be selected.
        else {
            $Extensions = $AzureVMAvailableExtensions | Out-GridView -PassThru
            }

        # Register TrendMicro Example
        # Cmd /c "c:\Program Files\Trend Micro\Deep Security Agent\dsa_control.cmd" -a dsm://agents.deepsecurity.trendmicro.com:443/ tenantID:20698506-a2d9-4ff5-9e53-026a54d71262 tenantPassword:771119ca-125d-4893-86fa-d7f82e2f2729

    }
    Process
    {
        
        foreach ($VM in $VMName) {
            foreach ($Extension in $Extensions) {
                Set-AzureRmVMExtension -ExtensionName $Extension.ExtensionName -Publisher $Extension.Publisher -ExtensionType $Extension.ExtensionName -Version $Extension.Version -Location $Location -ResourceGroupName $ResourceGroupName -VMName $VM
                }
            }
    }
    End {}
}