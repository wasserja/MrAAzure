<#
.Synopsis
   Copy blob files (vhds) between Azure storage accounts.
.DESCRIPTION
   Copy VHD blob files (vhds) between Azure storage accounts.

   Sometimes it is necessary to copy VHD files between storage accounts
   in Azure. In addition you may need to copy VHD files between storage
   accounts located in different Azure subscriptions. 
.NOTES
   Created by: Jason Wasser @wasserja
   Modified: 3/7/2016 03:56:46 PM 
.PARAMETER SourceSubscriptionId
.PARAMETER DestinationSubscriptionId
.PARAMETER srcUri
.PARAMETER SourceStorageAccount
.PARAMETER SourceStorageKey
.PARAMETER DestinationStorageAccount
.PARAMETER DestinationStorageKey
.PARAMETER DestinationContainerName
.PARAMETER DestinationBlobName
.EXAMPLE
   Copy-AzureBlob
.EXAMPLE
   Another example of how to use this cmdlet

.LINK
    https://www.opsgility.com/blog/windows-azure-powershell-reference-guide/copying-vhds-blobs-between-storage-accounts/
    Mostly stolen from here, but needed to modify to add ARM support.
#>
function Copy-AzureBlob
{
    [CmdletBinding()]
    [Alias()]
    Param
    (

        [string]$SourceSubscriptionId,
        [string]$DestinationSubscriptionId,
        
        # Enter the uri for the source vhd
        [string]$srcUri = 'https://mystorageaccount.blob.core.windows.net/vhds/myvhd.vhd',
        
        ### Source Storage Account ###
        [string]$SourceStorageAccount = 'sourcestorageaccountname',
        [string]$SourceStorageKey = 'STORAGEKEY',

        ### Target Storage Account ###
        [string]$DestinationStorageAccount = 'destinationstorageaccountname',
        [string]$DestinationStorageKey = 'STORAGEKEY',

        ### Destination Names ### 
        [string]$DestContainerName = 'vhds',
        [string]$DestinationBlobName = 'myvhd.vhd'
    )

    Begin
    {
    }
    Process
    {
        
        # Gather source and destination Azure subscriptions. 
        $SourceSubscription = Get-AzureRmSubscription -SubscriptionId $SourceSubscriptionId
        if ($DestinationSubscriptionId) {
            $DestinationSubscription = Get-AzureRmSubscription -SubscriptionId $DestinationSubscriptionId    
            }
        else {
            $DestinationSubscription = Get-AzureRmSubscription -SubscriptionId $SourceSubscriptionId
            }
        
        
        # Set subscription to the subscription containing the storage account and
        # blob file you need to copy.
        Select-AzureRmSubscription -SubscriptionName $SourceSubscription.SubscriptionName

        ### Create the source storage account context ### 
        $SrcContext = New-AzureStorageContext  –StorageAccountName $SourceStorageAccount -StorageAccountKey $SourceStorageKey  
        
        # Set subscription to the destination subscription.
        Select-AzureRmSubscription -SubscriptionName $DestinationSubscription.SubscriptionName 

        ### Create the destination storage account context ### 
        $destContext = New-AzureStorageContext  –StorageAccountName $DestinationStorageAccount -StorageAccountKey $DestinationStorageKey  

        ### Create the container on the destination ### 
        # Probably need to verify if the container already exists
        New-AzureStorageContainer -Name $DestContainerName -Context $destContext 

        ### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
        $BlobCopyJob = Start-AzureStorageBlobCopy -srcUri $srcUri `
                                    -SrcContext $srcContext `
                                    -DestContainer $DestContainerName `
                                    -DestBlob $DestinationBlobName `
                                    -DestContext $destContext
        ### Retrieve the current status of the copy operation ###
        $BlobCopyJobStatus = $BlobCopyJob | Get-AzureStorageBlobCopyState 
 
        ### Print out status ### 
        $BlobCopyJobStatus 
 
        ### Loop until complete ###                                    
        While($BlobCopyJobStatus.Status -eq 'Pending'){
            $BlobCopyJobStatus = $BlobCopyJob | Get-AzureStorageBlobCopyState 
            Start-Sleep 10
            ### Print out status ###
            $BlobCopyJobStatus
        }

    }
    End
    {
    }
}