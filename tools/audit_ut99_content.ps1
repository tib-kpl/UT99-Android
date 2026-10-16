param(
    [Parameter(Mandatory=$true)][string]$EngineDirectory,
    [Parameter(Mandatory=$true)][string]$ContentDirectory,
    [string[]]$MapNames,
    [string]$StageDirectory
)
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
$engine = (Resolve-Path -LiteralPath $EngineDirectory).Path
$content = (Resolve-Path -LiteralPath $ContentDirectory).Path
if (!$StageDirectory) { $StageDirectory = Join-Path $project 'build/goty-content-audit' }
$stage = [IO.Path]::GetFullPath($StageDirectory)
$buildRoot = [IO.Path]::GetFullPath((Join-Path $project 'build')) + [IO.Path]::DirectorySeparatorChar
if (!$stage.StartsWith($buildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The audit stage must be inside this workspace build directory.'
}
foreach ($source in @($engine,$content)) {
    if ($stage.StartsWith($source + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'The audit stage must not be inside a source installation.'
    }
}
if (!(Test-Path -LiteralPath (Join-Path $engine 'System/UCC.exe'))) { throw 'Missing reference System/UCC.exe.' }
$system = Join-Path $stage 'System'
New-Item -ItemType Directory -Force $system | Out-Null
Get-ChildItem -LiteralPath (Join-Path $engine 'System') -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $system $_.Name) -Force
}
$ini = [IO.File]::ReadAllText((Join-Path $system 'UnrealTournament.ini'))
$paths = foreach ($pair in @(@('Maps','unr'),@('Textures','utx'),@('Sounds','uax'),@('Music','umx'))) {
    'Paths=' + (Join-Path $content ($pair[0] + '/*.' + $pair[1])).Replace('\','/')
}
$ini = $ini.Replace('[Core.System]', "[Core.System]`r`n" + ($paths -join "`r`n"))
$ini = [regex]::Replace($ini,'(?m)^Language=.*$','Language=int')
[IO.File]::WriteAllText((Join-Path $system 'ContentAudit.ini'),$ini,[Text.Encoding]::Default)
$maps = @(Get-ChildItem -LiteralPath (Join-Path $content 'Maps') -Filter '*.unr' -File | Sort-Object Name)
if ($MapNames) {
    $maps = @($maps | Where-Object { $MapNames -contains $_.Name })
    foreach ($name in $MapNames) {
        if (!($maps | Where-Object Name -EQ $name)) { throw "Map not found: $name" }
    }
}
$results = @()
Push-Location $system
try {
    foreach ($map in $maps) {
        $output = Join-Path $stage ('Export/' + $map.BaseName)
        $logName = 'Audit-' + $map.BaseName + '.log'
        $console = & '.\UCC.exe' batchexport $map.FullName Level t3d $output ini=ContentAudit.ini "log=$logName" 2>&1
        $code = $LASTEXITCODE
        $loaded = $code -eq 0 -and (Test-Path -LiteralPath (Join-Path $output 'MyLevel.t3d'))
        $results += [pscustomobject]@{Map=$map.Name; Loaded=$loaded; ExitCode=$code; Log=(Join-Path $system $logName)}
        Write-Host (("{0}/{1}: {2} {3}" -f $results.Count,$maps.Count,$map.Name,$loaded))
        if (!$loaded) { $console | Select-Object -Last 5 | Write-Host }
    }
} finally { Pop-Location }
$report = [pscustomobject]@{
    EngineDirectory=$engine
    ContentDirectory=$content
    Scope='Offline map load/export with reference System packages; not an Android rendering or gameplay test.'
    Results=$results
}
[IO.File]::WriteAllText((Join-Path $stage 'report.json'),($report | ConvertTo-Json -Depth 5),(New-Object Text.UTF8Encoding $false))
if ($results | Where-Object {!$_.Loaded}) { exit 1 }
