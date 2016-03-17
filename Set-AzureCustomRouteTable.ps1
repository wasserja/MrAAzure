<#
.Synopsis
   Set-AzureCustomRouteTable assists in creating and modifying Azure route tables.
.DESCRIPTION
   Set-AzureCustomRouteTable assists in creating and modifying Azure route tables.
   The function will create a new route table if it doesn't exist, or modify a route
   table if it does exist. Additionally the route table can be applied to an existing
   subnet in an Azure virtual network.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 2/15/2016 04:48:12 PM 
   Version: 0.9
.PARAMETER RouteTableName
   Enter a name for the route table to be created/modified.
.PARAMETER Location
   Enter an Azure data center location. Get-AzureLocation | Select-Object -Property Name
.PARAMETER RouteTableLabel
   Enter a description for your route table.
.PARAMETER VirtualNetworkName
   Enter a name of an existing virtual network if you wish to apply the route table.
   This parameter also requires the SubnetName.
.PARAMETER SubnetName
   Enter a name of an existing subnet in your Azure virtual network.
.PARAMETER CustomRouteCsvPath
   Enter a path to a CSV formatted file with proper fields.
   
   Format:
   RouteTableName,Location,RouteTableLabel,RouteName,AddressPrefix,NextHopType,NextHopIpAddress,VirtualNetworkName,SubnetName
   BogusRouteTable2,East Us,Custom Route table,AzureUsEast-1,23.96.0.0/18,Internet,,,
   BogusRouteTable2,East Us,Custom Route table,AzureUsEast-2,23.96.64.0/28,Internet,,,
   BogusRouteTable2,East Us,Custom Route table,AzureUsEast-3,8.8.8.8/32,VirtualAppliance,10.200.201.10,DefaultVirtualNetwork,Subnet-1

.EXAMPLE
   Set-AzureCustomRouteTable -RouteTableName DMZRouteTable -Location 'East US' -RouteTableLable 'Custom Route Table for DMZ'

   Creates or modifies route table named DMZRouteTable. The script will ask you to 
   enter the routes to add to this subnet.
.EXAMPLE
   Set-AzureCustomRouteTable -RouteTableName DMZRouteTable -Location 'East US' -RouteTableLable 'Custom Route Table for DMZ' -VirtualNetworkName DefaultVNet -SubnetName DMZSubnet

   Creates or modifies route table named DMZRouteTable. The script will ask you to 
   enter the routes to add to this subnet. It will then apply the route table to the DMZSubnet
   in the virtual network DefaultVNet.
.EXAMPLE
   Set-AzureCustomRouteTable -CustomRouteCsvPath C:\Temp\Set-AzureCustomRouteTable.csv

   Creates or modifies route tables listed in the CSV file, including adding routes, and 
   applying route tables to subnets.
.LINK
   https://azure.microsoft.com/en-us/documentation/articles/virtual-networks-udr-overview/
.LINK
   https://gallery.technet.microsoft.com/scriptcenter/Set-AzureCustomRouteTable-e8488a43
