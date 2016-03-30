<#
.Synopsis
   Get a list of the Azure Public IP addresses/subnets per region.
.DESCRIPTION
   Get a list of the Azure Public IP addresses/subnets per region.
   The script scrapes the Microsoft download page to find the URL
   to the current Azure Public IP list xml file. Then it downloads
   the file to a temporary location and outputs the list of IP 
   addresses and subnets for each region selected.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 2/17/2016 02:32:13 PM 
   Version: 0.999
.PARAMETER Region
   Enter the Azure region by name. Use the ListRegions switch to get 
   a list of available regions by name.
   Wildcards are acceptable.
.PARAMETER XmlFilePath
   Enter a temporary path to store the XML file.
.PARAMETER DownloadUrl
   The URL has been pre-populated from the Azure documentation website.
   https://azure.microsoft.com/en-us/documentation/articles/backup-azure-vms-troubleshoot/#networking
.PARAMETER ListRegions
   Get a list of the region names.
.EXAMPLE 
   Get-AzurePublicIpList -ListRegions
   
   
    Name
    ----
    europewest
    useast
    useast2
    uswest
    usnorth
    europenorth
    uscentral
    asiaeast
    asiasoutheast
    ussouth
    japanwest
    japaneast
    brazilsouth
    australiaeast
    australiasoutheast
    indiacentral
    indiawest
    indiasouth

    List the available regions by name
.EXAMPLE
   Get-AzurePublicIpList -Region useast

   Location Subnet
    -------- ------
    useast   23.96.0.0/18
    useast   23.96.64.0/28
    useast   23.96.64.64/26
    useast   23.96.64.128/27
    useast   23.96.64.160/28
    useast   23.96.80.0/20
    useast   23.96.96.0/19
    useast   23.100.16.0/20

    Get a list of subnets from region useast.
.LINK
   https://azure.microsoft.com/en-us/documentation/articles/backup-azure-vms-troubleshoot/#networking
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Get-AzurePublicIpList-928b0a0d
#>
function Get-AzurePublicIpList
{
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Region,
        [string]$XmlFilePath = 'C:\Temp\AzurePublicIpList.xml',
        [string]$DownloadUrl = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=41653',
        [switch]$ListRegions
    )

    Begin
    {
        # Establish Empty array
        $AzurePublicIpSubnets = @()
    }
    Process
    {
        # Scrape the Download page from Microsoft
        $Uri = Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing
        # This line is for not basic parsing, but it kept prompting for accepting the cookies.
        #$AzurePublicIpXmlUri = ($Uri.Links | Where-Object -FilterScript {$_.InnerText -eq 'Click here'}).href 

        # Find the link in the download page that has the xml. Three identical links are actually listed, so we just grab the first one.
        $AzurePublicIpXmlUri = ($Uri.Links | Where-Object -FilterScript {$_.href -like '*.xml'})[0].href

        # Create a WebClient Object and download the file to the path specified.
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($AzurePublicIpXmlUri,$XmlFilePath)

        # Create an XML object from the XML file
        [xml]$AzurePublicIpListXml = Get-Content $XmlFilePath

        # List the regions from the XML file
        if ($ListRegions) {
            # List Regions
            $AzurePublicIpListXml.AzurePublicIpAddresses.Region | Select-Object -Property Name
            }

        # List the subnets by region from the XML file
        else {
            # Get a list of the regions 
            $Regions = $AzurePublicIpListXml.AzurePublicIpAddresses.Region | Where-Object -FilterScript {$_.name -like "$Region"} | Select-Object -Property Name

            # Loop through each matching region
            foreach ($Location in $Regions) {
    
                # Get a list of the subnets in this region/location
                $Subnets = $AzurePublicIpListXml.AzurePublicIpAddresses.Region | Where-Object -FilterScript {$_.name -like "$($Location.Name)"} | Select-Object -ExpandProperty IpRange
    
                # Loop through each subnet in this region and create custom object
                foreach ($Subnet in $Subnets) {
                    $AzureSubnetProperties = [ordered]@{
                        Location = $Location.Name
                        Subnet = $Subnet.Subnet
                        }
                    $AzureSubnet = New-Object -TypeName PSCustomObject -Property $AzureSubnetProperties
        
                    # Append custom object to final output object
                    $AzurePublicIpSubnets += $AzureSubnet
                    }
                }
        
            # Output Object to the pipeline
            Write-Output $AzurePublicIpSubnets    
            
            }
    }
    End
    {
    }
}