<#
.Synopsis
   Install-AzureRmVMExtension simplifies the process of installing 
   VM extensions on Azure IaaS resource manager VM's.
.DESCRIPTION
   Install-AzureRmVMExtension simplifies the process of installing 
   VM extensions on Azure IaaS resource manager VM's.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 3/15/2016 02:09:36 PM 

   Version 1.5

.EXAMPLE
   Install-AzureRmVMExtension -VMName server01 -ResourceGroupName rg01 -Location eastus -PublisherName Microsoft.Compute -Type bginfo
   
   RequestId IsSuccessStatusCode StatusCode ReasonPhrase
    --------- ------------------- ---------- ------------
                             True         OK OK

   Installs the bginfo extension on server01 in resource group rg01 located in the East US Azure Datacenter.
.EXAMPLE
   Install-AzureRmVMExtension -VMName server01 -ResourceGroupName rg01 -Location eastus

   Opens a grid view of available extensions that you can install on server01.
.EXAMPLE
   Install-AzureRmVMExtension -VMName server01 -ResourceGroupName rg01 -Location eastus -PublisherName TrendMicro.DeepSecurity -ExtensionName TrendMicroDSA
   
   RequestId IsSuccessStatusCode StatusCode ReasonPhrase
    --------- ------------------- ---------- ------------
                             True         OK OK

   Installs the TrendMicro Deep Security extension on server01 in resource group rg01 located in the East US Azure Datacenter.
#>
#Requires -Modules AzureRM.profile,AzureRM.Compute
function Install-AzureRmVMExtension
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [string[]]$VMName,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$ResourceGroupName = 'we-use-rg-prd',
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Location = 'eastus',
        
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [string]$PublisherName,
        
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ExtensionName')]
        [string]$Type,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Version
        
    )

    Begin
    {
        
        # Verify we are signed into an Azure account
        if (Test-AzureRmLogin) {
            Write-Verbose 'Logged into Azure. Continuing.'
            }
        else {
            Write-Error 'Not logged into Azure. Exiting.'
            }
        
    }
    Process
    {
        
        $Extensions = Get-AzureRmVMAvailableExtension -Location $Location -PublisherName $PublisherName -ExtensionName $Type
        if ($Extensions) {
            
            foreach ($VM in $VMName) {
                # Add try/catch for verifying vm exists

                try {
                    $AzureVM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VM -ErrorAction Stop
                    }
                catch [Microsoft.Azure.Commands.Compute.Common.ComputeCloudException] {
                    Write-Error $Error[0].Exception
                    return
                    }
                catch {
                    Write-Error $Error[0].Exception
                    return
                    }

                foreach ($Extension in $Extensions) {
                    Set-AzureRmVMExtension -ExtensionName $Extension.Type -Publisher $Extension.PublisherName -ExtensionType $Extension.Type -Version $Extension.Version -Location $Location -ResourceGroupName $ResourceGroupName -VMName $VM 
                    }
                }
            }
        else {
            Write-Error 'No matching extensions found. Exiting.'
            }


    }
    End {}
}