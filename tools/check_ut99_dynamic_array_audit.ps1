param([Parameter(Mandatory=$true)][string[]]$ClientLogs)
$ErrorActionPreference='Stop'
$checks=@('self-copy','integer-edits-and-bounds','string-deep-copy-edit','struct-insert-zero',
    'struct-deep-copy-shrink','object-pointer-width','repeated-string-ownership',
    'invalid-string-write','overflow-size-rejected')
foreach($file in $ClientLogs) {
    $text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $file))
    if($text -match 'DYN_ARRAY FAIL|Critical:|Assertion failed|General protection fault') { throw "Audit failure: $file" }
    foreach($check in $checks) {
        $pattern='(?m)DYN_ARRAY PASS '+[regex]::Escape($check)+'\r?$'
        if([regex]::Matches($text,$pattern).Count -ne 1) { throw "Expected one PASS for ${check}: $file" }
    }
    if([regex]::Matches($text,'(?m)DYN_ARRAY COMPLETE\r?$').Count -ne 1) { throw "Incomplete array audit: $file" }
    Write-Host "PASS: 9 dynamic-array checks: $file"
}
