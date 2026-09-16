# Godot'u D:\Repolar\.godot-kilit kilidini alarak calistirir.
#   powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --import
# Cikti dosyaya da yazilir (son parametre olarak -Log verilmez; TEMP'e duser).
. "$PSScriptRoot\kilit.ps1"

# Yalniz ilk '--' atilir (PowerShell'in parametre ayraci);
# sonrakiler Godot'un betige arguman gecirme ayraci, korunmali.
$argListe = @($args)
if ($argListe.Count -gt 0 -and $argListe[0] -eq '--') {
  $argListe = @($argListe[1..($argListe.Count - 1)])
}

$log = Join-Path $env:TEMP 'kanca_godot.log'
$kod = Godot-Calistir $argListe $log
if (Test-Path $log) { Get-Content $log }
if (Test-Path "$log.err") { Get-Content "$log.err" }
Write-Output "EXIT=$kod"
exit $kod
