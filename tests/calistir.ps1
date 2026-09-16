# Cekirdek mekanik + bolum verisi testlerini headless calistirir.
# Kullanim:  powershell -ExecutionPolicy Bypass -File tests\calistir.ps1
# Cikis kodu 0 = hepsi gecti, n = kalan test sayisi, 99 = zaman asimi.
#
# Not: betik parse hatasi verirse Godot bos sahneyle sonsuza kadar calisir;
#      Godot-Calistir icindeki zaman asimi bunu asili kalmak yerine hataya cevirir.
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\..\tools\kilit.ps1"

$kok = Split-Path -Parent $PSScriptRoot
$log = Join-Path $env:TEMP 'kanca_testler.log'

$kod = Godot-Calistir @('--headless', '--path', $kok, '--scene', 'res://tests/test_kanca.tscn') $log 180
if (Test-Path $log) { Get-Content $log }
if (Test-Path "$log.err") { Get-Content "$log.err" }
Write-Output "EXIT=$kod"
exit $kod
