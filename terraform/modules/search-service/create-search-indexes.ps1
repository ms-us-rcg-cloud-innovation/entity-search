[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]
    $searchServiceName,
    [Parameter(Mandatory = $true)]
    [string]
    $indexesFilePath
)

$apiVersionQueryParam = "api-version=2020-06-30"
$searchServiceIndexesUri = "https://{0}.search.windows.net/indexes"

function TryGet-IndexesFileContent([string] $FilePath, [ref] $Content) {
    if (Test-Path -Path $FilePath) {
        try {
            $Content.Value = Get-Content -Path $FilePath
            return $true
        }
        catch {
            Write-Error $_
            Exit 1
        }
    }

    return $false
}

function Get-DefaultAzRequestHeaders {
    $headers = @{
        'api-key'      = $env:AZSEARCH_ADMIN_KEY
        'content-type' = "application/json"
    }

    return $headers
}

function Assert-IndexExists([string] $IndexName) {
    $headers = Get-DefaultAzRequestHeaders        
    $uri = [string]::Format("$searchServiceIndexesUri/$($indexName)/stats?$apiVersionQueryParam", $searchServiceName)
    try {
        Write-Host -ForegroundColor DarkYellow "GET $uri"
        Invoke-RestMethod -uri $uri -Method GET -Headers $headers  -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        return $status -eq 200    
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $status = $_.Exception.Response.StatusCode.value__

        if($status -eq 404){
            Write-Host -ForegroundColor DarkRed "404 - Not Found"
            return $false
        }
        
        Write-Error $_
        Exit 1
    }
}

function Update-AzSearchIndex([string] $IndexName, [string] $Definition) {
    try {
        $uri = [string]::Format("$searchServiceIndexesUri/$($indexName)?$apiVersionQueryParam", $searchServiceName)    
        Write-Host -ForegroundColor DarkYellow "PUT $uri"
        $headers = Get-DefaultAzRequestHeaders
        $headers.Add("Prefer", "return=representation")
        $response = Invoke-RestMethod -uri $uri -Method PUT -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        Write-Output $response | ConvertTo-Json -Depth 15
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error $_
        Exit 1
    }        
}

function New-AzSearchIndex([string] $IndexName, [string] $Definition) {
    try {
        $uri = [string]::Format("$($searchServiceIndexesUri)?$apiVersionQueryParam", $searchServiceName)
        Write-Host -ForegroundColor DarkYellow "POST $uri"
        $headers = Get-DefaultAzRequestHeaders
        $response = Invoke-RestMethod -uri $uri -Method POST -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        Write-Output $response | ConvertTo-Json -Depth 15
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error $_
        Exit 1
    }  
}

$content = $null
#try to read content of given file
if (TryGet-IndexesFileContent -FilePath $indexesFilePath -Content ([ref]$content)) {
    $index = Write-Output $content | ConvertFrom-Json -Depth 15

    $response = $null
    # check if index exists -- if it exists we'll perform a PUT vs POST
    
    
    if (Assert-IndexExists -IndexName $index.name) {
        Write-Host -ForegroundColor DarkYellow "Index $($index.name) already exists, proceeding with update"
        Update-AzSearchIndex -IndexName $index.name -Definition $content
    }
    else {
        Write-Host -ForegroundColor DarkYellow "Index $($index.name) does not exists, creating index"
        New-AzSearchIndex -IndexName $index.name -Definition $content
    }
}


