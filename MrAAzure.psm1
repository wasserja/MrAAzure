# Source all ps1 scripts in current directory.
Get-ChildItem (Join-Path $PSScriptRoot *.ps1) | foreach {. $_.FullName}

# Helper Functions
Function Install-AzureRmVMTrendMicroDeepSecurityExtension {
    param (
        [parameter(mandatory)]
        $VMName,
        $ResourceGroupName = 'we-use-rg-prd',
        $Location = 'eastus',
        $PublisherName = 'TrendMicro.DeepSecurity',
        $ExtensionName = 'TrendMicroDSA'
        )


    Install-AzureRmVMExtension -VMName $VMName -ResourceGroupName $ResourceGroupName -Location $Location -PublisherName $PublisherName -ExtensionName $ExtensionName
    }


# Making Parent Functions Available to Module
Export-ModuleMember -Function Install-AzureRmVMExtensionLegacy
Export-ModuleMember -Function Get-AzureRmVMAvailableExtension
Export-ModuleMember -Function Install-AzureRmVMExtension
Export-ModuleMember -Function Set-AzureCustomRouteTable
Export-ModuleMember -Function Copy-AzureBlob
Export-ModuleMember -Function Copy-AzureItem
Export-ModuleMember -Function Install-AzureRmVMTrendMicroDeepSecurityExtension
Export-ModuleMember -Function Test-AzureRmLogin
