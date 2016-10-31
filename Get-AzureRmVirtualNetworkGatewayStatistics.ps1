<#
.Synopsis
   Generate and collect logs from an Azure Resource Manager virtual network gateway.
.DESCRIPTION
   When deploying a virtual network gateway in Azure you may need to troubleshoot if 
   connectivity issues arise. At the time of writing this script, both the Azure and
   AzureRM PowerShell modules are required to generate and collect the logs and statistics. 
   This script connects both PowerShell sessions required, starts the statisics and then 
   retrieves the log file for review.
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 10/31/2016 10:30:21 AM 
   Version 0.5
.PARAMETER SubscriptionId
    Provide the subscription Id of the subscription containing the virtual network
    gateway.

    Get-AzureRmSubscription
.PARAMETER StorageAccountName
    Provide a storage account name where the vpn gateway statisics will be stored.
.PARAMETER ResourceGroupName
    Provide the resource group name of the storage account. 
.PARAMETER VirtualNetworkGatewayId
    Provide the ID of the virtual network gateway for which you want to capture statistics. 

    Use Get-AzureVirtualNetworkGateway to find the GatewayId
.PARAMETER CaptureDuration
    Provide the duration in seconds of how long you would like to capture statistics.
.PARAMETER LogFile
    Provide a path to a log file.
.PARAMETER StorageContainer
    Provide a name of the storage container that will store the virtual network gateway
    statistics.
.EXAMPLE
   Get-AzureRmVirtualNetworkGatewayStatistics -SubscriptionId 195c0aaa-c80f-4e66-8490-f571c26174e1 -StorageAccountName storageaccount001 -ResourceGroupName rg001 -VirtualNetworkGatewayId 777fd324-151b-4d3d-bf91-9318cf09e138 
   
   Gather and collect virtual network gateway statistics for a gateway in a specific subscription.
.LINK
   https://miteshc.wordpress.com/tag/start-azurevirtualnetworkgatewaydiagnostics-azure-vpn-diagnostics-download-azure-vpn-diagnostics-azure-gateway-diagnostics-download/
#>
#Requires -Modules Azure,AzureRM
function Get-AzureRmVirtualNetworkGatewayStatistics
{
    [CmdletBinding()]
    param (
        [parameter(Mandatory)]
        [string]$SubscriptionId,
        [parameter(Mandatory)]
        [string]$StorageAccountName,
        [parameter(Mandatory)]
        [string]$ResourceGroupName,
        [parameter(Mandatory)]
        [string]$VirtualNetworkGatewayId,
        [int]$CaptureDuration = 60,
        [string]$LogFile = "C:\Logs\AzureVirtualNetworkGatewayDiagnostics-$(Get-Date -Format yyyymmddhhmmss).log",
        [string]$StorageContainer = 'vpnlogs'
        )
    
    begin {
        $ErrorActionPreference = 'Stop'
        $VerbosePreference = 'Continue'
        #region Azure Login
        # Requires login to Azure and AzureRM for now.

        # Log in to Azure PowerShell
        Write-Verbose 'Verifying login to Azure'
        if (Get-AzureAccount) {
            Write-Verbose 'Logged in to Azure already.'
            }
        else {
            Write-Verbose 'Logging into Azure Classic'
            $Credential = Get-Credential -Message 'Login to Azure'
            Add-AzureAccount -Credential $Credential
            }

        # Log in to AzureRM PowerShell
        Write-Verbose 'Verifying login to AzureRm'
        if (Test-AzureRmLogin) {
            Write-Verbose 'Logging in to AzureRm.'
            }
        #endregion 
    
        }
    process {
        
        # Select the subscription in both Azure PowerShell contexts
        Write-Verbose "Switching to subscription $SubscriptionId for both Azure and AzureRm."
        try {
            $Subscription = Select-AzureSubscription -SubscriptionId $SubscriptionId
            $SubscriptionRm = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
            }
        catch {
            Write-Error "$($Error[0].Exception.Message) $SubscriptionId"
            return 
            }
        

        
        # Verify resource group name
        try {
            Write-Verbose "Verifying $ResourceGroupName exists."
            $Resourcegroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
            Write-Verbose "Resource group $ResourceGroupName exists."
            }
        catch {
            Write-Error "$($Error[0].Exception.Message) $ResourceGroupName"
            return
            }

        # Get the storage account where we will store the logs.
        try {
            Write-Verbose "Verifying $StorageAccountName exists."
            $StorageAccount = Get-AzureRmStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
            Write-Verbose "Storage account $StorageAccountName exists."
            $StorageAccountKey = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName)[0].Value
            $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
            }
        catch {
            Write-Error "$($Error[0].Exception.Message) $StorageAccountName"
            return
            }

        
        # Get the Azure Virtual Network gateway using Azure classic PowerShell
        Write-Verbose 'Getting the Azure Network Gateway'
        try {
            $VirtualNetworkGateway = Get-AzureVirtualNetworkGateway -GatewayId $VirtualNetworkGatewayId
            }
        catch {
            Write-Error "Unable to get the Azure Virtual Network Gateway with id $VirtualNetworkGatewayId."
            return
            }

        # Starting the Azure Virtual Network Gateway diagnostics
        Write-Verbose "Starting diagnostics for $($VirtualNetworkGateway.GatewayName) for $CaptureDuration seconds."
        $AzureVirtualNetworkDiagnostics = Start-AzureVirtualNetworkGatewayDiagnostics -GatewayId $VirtualNetworkGateway.GatewayId -CaptureDurationInSeconds $CaptureDuration -StorageContext $StorageContext -ContainerName $StorageContainer
        Start-Sleep -Seconds $CaptureDuration
        Write-Verbose 'Diagnostics capture completed.'

        # Capture log from storage account to local log directory.
        Write-Verbose "Capture log from storage account to local log $LogFile"
        $LogUrl = (Get-AzureVirtualNetworkGatewayDiagnostics -GatewayId $VirtualNetworkGateway.GatewayId).DiagnosticsUrl
        $LogContent = (Invoke-WebRequest -Uri $LogUrl).RawContent
        $LogContent | Out-File -FilePath $LogFile
        Start-Process $LogFile
    }
    end {}
}