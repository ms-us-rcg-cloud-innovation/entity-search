[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $dataFilePath,
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
    $containerName
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

try
{
    Submit-PromptUntilYesOrNoInput "Prepare modules (y/n)?" {
        $azModule = "Az"
        $cosmosModule = "CosmosDB"
    
        Write-Host "Checking if $azModule module is installed"
        if (Get-Module -ListAvailable -Name $azModule) {
            Write-Host "Module $azModule already installed"
        }
        else {
            Write-Host "$azModule module not installed...installing"
            Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
        }
        
        Write-Host "Checking if $cosmosModule module is installed"
        if (Get-Module -ListAvailable -Name $cosmosModule) {
            Write-Host "Module $cosmosModule already installed"
        }
        else {
            Write-Host "Installing module $cosmosModule"
    
            Install-Module -Name CosmosDB -Verbose
            Import-Module -Name CosmosDB
        }
    }
    
    Submit-PromptUntilYesOrNoInput "Import data from '$dataFilePath' (y/n)?" {
        $data = Import-Csv -Path $dataFilePath      
        if ($data.Length -gt 0) {
            $cosmosContext = New-CosmosDbContext -Account $cosmosAccountName -Database $cosmosDatabase -ResourceGroupName $resourceGroupName
            $index = 0
            Write-Host "Importing $($data.Length) products"
            foreach ($d in $data) {                        
                $document = (ConvertTo-Json $d -Depth 10)
                $percent = [Math]::Floor((++$index / $($data.Length)) * 100)
                $progress = @{
                    Activity        = "Inserting"
                    Status          = "Inserting record id: $($d.id) | Progress -> $percent%"
                    PercentComplete = $percent
                }
    
                Write-Progress @progress            
                New-CosmosDbDocument -Context $cosmosContext -CollectionId $containerName -DocumentBody $document -PartitionKey $d.id 
            }
        }
    }
}
finally {
  Pop-Location
}
