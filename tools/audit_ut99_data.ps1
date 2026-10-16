param(
    [Parameter(Mandatory=$true)][string]$ReferenceDirectory,
    [Parameter(Mandatory=$true)][string]$CandidateDirectory,
    [string[]]$MapNames = @('DM-Oblivion.unr'),
    [string]$OutputFile
)
$ErrorActionPreference = 'Stop'
$referenceRoot = (Resolve-Path -LiteralPath $ReferenceDirectory).Path
$candidateRoot = (Resolve-Path -LiteralPath $CandidateDirectory).Path

function Read-PackageHeader([string]$Path) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{ Path=$Path; Present=$false }
    }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $header = New-Object byte[] 8
        if ($stream.Read($header, 0, 8) -ne 8) { throw "Truncated package: $Path" }
        $length = $stream.Length
    } finally { $stream.Dispose() }
    [pscustomobject]@{
        Path=$Path
        Present=$true
        Length=$length
        ValidTag=([BitConverter]::ToUInt32($header, 0) -eq 0x9E2A83C1L)
        FileVersion=[BitConverter]::ToUInt16($header, 4)
        LicenseeVersion=[BitConverter]::ToUInt16($header, 6)
        SHA256=(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    }
}

$comparisons = foreach ($relative in @('System/Core.u', 'System/Engine.u', 'System/Botpack.u', 'System/UWindow.u', 'System/UMenu.u', 'System/UTMenu.u') + @($MapNames | ForEach-Object { 'Maps/' + $_ })) {
    $reference = Read-PackageHeader (Join-Path $referenceRoot $relative)
    $candidate = Read-PackageHeader (Join-Path $candidateRoot $relative)
    [pscustomobject]@{
        File=$relative
        Reference=$reference
        Candidate=$candidate
        Identical=($reference.Present -and $candidate.Present -and $reference.SHA256 -eq $candidate.SHA256)
    }
}
$report = [pscustomobject]@{
    ReferenceDirectory=$referenceRoot
    CandidateDirectory=$candidateRoot
    Comparisons=@($comparisons)
}
$json = $report | ConvertTo-Json -Depth 5
if ($OutputFile) { [IO.File]::WriteAllText($OutputFile, $json, (New-Object Text.UTF8Encoding $false)) }
else { $json }
