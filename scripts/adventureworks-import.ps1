[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $resourceGroupName,
    [Parameter(Mandatory = $true)]
    [string]
    $cosmosAccountName,
    [Parameter(Mandatory = $true)]
    [string]
    $cosmosDatabase,
    [Parameter(Mandatory = $true)]
    [string]
    $collectionId
)

function Submit-PromptUntilYesOrNoInput($yes_or_no_prompt, $func) {
    do {
        $run_tf = (Read-Host -Prompt $yes_or_no_prompt).ToLowerInvariant()
    } while (($run_tf -ne "y") -and ($run_tf -ne "n"))

    if ($run_tf -eq "y") {
        & $func
    }
}

$scriptPath = $MyInvocation.MyCommand.path
$dir = Split-Path $scriptPath

# move to script location
Push-Location $dir

Submit-PromptUntilYesOrNoInput "Install required modules (y/n)?" {
    $azModule = "Az"
    $cosmosModule = "CosmosDB"
    
    Write-Host "Checking if $azModule module is installed"
    if(Get-Module -ListAvailable -Name $azModule) {
        Write-Host "Module $azModule already installed"
    } else {
        Write-Host "$azModule module not installed...installing"
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
    }
    
    Write-Host "Checking if $cosmosModule module is installed"
    if(Get-Module -ListAvailable -Name $cosmosModule) {
        Write-Host "Module $cosmosModule already installed"
    } else {
        Write-Host "Installing module $cosmosModule"

        Install-Module -Name CosmosDB -Verbose
        Import-Module -Name CosmosDB
    }
}

Submit-PromptUntilYesOrNoInput "Import CSV sample file (y/n)?" {
    $adventureProducts = Import-Csv -Path "../data/adventureworks-products.csv"      
    if($adventureProducts.Length -gt 0) {
        $cosmosContext = New-CosmosDbContext -Account $cosmosAccountName -Database $cosmosDatabase -ResourceGroupName $resourceGroupName
        $index = 0
        Write-Host "Importing $($adventureProducts.Length) products"
        foreach($product in $adventureProducts) {                        
            $document = (ConvertTo-Json $product -Depth 10)
            $percent = [Math]::Floor((++$index/$($adventureProducts.Length)) * 100)
            $progress = @{
                Activity = "Inserting"
                Status   = "Inserting record id: $($product.id) | Progress -> $percent%"
                PercentComplete = $percent
            }

            Write-Progress @progress            
            New-CosmosDbDocument -Context $cosmosContext -CollectionId $collectionId -DocumentBody $document -PartitionKey $product.id 
        }
    }
}
