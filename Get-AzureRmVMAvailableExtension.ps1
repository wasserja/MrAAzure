<#
.Synopsis
   Get a list of available extensions for Azure IaaS VM's.
.DESCRIPTION
   Get a list of available extensions for Azure IaaS VM's
   using the Azure RM PowerShell modules. 

   The Get-AzureVMAvailableExtension has not yet been ported
   to the new ARM PowerShell module. Use this function as a
   replacement.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 3/15/2016 02:10:17 PM 

   Version 1.0
.PARAMETER PublisherName
    Enter a name of a publisher. Wildcards are acceptable, but
    a single * will timeout.
.PARAMETER Location
    Enter an Azure data center location (i.e. eastus)
.PARAMETER ExtensionName
    Enter the name of an extension. Wildcards are acceptable.
.EXAMPLE
   Get-AzureRmVMAvailableExtension -PublisherName Microsoft*

   Select from the list of available extensions from the publisher
   Microsoft. 
.EXAMPLE
   Get-AzureRmVMAvailableExtension -PublisherName Microsoft.Compute -ExtensionName BGInfo

   Get the BGInfo extension from Microsoft.Compute publisher.
.EXAMPLE
   Get-AzureRmVMAvailableExtension -PublisherName TrendMicro*

   Get a list of available extensions published by Trend Micro.
.LINK
   
#>
#Requires -Modules AzureRM.profile,AzureRM.Compute
function Get-AzureRmVMAvailableExtension
{
    [CmdletBinding()]
    [Alias()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$PublisherName,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]$Location = 'eastus',

        [string]$ExtensionName
    )

    Begin
    {
        Write-Verbose "Beginning $($MyInvocation.InvocationName)"
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
        
        # Getting a list of publishers
        # 
        Write-Verbose "Getting a list of publishers like $PublisherName"
        $AzureRmVMImagePublisher = Get-AzureRmVMImagePublisher -Location $Location | Where-Object -FilterScript {$_.PublisherName -like $PublisherName}
        
        # Verify if there is more than one matching publisher
        if ($AzureRmVMImagePublisher.Count -gt 1) {
            Write-Verbose "More than one publisher found matching $PublisherName"
            $AzureRmVMImagePublisher = $AzureRmVMImagePublisher | Out-GridView -PassThru
            }
        
        # Filter by extension name if one was provided as a parameter.
        if ($ExtensionName) {
            Write-Verbose "Getting a list of extensions."
            $Extensions = $AzureRmVMImagePublisher | Get-AzureRmVMExtensionImageType | Get-AzureRmVMExtensionImage | Where-Object -FilterScript {$_.Type -like $ExtensionName}
            }
        # Get all Extensions from the supplied publisher.
        else {
            $Extensions = $AzureRmVMImagePublisher | Get-AzureRmVMExtensionImageType | Get-AzureRmVMExtensionImage
            }
        # No matching extensions were found.
        if (!$Extensions) {
            Write-Verbose 'No matching extensions found.'
            }
        # Matching extensions were found.
        else {
            # If more than one matching extensions found, allow the user to select one or more.
            if ($Extensions.Count -gt 1) {
                Write-Verbose "More than one matching extension found."
                $Extensions = $Extensions | Out-GridView -PassThru
                }
            }
        $Extensions
    }
    End
    {
    }
}