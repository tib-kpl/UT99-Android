param(
    [Parameter(Mandatory=$true)][string]$GameDirectory
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$stage = Join-Path $project 'build/console-menu'
$game = (Resolve-Path -LiteralPath $GameDirectory).Path
if (!(Test-Path -LiteralPath (Join-Path $game 'System/UCC.exe'))) {
    throw 'Provide an Unreal Tournament v400 directory containing System/UCC.exe.'
}
New-Item -ItemType Directory -Force (Join-Path $stage 'System'), (Join-Path $stage 'UT99ConsoleMenu/Classes') | Out-Null
Copy-Item -Path (Join-Path $game 'System/*') -Destination (Join-Path $stage 'System') -Recurse -Force
foreach ($folder in @('Textures', 'Sounds', 'Music')) {
    if (!(Test-Path -LiteralPath (Join-Path $stage $folder))) {
        Copy-Item -LiteralPath (Join-Path $game $folder) -Destination $stage -Recurse
    }
}
Copy-Item -Path (Join-Path $project 'app/src/main/assets/ut99_patches/System/UMenu.u'), (Join-Path $project 'app/src/main/assets/ut99_patches/System/UTMenu.u') -Destination (Join-Path $stage 'System') -Force
Copy-Item -Path (Join-Path $project 'app/src/main/console_menu/Classes/*.uc') -Destination (Join-Path $stage 'UT99ConsoleMenu/Classes') -Force
$ini = Get-Content -LiteralPath (Join-Path $stage 'System/UnrealTournament.ini') -Raw
$ini = $ini.Replace('EditPackages=UTBrowser', "EditPackages=UTBrowser`r`nEditPackages=UT99ConsoleMenu")
Set-Content -LiteralPath (Join-Path $stage 'System/ConsoleMenu.ini') -Value $ini -Encoding ASCII
$output = Join-Path $stage 'System/UT99ConsoleMenu.u'
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output }
Push-Location (Join-Path $stage 'System')
try {
    & '.\UCC.exe' make ini=ConsoleMenu.ini
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $output)) { throw 'UnrealScript compilation failed.' }
} finally { Pop-Location }
$bytes = [IO.File]::ReadAllBytes($output)
if ([BitConverter]::ToUInt16($bytes, 4) -ne 68) {
    throw 'Package is not v400 (version 68). Use the matching v400 compiler.'
}
Copy-Item -LiteralPath $output -Destination (Join-Path $project 'app/src/main/assets/ut99_patches/System/UT99ConsoleMenu.u') -Force
