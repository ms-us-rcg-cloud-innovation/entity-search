[CmdletBinding()]
param (
    [Parameter()]
    [string] $tf_varfile
)

$tf_planfile =  "entity_search.tfplan"
$tf_output = $null
function Submit-PromptUntilYesOrNoInput($yes_or_no_prompt, $func) {
    do {
        $run_tf = (Read-Host -Prompt $yes_or_no_prompt).ToLowerInvariant()
    } while (($run_tf -ne "y") -and ($run_tf -ne "n"))

    if ($run_tf -eq "y") {
        & $func
    }
}

function New-AzureFunctionDeployment([string] $resource_group, [string] $name, [string]$path) {
    try {
        # push current script path to top of location
        Push-LocationWrapper $path
        
        # dotnet publish the change feed indexer func
        dotnet publish -c Release --os linux -f net6.0 -o "./output"
        
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet publish failed."
        }

        # zip the publish folder for deployment, overwrite if it exists
        Compress-Archive -Path "./output/*" -DestinationPath "output.zip" -Force

        # deploy change-feed function zip to azure
        az functionapp deployment source config-zip -g $resource_group -n $name --src "output.zip"

        if ($LASTEXITCODE -ne 0) {
            throw "az functionapp deployment source config-zip failed."
        }
    }
    finally {
        Pop-Location
    }

}

# function for deploying azure infrastructure
function New-AzureSearchInfrastructure([string] $repoRoot) {
    try {
        # push terraform folder to top of location
        Push-LocationWrapper "$repoRoot/infrastructure/terraform/cognitive-search"

        # create infrastructure
        terraform init

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed."
        }

        # create a terraform plan for cognitive search using default variables    
        terraform plan -detailed-exitcode -var-file="$tf_varfile" -out="$tf_planfile"

        if ($LASTEXITCODE -eq 0) {
            Write-Host -ForegroundColor Green "No change detected, skippling apply"
        }
        elseif ($LASTEXITCODE -eq 1) {
            throw "Terraform plan failed."
        }
        else {
            # last exit code is 2
            Write-Host -ForegroundColor Green "Terraform plan detected changes. Performing apply..."
        
            # apply the generated plan
            terraform apply "$tf_planfile"

            if ($LASTEXITCODE -eq 1) {
                throw "Terraform apply failed."
            }
        }        
    }
    finally {
        Pop-Location
    }    
}

function Get-TerraformOutput([string] $repoRoot) {
    try {
        # push terraform folder to top of location
        Push-LocationWrapper "$repoRoot/infrastructure/terraform/cognitive-search"
        $output = terraform output -json | ConvertFrom-Json

        if ($LASTEXITCODE -ne 0) {
            throw "Terraform output failed."
        }

        return $output
    }
    finally {
        Pop-Location
    }
}

function Push-LocationWrapper([string] $path) {
    Write-Host -ForegroundColor DarkYellow "Trying to push: $path"
    Push-Location $path
    if ($error.count -gt 0) {
        throw $error[0].Exception
    }
    Write-Host -ForegroundColor Green "Pushed location: $path"
}

try {
    
    # push current script path to top of location
    $scriptpath = $MyInvocation.MyCommand.Path
    
    # get the root directory of the repo
    $root = Split-Path (Split-Path $scriptpath -Parent) -Parent
    
    Push-LocationWrapper "$root/scripts"

    # prompt user to create infrastructure
    Submit-PromptUntilYesOrNoInput "Deploy infrastrucutre (y/n)?" {
        # create infrastructure
        Write-Host -ForegroundColor Green "Creating infrastructure..."
        New-AzureSearchInfrastructure $root
        Write-Host -ForegroundColor Green "Infrastructure created."
    }

    # capture output variables from terraform to use for function deployment
    $tf_output = Get-TerraformOutput $root

    Submit-PromptUntilYesOrNoInput "Deploy Change Feed function (y/n)?" {        
        Write-host -ForegroundColor Green "Deploying Change Feed Functions..."
        New-AzureFunctionDeployment $tf_output.resource_group_name.value $tf_output.change_feed_function_name.value "$root/src/apps/ChangeFeedIndexerFunction"
        Write-host -ForegroundColor Green "Change Feed Functions deployed."
    }
    
    Submit-PromptUntilYesOrNoInput "Deploy Search API function (y/n)?" {        
        Write-host -ForegroundColor Green "Deploying Search Function..."
        New-AzureFunctionDeployment $tf_output.resource_group_name.value $tf_output.search_function_name.value "$root/src/apps/SearchFunction" 
        Write-host -ForegroundColor Green "Search Function deployed."
    }



    # prompt user to import sample data using cosmosdb-csv-import.ps1 script
    Submit-PromptUntilYesOrNoInput "Import sample data (y/n)?" {
        try {
            
            # push back to scripts folder
            Push-LocationWrapper "$root/scripts"
            
            # import sample data            
            ./cosmosdb-csv-import.ps1 -dataFilePath "$root/data/search-demo/adventureworks-products.csv" `
                -resourceGroupName $tf_output.resource_group_name.value `
                -cosmosAccountName $tf_output.cosmosdb_account_name.value `
                -cosmosDatabase $tf_output.cosmosdb_database_name.value `
                -containerName $tf_output.cosmosdb_container_name.value
        }
        finally {
            Pop-Location
        }        
    }

    if($null -ne $tf_output && $LASTEXITCODE -ne 1) {
        Write-Host "Deployment complete using the following values:"
        $tf_output | ConvertTo-Json -Depth 100
    }
}
catch {
    Write-Error $_.Exception
}
finally {
    Pop-Location
    # clear error stack
    $error.Clear()
}       
