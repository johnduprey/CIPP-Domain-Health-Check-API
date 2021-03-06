using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#$CheckOrchestrator = $true

if ($request.query.GUID) {
    $RunningGUID = $request.query.GUID
    $CacheFileName = '{0}.json' -f $RunningGUID

    if (Test-Path "Cache_DomainHealth\$($CacheFileName)" ) {
        $JSONOutput = Get-Content "Cache_DomainHealth\$($CacheFileName)" | ConvertFrom-Json
        #Write-Information $JSONOutput
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = $JSONOutput
            })
        try {
            Remove-Item "Cache_DomainHealth\$($CacheFileName)" -Force
        }
        catch {}
    }   
    else {
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = @{ Waiting = $true }
            })
    }
}
else {
    $RunningGUID = (New-Guid).Guid
    $CacheFileName = '{0}.json' -f $RunningGUID

    $OrchQueue = [PSCustomObject]@{
        CacheFileName = $CacheFileName
        Query         = $Request.Query
    }
    $OrchQueue | ConvertTo-Json | Out-File "Cache_DomainHealthQueue\$($CacheFileName)"
    Start-NewOrchestration -FunctionName 'DomainHealth_Orchestrator' -Input $OrchQueue
    

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @{ GUID = $RunningGUID }
        })
}
