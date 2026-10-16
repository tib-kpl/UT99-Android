param(
    [Parameter(Mandatory=$true)][string]$CompatibleGameDirectory,
    [Parameter(Mandatory=$true)][string]$GotyDirectory,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
$base = (Resolve-Path -LiteralPath $CompatibleGameDirectory).Path
$goty = (Resolve-Path -LiteralPath $GotyDirectory).Path
$output = [IO.Path]::GetFullPath($OutputDirectory)
foreach ($source in @($base,$goty)) {
    if ($output.Equals($source,[StringComparison]::OrdinalIgnoreCase) -or
        $output.StartsWith($source + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Choose a separate output directory outside both source installations.'
    }
}
if (Test-Path -LiteralPath $output) { throw 'The output directory must not already exist.' }

function Read-PackageVersion([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    try {
        $header = New-Object byte[] 8
        if ($stream.Read($header,0,8) -ne 8 -or [BitConverter]::ToUInt32($header,0) -ne 0x9E2A83C1L) {
            throw "Invalid Unreal package: $Path"
        }
        if ([BitConverter]::ToUInt16($header,6) -ne 0) { throw "Unsupported licensee format: $Path" }
        return [BitConverter]::ToUInt16($header,4)
    } finally { $stream.Dispose() }
}
foreach ($name in @('Core.u','Engine.u','Botpack.u')) {
    if ((Read-PackageVersion (Join-Path $base "System/$name")) -ne 68) {
        throw 'The compatible installation must contain matching v400 Core, Engine and Botpack packages.'
    }
}
# Validate every selected content package before creating the output.
$content = @()
foreach ($pair in @(@('Maps','unr'),@('Textures','utx'),@('Sounds','uax'),@('Music','umx'))) {
    $files = @(Get-ChildItem -LiteralPath (Join-Path $goty $pair[0]) -Filter ('*.'+$pair[1]) -File)
    if (!$files.Count) { throw "Missing GOTY content: $($pair[0])" }
    foreach ($file in $files) {
        $version = Read-PackageVersion $file.FullName
        if ($version -lt 60 -or $version -gt 69) { throw "Unsupported content version $version`: $($file.FullName)" }
        $content += [pscustomobject]@{Folder=$pair[0];Name=$file.Name;Path=$file.FullName;Version=$version}
    }
}
New-Item -ItemType Directory -Path $output | Out-Null
$system = Join-Path $output 'System'
New-Item -ItemType Directory -Path $system | Out-Null
Get-ChildItem -LiteralPath (Join-Path $base 'System') -File | Where-Object {
    $_.Extension -in @('.u','.ini','.int','.frt')
} | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $system $_.Name) }
# These scripts load with the Android compatibility runtime. Relics needs its
# HUD field extensions and PCM resampling; it does not load in unmodified v400.
# The remaining modern System packages require separate compatibility work.
foreach ($name in @('de','epiccustommodels','multimesh','relics')) {
    foreach ($extension in @('.u','.int','.frt')) {
        $file = Join-Path $goty ('System/'+$name+$extension)
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            Copy-Item -LiteralPath $file -Destination (Join-Path $system ($name+$extension)) -Force
        }
    }
}
# Recent installations keep registrations/translations outside System. Copy
# only the supported bonus packages and their skins, preserving the classic
# core/interface localization files.
foreach ($name in @('de','epiccustommodels','multimesh','relics','tnalimeshskins','tcowmeshskins','tskmskins')) {
    foreach ($language in @('int','frt')) {
        $filename=$name+'.'+$language
        foreach ($relative in @(('System/'+$filename),('SystemLocalized/'+$language+'/'+$filename))) {
            $file=Join-Path $goty $relative
            if (Test-Path -LiteralPath $file -PathType Leaf) {
                Copy-Item -LiteralPath $file -Destination (Join-Path $system $filename) -Force
            }
        }
    }
}
foreach ($folder in @('Maps','Textures','Sounds','Music')) { New-Item -ItemType Directory -Path (Join-Path $output $folder) | Out-Null }
foreach ($file in $content) { Copy-Item -LiteralPath $file.Path -Destination (Join-Path (Join-Path $output $file.Folder) $file.Name) }
$report = [pscustomobject]@{
    CompatibleSystem=$base
    GotyContent=$goty
    Scope='GOTY maps, textures, sounds and music with v400-compatible System packages. This does not install the OldUnreal 469 engine or all its script/gameplay changes.'
    AdditionalScriptPackages=@('de','epiccustommodels','multimesh','relics')
    RequiredAndroidFeatures=@('MutatorHUDFields','PCMResampling')
    Content=$content
}
[IO.File]::WriteAllText((Join-Path $output 'android-compatibility.json'),($report | ConvertTo-Json -Depth 4),(New-Object Text.UTF8Encoding $false))
Write-Host "Prepared $($content.Count) GOTY content packages in $output"
