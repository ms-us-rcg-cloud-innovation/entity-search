param(
    [Parameter(Mandatory = $true)]    
    [string] $ServiceName,
    [Parameter(Mandatory = $true)]    
    [string] $DefinitionFile,
    [Parameter(Mandatory = $true)]    
    [string] $APIVersion,
    [Parameter(Mandatory = $true)]    
    [ValidateSet("Index", "DataSource", "Indexer")]
    [string] $ResourceType
)

function TryGet-FileContent([string] $FilePath, [ref] $Content) {
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

function Assert-ResourceExists([string] $Uri, [string] $ServiceName) {
    $headers = Get-DefaultAzRequestHeaders        
    try {
        Write-Host -ForegroundColor DarkYellow "GET $Uri"
        Invoke-RestMethod -uri $Uri -Method GET -Headers $headers  -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        return $status -eq 200    
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        $status = $_.Exception.Response.StatusCode.value__

        if ($status -eq 404) {
            Write-Host -ForegroundColor DarkRed "404 - Not Found"
            return $false
        }
        
        Write-Error $_
        Exit 1
    }
}

function Update-AzSearchResource([string] $Uri, [string] $Definition, [string] $ServiceName) {
    try {   
        Write-Host -ForegroundColor DarkYellow "PUT $Uri"
        $headers = Get-DefaultAzRequestHeaders
        $headers.Add("Prefer", "return=representation")
        $response = Invoke-RestMethod -uri $Uri -Method PUT -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        return $response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error $_
        Exit 1
    }        
}

function New-AzSearchResource([string] $Uri, [string] $Definition) {
    try {
        Write-Host -ForegroundColor DarkYellow "POST $Uri"
        $headers = Get-DefaultAzRequestHeaders
        $response = Invoke-RestMethod -uri $Uri -Method POST -Headers $headers -Body $Definition -ResponseHeadersVariable resHeaders -StatusCodeVariable status
        Write-Host -ForegroundColor DarkYellow "Response: $status"
        return $response
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        Write-Error $_
        Exit 1
    }  
}

$endpointMap = @{
    "index" = "indexes"   
    "datasource" = "datasources"
    "indexer" = "indexers" 
}

$endpoint = $endpointMap[$ResourceType.ToLower()]

$apiVersionParam = "api-version=$APIVersion "#2020-06-30"
$serviceUri = [string]::Format("https://{0}.search.windows.net/$($endpoint)", $ServiceName)

$definition = $null

#try to read content of given file
if (TryGet-FileContent -FilePath $DefinitionFile -Content ([ref]$definition)) {
    if($ResourceType.ToLower() -eq "datasource") {
        $definition = $definition.Replace('%COSMOS_DB%', $env:COSMOS_DB)
    }
        
    $resource = Write-Output $definition | ConvertFrom-Json -Depth 15
    
    $response = $null
    # check if index exists -- if it exists we'll perform a PUT vs POST
            
    if (Assert-ResourceExists -Uri "$serviceUri/$($resource.name)?$apiVersionParam" -ServiceName $serviceName) {
        Write-Host -ForegroundColor DarkYellow "Resource $($resource.name) already exists, proceeding with update!"
        $response = Update-AzSearchResource -Uri "$($serviceUri)/$(resource.name)?$apiVersionParam" -Definition $definition
    }
    else {
        Write-Host -ForegroundColor DarkYellow "Resource $($resource.name) does not exists, creating!"
        $response = New-AzSearchResource -Uri "$($serviceUri)?$apiVersionParam" -Definition $definition
    }
}
    
ConvertTo-Json -InputObject $response -Depth 5
