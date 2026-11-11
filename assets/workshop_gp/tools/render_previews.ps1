param(
    [Parameter(Mandatory=$true)][string]$GodotBinary,
    [Parameter(Mandatory=$true)][string]$PreviewProject,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$Boards
)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path -LiteralPath $PreviewProject).Path
$outputPath = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
$captureArgs = @('--path',$projectPath,'--rendering-method','gl_compatibility','--',"--capture-dir=$outputPath")
if ($Boards) {
    $captureArgs += "--board=$outputPath/OVERVIEW.png"
    $captureArgs += "--asset-board=$outputPath/ASSET_CATALOG.png"
}
# Quote paths with spaces for the Windows process command line.
$quotedArgs = $captureArgs | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }
$renderProcess = Start-Process -FilePath $GodotBinary -ArgumentList $quotedArgs -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput "$outputPath/render.log" -RedirectStandardError "$outputPath/render_error.log"
if ($renderProcess.ExitCode -ne 0) { throw "Godot capture failed: $($renderProcess.ExitCode)" }
$errors = Get-Content -LiteralPath "$outputPath/render_error.log" -Raw
if ($errors -match 'ERROR|SCRIPT ERROR') { throw $errors }
Get-Content -LiteralPath "$outputPath/render.log"
