# Cekirdek mekanik testlerini headless calistirir.
# Kullanim:  powershell -ExecutionPolicy Bypass -File tests\calistir.ps1
# Cikis kodu 0 = hepsi gecti, n = kalan test sayisi.
#
# Not: godot.exe bir WinGet sembolik baglantisi; `& $godot` sonrasi
# $LASTEXITCODE bos kaliyor. Bu yuzden Start-Process -Wait -PassThru.
$godot = 'C:\Users\furki\AppData\Local\Microsoft\WinGet\Links\godot.exe'
$proje = Split-Path -Parent $PSScriptRoot

$p = Start-Process -FilePath $godot -NoNewWindow -Wait -PassThru `
  -ArgumentList '--headless', '--path', $proje, '--scene', 'res://tests/test_kanca.tscn'
Write-Output "EXIT=$($p.ExitCode)"
exit $p.ExitCode
