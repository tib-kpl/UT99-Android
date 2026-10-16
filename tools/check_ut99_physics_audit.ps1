param([Parameter(Mandatory=$true)][string]$LogPath)
$ErrorActionPreference='Stop'
$log=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $LogPath).Path)
$rows=[regex]::Matches($log,'OBLIVION_WALL_AUDIT result[^\r\n]*progress=([\d.]+) distance=([\d.]+) stall=([\d.]+)')
$failed=@($rows | Where-Object { [double]$_.Groups[1].Value -lt [double]$_.Groups[2].Value-10 -or [double]$_.Groups[3].Value -gt 0.49 })
if($rows.Count -ne 192 -or $failed.Count -or $log.Contains('OBLIVION_WALL_AUDIT invalid-start') -or !$log.Contains('OBLIVION_WALL_AUDIT complete')) {
    $failed | ForEach-Object { Write-Host $_.Value }
    throw "Oblivion wall audit failed: $($rows.Count)/192 results; $($failed.Count) blocked or incomplete traversals."
}
Write-Host 'PASS: 192 Oblivion wall traversals.'
