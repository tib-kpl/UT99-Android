param(
    [Parameter(Mandatory=$true)][string]$ServerLog,
    [Parameter(Mandatory=$true)][string[]]$ClientLogs,
    [switch]$ColdDownloads,
    [switch]$WarmCache
)
$ErrorActionPreference='Stop'
if($ColdDownloads -and $WarmCache) { throw 'Choose either cold downloads or a warm cache.' }
$server=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $ServerLog).Path)
$maps=@('DM-DownloadAudit','DM-TravelAudit','DM-Oblivion')
$last=-1
for($stage=0; $stage -lt $maps.Count; $stage++) {
    $pattern='NETWORK_TRAVEL_SERVER PASS stage='+$stage+' map='+[regex]::Escape($maps[$stage])+' players=2 armed=2'
    $match=[regex]::Match($server,$pattern)
    if(!$match.Success -or $match.Index -le $last) { throw "Missing or unordered server stage $stage." }
    $last=$match.Index
}
if(!$server.Contains('NETWORK_TRAVEL_SERVER COMPLETE')) { throw 'The server did not complete the rotation.' }
if($ClientLogs.Count -lt 2) { throw 'Provide both client logs.' }
foreach($file in $ClientLogs) {
    $client=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $file).Path)
    $last=-1
    foreach($map in $maps) {
        $match=[regex]::Match($client,'NETWORK_TRAVEL_CLIENT PASS map='+[regex]::Escape($map)+' ')
        if(!$match.Success -or $match.Index -le $last) { throw "Missing or unordered client stage $map in $file." }
        $last=$match.Index
    }
    if($client -match 'Critical:|Assertion failed:') { throw "Native failure in $file." }
    if($WarmCache -and $client -match 'Android download: (HTTP start|file request)') {
        throw "Unexpected repeat download with a populated cache in $file."
    }
    if($ColdDownloads) {
        if(!$client.Contains('HTTP complete package=DM-TravelAudit')) { throw "Missing HTTP map download in $file." }
        $first=[regex]::Match($client,'file request package=noxxpack channel=(\d+)')
        $second=[regex]::Match($client,'file request package=xutfx channel=(\d+)')
        if(!$first.Success -or !$second.Success -or $first.Groups[1].Value -eq $second.Groups[1].Value) {
            throw "The two fallback downloads did not use distinct channels in $file."
        }
    }
}
Write-Host 'PASS: three server maps, both client HUDs/weapons, final opponent replication, and complete rotation.'
if($ColdDownloads) { Write-Host 'PASS: HTTP map download followed by two distinct fallback file channels on both clients.' }
if($WarmCache) { Write-Host 'PASS: no package download was repeated with populated caches.' }
