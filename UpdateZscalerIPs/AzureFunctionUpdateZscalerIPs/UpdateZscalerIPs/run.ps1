# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Get Application Setting Variables
$subscriptionId = $env:SubscriptionId
$resourceGroupName = $env:ResourceGroupName
$workspaceName = $env:workspaceName
$resourceURI = $env:resourceURI
$ZscalerTenant = $env:ZscalerTenant
$watchlistAlias = $env:watchlistAlias


# Prepare Variables
$configUri = "https://api.config.zscaler.com/$ZscalerTenant/cenr/json"
$ZscalerData = @()

# Fetch Zscaler JSON Data
Write-Host "Fetching Zscaler Data from $configUri"
$jsonData = Invoke-RestMethod -Uri $configUri

# Validate Data
if ($jsonData.PSObject.Properties.Name -eq $ZscalerTenant) {
    Write-Host "Received Zscaler Data"
} else {
    Write-Host "Problem Receiving Zscaler Data.  Exiting..."
    exit
}

# Loop Through JSON Data to build objects
$jsonData.PSObject.Properties | ForEach-Object {
    $rootName = $_.Name
    $_.Value.PSObject.Properties | ForEach-Object {
        $continentName = $_.Name.replace("continent : ", "")
        $_.Value.PSObject.Properties | ForEach-Object {
            $cityName = $_.Name.replace("city : ", "")
            $_.Value | ForEach-Object {
                $object = [PSCustomObject]@{
                    Tenant = $rootName
                    Continent = $continentName
                    City = $cityName
                    Range = $_.Range
                    VPN = $_.VPN
                    GRE = $_.GRE
                    Hostname = $_.Hostname
                    Latitude = $_.Latitude
                    Longitude = $_.Longitude
                }
                $ZscalerData += $object
            }
        }
    }
}

Write-Host "Received $($ZscalerData.Count) records"


$rawContent = ""
foreach ($prop in ($ZscalerData[0].PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty" })) {
    if ($rawContent -eq "") {
        $rawContent += $prop.Name
    } else {
        $rawContent += ",$($prop.Name)"
    }
}
$rawContent += "`r`n"

foreach ($object in $ZscalerData) {
    $rawContent += "$($object.Tenant),$($object.Continent),$($object.City),$($object.Range),$($object.VPN),$($object.GRE),$($object.Hostname),$($object.Latitude),$($object.Longitude)`r`n"
}

Write-Host "Converted Data to Raw Content"



$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

$requestHeaders = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

$body = @{
    "properties" = @{
        "displayName" = $watchlistAlias
        "provider" = "Microsoft"
        "source" = "Local file"
        "itemsSearchKey" = "City"
        "rawContent" = "$rawContent"
        "contentType" = "Text/csv"
        "numberOfLinesToSkip" = 0
    }
}
$body = $body | ConvertTo-Json



$uri = "https://management.azure.com/subscriptions/" + $subscriptionId + "/resourceGroups/" + $resourceGroupName + "/providers/Microsoft.OperationalInsights/workspaces/" + $workspaceName + "/providers/Microsoft.SecurityInsights/watchlists/" + $watchlistAlias + "?api-version=2021-03-01-preview"
Invoke-RestMethod -Method Delete -Headers $requestHeaders -Uri $Uri
Write-Host "Deleted existing Watchlist"


Invoke-RestMethod -Method Put -Headers $requestHeaders -Body $body -Uri $Uri
Write-Host "Created new Watchlist"





# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"