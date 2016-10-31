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
