param([Parameter(Mandatory=$true)][string]$GameDirectory)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$game=(Resolve-Path -LiteralPath $GameDirectory).Path
$stage=Join-Path $project 'build/physics-audit'
$system=Join-Path $stage 'System'
$classes=Join-Path $stage 'UT99PhysicsAudit/Classes'
New-Item -ItemType Directory -Force $system,$classes | Out-Null
Get-ChildItem -LiteralPath $classes -Filter '*.uc' -File | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
Get-ChildItem -LiteralPath (Join-Path $game 'System') -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $system $_.Name) -Force
}
Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'physics_audit/Classes') -Filter '*.uc' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $classes $_.Name) -Force
}
$header=[IO.File]::ReadAllBytes((Join-Path $system 'Core.u'))
if([BitConverter]::ToUInt16($header,4) -ne 68) { throw 'Use a matching v400 compiler and Core package.' }
$ini=[IO.File]::ReadAllText((Join-Path $system 'UnrealTournament.ini'))
$paths=foreach($pair in @(@('Maps','unr'),@('Textures','utx'),@('Sounds','uax'),@('Music','umx'))) {
    'Paths='+(Join-Path $game ($pair[0]+'/*.'+$pair[1])).Replace('\','/')
}
$ini=$ini.Replace('[Core.System]',"[Core.System]`r`n"+($paths -join "`r`n"))
$ini+="`r`n[Editor.EditorEngine]`r`nEditPackages=UT99PhysicsAudit`r`n"
[IO.File]::WriteAllText((Join-Path $system 'PhysicsAudit.ini'),$ini,[Text.Encoding]::Default)
$package=Join-Path $system 'UT99PhysicsAudit.u'
if(Test-Path -LiteralPath $package) { Remove-Item -LiteralPath $package }
Push-Location $system
try {
    & '.\UCC.exe' make ini=PhysicsAudit.ini
    if($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $package)) { throw 'Physics fixture compilation failed.' }
} finally { Pop-Location }
Write-Host "Physics fixtures: $package"
