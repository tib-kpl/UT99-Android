param([Parameter(Mandatory=$true)][string[]]$ClientLogs)
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'check_ut99_core_format_audit.ps1') -ClientLogs $ClientLogs
& (Join-Path $PSScriptRoot 'check_ut99_dynamic_array_audit.ps1') -ClientLogs $ClientLogs
$groups=@{
    STATIC_ARRAY=@('initial-empty','read-restores-extent','write-in-extent',
        'legacy-clamped-write','explicit-growth','shrink-and-restore')
    STRING_API=@('concat-self','space-empty-left','space-empty-right','remove-sensitive','remove-repeated')
    REGISTRY_API=@('objects','preferences-count','preferences-fields','properties-count',
        'property-text','property-flags','property-range','value-count','value-labels',
        'load-property','result-ownership')
    ENGINE_FONT=@('create-and-cache')
}
foreach($file in $ClientLogs) {
    $text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $file))
    if($text -match '(STATIC_ARRAY|STRING_API|REGISTRY_API|ENGINE_FONT) FAIL|Critical:|Assertion failed|General protection fault') {
        throw "Engine audit failure: $file"
    }
    foreach($group in $groups.Keys) {
        foreach($check in $groups[$group]) {
            $pattern='(?m)'+$group+' PASS '+[regex]::Escape($check)+'\r?$'
            if([regex]::Matches($text,$pattern).Count -ne 1) { throw "Expected one PASS for ${group}/${check}: $file" }
        }
    }
    foreach($group in @('STATIC_ARRAY','REGISTRY_API')) {
        if([regex]::Matches($text,'(?m)'+$group+' COMPLETE\r?$').Count -ne 1) { throw "Incomplete $group audit: $file" }
    }
    if([regex]::Matches($text,'(?m)ENGINE_GAME match-started\r?$').Count -ne 1) { throw "Game did not start: $file" }
    Write-Host "PASS: 54 Core/engine checks and match startup: $file"
}
