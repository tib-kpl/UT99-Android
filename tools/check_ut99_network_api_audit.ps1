param([Parameter(Mandatory=$true)][string[]]$ClientLogs,[switch]$Network)
$ErrorActionPreference='Stop'
$checks=@('empty-hooks','empty-message','end-chain','restart-chain','pickup-out',
    'death-parameters','login-out','team-parameters','broadcast-out','localized-out',
    'pause-parameters','hud-key-base','message-window-field','hud-register-once')
if($Network) { $checks+= 'initial-event' }
foreach($file in $ClientLogs) {
    $text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $file))
    if($text -match 'NET_API FAIL|Critical:|Assertion failed|General protection fault') { throw "Audit failure: $file" }
    foreach($check in $checks) {
        $pattern='(?m)NET_API PASS '+[regex]::Escape($check)+'\r?$'
        if([regex]::Matches($text,$pattern).Count -ne 1) { throw "Expected one PASS for ${check}: $file" }
    }
    if($text -notmatch 'NET_API COMPLETE') { throw "Incomplete audit: $file" }
    Write-Host "PASS: $($checks.Count) API checks: $file"
}
