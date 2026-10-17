param(
    [Parameter(Mandatory=$true)][string]$GameDirectory,
    [string]$ContentDirectory,
    [ValidateSet('UT99NetworkAPIAudit','UT99CoreFormatAudit')]
    [string]$AuditPackage='UT99NetworkAPIAudit',
    [switch]$ModernEngineAPIs
)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$game=(Resolve-Path -LiteralPath $GameDirectory).Path
if(!$ContentDirectory) { $ContentDirectory=$GameDirectory }
$content=(Resolve-Path -LiteralPath $ContentDirectory).Path
$folder=if($AuditPackage -eq 'UT99CoreFormatAudit') { 'core_format_audit' } else { 'network_api_audit' }
$stage=Join-Path $project ('build/'+$folder.Replace('_','-'))
$system=Join-Path $stage 'System'
$classes=Join-Path $stage ($AuditPackage+'/Classes')
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
Copy-Item -Path (Join-Path $PSScriptRoot ($folder+'/Classes/*.uc')) -Destination $classes -Force
if($AuditPackage -eq 'UT99CoreFormatAudit' -and !$ModernEngineAPIs) {
    # Keep the Core-only fixture loadable with the original Engine/Core packages.
    foreach($name in @('RegistryProbe','RegistryAudit','EngineFunctionsCommandlet','EngineGameAudit')) {
        $modernClass=Join-Path $classes ($name+'.uc')
        if(Test-Path -LiteralPath $modernClass) { Remove-Item -LiteralPath $modernClass }
    }
}
$ini="[Core.System]`r`nPaths=../System/*.u`r`n"
$ini+='Paths='+(Join-Path $content 'System/*.u').Replace('\','/')+"`r`n"
foreach($pair in @(@('Maps','unr'),@('Textures','utx'),@('Sounds','uax'),@('Music','umx'))) {
    $ini+='Paths='+(Join-Path $content ($pair[0]+'/*.'+$pair[1])).Replace('\','/')+"`r`n"
}
$ini+="[Engine.Engine]`r`nEditorEngine=Editor.EditorEngine`r`n[Editor.EditorEngine]`r`n"
foreach($name in @('Core','Engine','Fire','IpDrv','UnrealShare','UnrealI','Botpack',$AuditPackage)) {
    $ini+="EditPackages=$name`r`n"
}
[IO.File]::WriteAllText((Join-Path $system 'NetworkAPIAudit.ini'),$ini,[Text.Encoding]::UTF8)
if($AuditPackage -eq 'UT99CoreFormatAudit') {
    Copy-Item -LiteralPath (Join-Path $project 'tools/core_format_audit/CoreFormatFixture.ini') -Destination $system -Force
    Copy-Item -LiteralPath (Join-Path $project 'tools/core_format_audit/RegistryFixture_Settings.int') -Destination $system -Force
}
$package=Join-Path $system ($AuditPackage+'.u')
if(Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package }
Push-Location $system
try {
    # The fixture deliberately imports post-436 APIs. Approve only these known
    # compiler compatibility warnings; this does not change the source game.
    ("Y`n" * 128) | & '.\UCC.exe' Editor.MakeCommandlet ini=NetworkAPIAudit.ini
    if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $package)) { throw 'Network API fixture compilation failed. Use a recent UT compiler.' }
} finally { Pop-Location }
Write-Host "Network API fixture: $package"
