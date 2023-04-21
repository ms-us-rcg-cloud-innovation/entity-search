param(
    [Parameter(Mandatory = $true)]    
    [string] $ServiceName,
    [Parameter(Mandatory = $true)]    
    [string] $Definition,
    [Parameter(Mandatory = $true)]    
    [ValidateSet("Index", "DataSource", "Indexer")]
    [string] $ResourceType,
    [string] $APIVersion = "2020-06-30"
)

function Get-DefaultAzRequestHeaders {
    $headers = @{
        'api-key'      = $env:AZSEARCH_ADMIN_KEY
        'content-type' = "application/json"
    }

    return $headers
}

function Assert-ResourceExists([string] $Uri, [string] $ServiceName) {
    $headers = Get-DefaultAzRequestHeaders        
    try {
        Write-Host -ForegroundColor Green "GET $Uri"
        Invoke-RestMethod -uri $Uri -Method GET -Headers $headers  -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor Green "Response: $status"
        return $status -eq 200    
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $status = $_.Exception.Response.StatusCode.value__

        if ($status -eq 404) {
            Write-Host -ForegroundColor DarkYellow "404 - Resource Not Found"
            return $false
        }
        
        $reason = $_.Exception.Response.ReasonPhrase

        Write-Error "$status | $reason"
        Write-Error $_
        Exit 1
    }
}

function Update-AzSearchResource([string] $Uri, [string] $Definition, [string] $ServiceName) {
    try {   
        Write-Host -ForegroundColor Green "PUT $Uri"
        $headers = Get-DefaultAzRequestHeaders
        $headers.Add("Prefer", "return=representation")
        $response = Invoke-RestMethod -uri $Uri -Method PUT -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor Green "Response: $status"
        return $response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $status = $_.Exception.Response.StatusCode.value__
        $reason = $_.Exception.Response.ReasonPhrase

        Write-Error "$status | $reason"
        Write-Error $_
        Exit 1
    }        
}

function New-AzSearchResource([string] $Uri, [string] $Definition) {
    try {
        Write-Host -ForegroundColor Green "POST $Uri"
        $headers = Get-DefaultAzRequestHeaders
        $response = Invoke-RestMethod -uri $Uri -Method POST -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor Green "Response: $status"
        return $response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $status = $_.Exception.Response.StatusCode.value__
        $reason = $_.Exception.Response.ReasonPhrase

        Write-Error "$status | $reason"
        Write-Error $_
        Exit 1
    }  
}
$scriptPath = $MyInvocation.MyCommand.path
$dir = Split-Path $scriptPath

# move to script location
Push-Location $dir

try
{
    Write-Host -ForegroundColor Blue "Push-Location $dir"

    $endpointMap = @{
        "index" = "indexes"   
        "datasource" = "datasources"
        "indexer" = "indexers" 
    }

    $endpoint = $endpointMap[$ResourceType.ToLower()]
    $apiVersionParam = "api-version=$APIVersion"

    $serviceUri = [string]::Format("https://{0}.search.windows.net/$($endpoint)", $ServiceName)
    
    #try to read content of given file
    if ($null -ne $Definition) {
        
        #$definition = ConvertTo-Json $Definition
    
        if($ResourceType.ToLower() -eq "datasource") {
            $Definition = $Definition.Replace('%COSMOS_DB_CONNECTIONSTRING%', $env:COSMOS_DB_CONNECTIONSTRING)
        }

        Write-Host $Definition

        $resource = $Definition | ConvertFrom-Json -Depth 15
        Write-Host "Resource: $resource"
        Write-Host "Name: $($resource.name)"
        if($null -eq $resource) {
            throw "Unable to parse definition!"
        }

        # check if index exists -- if it exists we'll perform a PUT vs POST        
        if (Assert-ResourceExists -Uri "$serviceUri/$($resource.name)?$apiVersionParam" -ServiceName $serviceName) {
            Write-Host -ForegroundColor DarkYellow "Resource $($resource.name) already exists, proceeding with update!"
            $response = Update-AzSearchResource -Uri "$($serviceUri)/$($resource.name)?$apiVersionParam" -Definition $Definition
        }
        else {
            Write-Host -ForegroundColor DarkYellow "Resource $($resource.name) does not exists, creating!"
            $response = New-AzSearchResource -Uri "$($serviceUri)?$apiVersionParam" -Definition $Definition
        }

        ConvertTo-Json -InputObject $response -Depth 5
    }
    else {
        throw "No definition provided!"
    }
        

}
finally {
  Pop-Location
}
