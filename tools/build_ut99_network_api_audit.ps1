param([Parameter(Mandatory=$true)][string]$GameDirectory)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$game=(Resolve-Path -LiteralPath $GameDirectory).Path
$stage=Join-Path $project 'build/network-api-audit'
$system=Join-Path $stage 'System'
$classes=Join-Path $stage 'UT99NetworkAPIAudit/Classes'
New-Item -ItemType Directory -Force $system,$classes | Out-Null
Get-ChildItem -LiteralPath (Join-Path $game 'System') -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $system $_.Name) -Force
}
$localized=Join-Path $game 'SystemLocalized/int'
if(Test-Path -LiteralPath $localized) {
    Get-ChildItem -LiteralPath $localized -Filter '*.int' -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $system $_.Name) -Force
    }
}
Copy-Item -Path (Join-Path $PSScriptRoot 'network_api_audit/Classes/*.uc') -Destination $classes -Force
$ini="[Core.System]`r`nPaths=../System/*.u`r`n"
foreach($pair in @(@('Maps','unr'),@('Textures','utx'),@('Sounds','uax'),@('Music','umx'))) {
    $ini+='Paths='+(Join-Path $game ($pair[0]+'/*.'+$pair[1])).Replace('\','/')+"`r`n"
}
$ini+="[Engine.Engine]`r`nEditorEngine=Editor.EditorEngine`r`n[Editor.EditorEngine]`r`n"
foreach($name in @('Core','Engine','Fire','IpDrv','UnrealShare','UnrealI','Botpack','UT99NetworkAPIAudit')) {
    $ini+="EditPackages=$name`r`n"
}
[IO.File]::WriteAllText((Join-Path $system 'NetworkAPIAudit.ini'),$ini,[Text.Encoding]::UTF8)
$package=Join-Path $system 'UT99NetworkAPIAudit.u'
if(Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package }
Push-Location $system
try {
    # The fixture deliberately imports post-436 APIs. Approve only these known
    # compiler compatibility warnings; this does not change the source game.
    "Y`nY`nY`nY`n" | & '.\UCC.exe' Editor.MakeCommandlet ini=NetworkAPIAudit.ini
    if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $package)) { throw 'Network API fixture compilation failed. Use a recent UT compiler.' }
} finally { Pop-Location }
Write-Host "Network API fixture: $package"
