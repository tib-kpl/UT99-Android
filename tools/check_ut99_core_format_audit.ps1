param([Parameter(Mandatory=$true)][string[]]$ClientLogs,[switch]$Legacy)
$ErrorActionPreference='Stop'
$groups=@{
    POINTER_API=@('construct-array-layout','null-text-roundtrip','numeric-address-rejected','setter-result')
    CORE_API=@('lowercase','replace-insensitive','replace-sensitive','replace-overlap',
        'replace-original-input','replace-delete','random-range','trace-enabled','trace-disabled',
        'default-null-object','config-read','config-not-live-value','config-missing-key',
        'config-reject-invalid','config-clear-key','config-preserve-other-key','config-clear-all','config-static-clear-key')
}
foreach($file in $ClientLogs) {
    $text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $file))
    if($text -match '(POINTER_API|CORE_API|LEGACY_PROPERTY) FAIL|Critical:|Assertion failed|General protection fault') { throw "Audit failure: $file" }
    foreach($group in $groups.Keys) {
        foreach($check in $groups[$group]) {
            $pattern='(?m)'+$group+' PASS '+[regex]::Escape($check)+'\r?$'
            if([regex]::Matches($text,$pattern).Count -ne 1) { throw "Expected one PASS for ${check}: $file" }
        }
        if([regex]::Matches($text,'(?m)'+$group+' COMPLETE\r?$').Count -ne 1) { throw "Incomplete $group audit: $file" }
    }
    if($text -notmatch 'UTrace: .*CoreFunctions.TraceProbe') { throw "Missing actual script trace: $file" }
    if($Legacy -and [regex]::Matches($text,'(?m)LEGACY_PROPERTY PASS void-setter\r?$').Count -ne 1) { throw "Missing v400 void-call test: $file" }
    Write-Host "PASS: 22 Core checks$(if($Legacy){' + v400 void caller'}): $file"
}