#>
#Requires -Modules Azure
function Set-AzureCustomRouteTable
{
    [CmdletBinding()]
    Param
    (
        [string]$RouteTableName,
        [string]$Location,
        [string]$RouteTableLabel,
        [string]$VirtualNetworkName,
        [string]$SubnetName,
        [string]$CustomRouteCsvPath
    )

    Begin
    {
        
        # Initialize $CustomRoute array
        $CustomRoute = @()
        $RouteTable = $null

        #region Set-AzureCustomRoute
        <#
        .PARAMETER
        #>
        function Set-AzureCustomRoute {
            param (
                [Parameter(Mandatory)]
                [AllowEmptyString()]
                [string]$RouteName,
                
                [Parameter(Mandatory)]
                [AllowEmptyString()]
                [string]$AddressPrefix,
                
                # Azure is case sensitive on these values
                [Parameter(Mandatory,HelpMessage='Values are case-senstive.')]
                [Validateset('VPNGateway','VNETLocal','Internet','VirtualAppliance','Null','',IgnoreCase = $false)]
                [AllowEmptyString()]
                [string]$NextHopType,

                [Parameter(Mandatory)]
                [AllowEmptyString()]
                [string]$NextHopIpAddress
                )
            

            # A route name was entered, so we're going to add it to an object.
            if ($RouteName) {
                Write-Verbose 'Route name not null, continuing.'
                $CustomRouteProperties = [ordered]@{
                    RouteTable = $RouteTable
                    RouteName = $RouteName
                    AddressPrefix = $AddressPrefix
                    NextHopType = $NextHopType
                    NextHopIpAddress = $NextHopIpAddress
                    }
                Write-Verbose 'Creating Custom route object'
                $CustomRoute = New-Object -TypeName PSCustomObject -Property $CustomRouteProperties
                Write-Verbose 'Adding custom route to route table.'
                Set-AzureRoute -RouteTable $CustomRoute.RouteTable -RouteName $CustomRoute.RouteName -AddressPrefix $CustomRoute.AddressPrefix -NextHopType $CustomRoute.NextHopType -NextHopIpAddress $CustomRoute.NextHopIpAddress      
                }
            # No route name entered, assuming all done and returning the $CustomRoute Object
            else {
                Write-Verbose 'No route name entered, assuming all done.'
                return $null
                }
            
            }
            #endregion
        
        #region Set-AzureCustomRouteCSV
        function Set-AzureCustomRouteCSV {
            param (
                $CustomRouteCsvPath
                )
                # Verify the Csv File actually exists
                if (Test-Path -Path $CustomRouteCsvPath) {
                    $CustomRouteCsv = Get-Content -Path $CustomRouteCsvPath | ConvertFrom-Csv
                    foreach ($CustomRoute in $CustomRouteCSV) {
                        
                        # Verify Route table, create if necessary.
                        $RouteTable = Test-AzureCustomRouteTable -RouteTableName $CustomRoute.RouteTableName

                        # Set the azure custom route
                        Write-Verbose "Adding custom route $($CustomRoute.RouteName) to route table $($CustomRoute.RouteTableName)"
                        Set-AzureRoute -RouteTable $RouteTable -RouteName $CustomRoute.RouteName -AddressPrefix $CustomRoute.AddressPrefix -NextHopType $CustomRoute.NextHopType -NextHopIpAddress $CustomRoute.NextHopIpAddress
                        
                        # If a Virtual Network and Subnet were provided, then apply the route table to that virtual network and subnet.
                        if ($CustomRoute.VirtualNetworkName -and $CustomRoute.SubnetName) {
            
                            # But first we need to validate that the Virtual Network and Subnets exist
                            # Coming soon

                            Write-Verbose -Message "Applying Route Table $($CustomRoute.RouteTableName) to subnet $($CustomRoute.SubnetName) in virtual network $($CustomRoute.VirtualNetworkName)"
                            Set-AzureSubnetRouteTable -VirtualNetworkName $CustomRoute.VirtualNetworkName -SubnetName $CustomRoute.SubnetName -RouteTableName $CustomRoute.RouteTableName

                            Write-Verbose -Message "Verifying Route table has been applied."
                            Get-AzureSubnetRouteTable -VirtualNetworkName $CustomRoute.VirtualNetworkName -SubnetName $CustomRoute.SubnetName -Detailed
                            }

                        }
                    }
                else {
                    Write-Error "$CustomRouteCSV path not found."
                    }
            }
        #endregion

        #region Test-AzureCustomRouteTable
        # This function is to test to see if the custom route table exists.
        # It will create the table if it doesn't exist.
        function Test-AzureCustomRouteTable {
            param (
                [Parameter(Mandatory)]
                [string]$RouteTableName
                )

            # We first need to validate if the table already exists. If it already exists then we need to add the routes.
            try {
                $RouteTable = Get-AzureRouteTable -Name $RouteTableName -ErrorAction Stop
                }
            catch [Hyak.Common.CloudException] {
                # Route Table does not yet exist so we will need to create it.
                Write-Verbose $Error[0].Exception.Message
                }
            catch {
                Write-Error "An error occurred when trying to determine if the route table $RouteTable exists."
                return
                }
        
            # Does the Route table already exist in Azure in that $Location?
            if ($RouteTable) {
                # Route Table exists.
                Write-Verbose "Route table $RouteTableName already exists."
                Write-Output $RouteTable
                }
            # Route Table does not exist in $Location.
            else {
                # If the route table doesn't exist, create it now.
                Write-Verbose "Creating new route table."

                # Create Custom Route Table
                if (!$RouteTableName) {
                    $RouteTableName = Read-Host -Prompt 'RouteTableName'
                    }
                if (!$Location) {
                    $Location = Read-Host -Prompt 'Location'
                    }
                if (!$RouteTableLabel) {
                    $RouteTableLabel = Read-Host -Prompt 'RouteTableLable'
                    }
                $RouteTable = New-AzureRouteTable -Name $RouteTableName -Location $Location -Label $RouteTableLabel
                Write-Output $RouteTable
                }               
            }
        #endregion

    }
    Process
    {
        
     
        #region MainProcess

        # Enter custom routes via CSV
        if ($CustomRouteCsvPath) {
            Set-AzureCustomRouteCSV -CustomRouteCsvPath $CustomRouteCsvPath
            }
        
        # Manual
        else {
            # This is for "manually entry"
            # This loop will continue until the CustomRoute.RouteName is $null.
            do {
                # Test to see if the route table already exists
                if (!$RouteTableName) {
                    $RouteTableName = Read-Host -Prompt 'RouteTableName'
                    }
                $RouteTable = Test-AzureCustomRouteTable -RouteTableName $RouteTableName
                
                Write-Host 'Getting custom routes.'
                Write-Host 'Enter blank values to stop.'
                $CustomRoute = Set-AzureCustomRoute
                $CustomRoute
                }
            while ($CustomRoute) 

            # View Custom Route Table routes
            # Write-Verbose "Routes have been added to $RouteTableName"
            Get-AzureRouteTable -Name $RouteTableName -Detailed

            # If a Virtual Network and Subnet were provided, then apply the route table to that virtual network and subnet.
            if ($VirtualNetworkName -and $SubnetName) {
            
                # But first we need to validate that the Virtual Network and Subnets exist


                # Applying Azure Custom Route table
                Write-Verbose -Message "Applying Route Table $RouteTableName to subnet $SubnetName in virtual network $VirtualNetworkName"
                Set-AzureSubnetRouteTable -VirtualNetworkName $VirtualNetworkName -SubnetName $SubnetName -RouteTableName $RouteTableName
                }

            }
        #endregion

    }
    End
    {
    }
}