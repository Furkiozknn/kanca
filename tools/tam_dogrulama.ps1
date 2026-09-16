# Butun Godot adimlarini SIRAYLA ve KILIDI BIR KEZ ALARAK calistirir.
#   powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1
#   powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1 -Atla varlik,ekran
#
# Adimlar: varlik (sprite+ses) -> import -> rota -> test -> olcum -> ekran -> disa aktarma
# 'rota' madalya surelerini ve rota ipucunu uretir; testler bu veriyi kontrol
# ettigi icin testten ONCE calisir.
# Her adimin ciktisi $env:TEMP\kanca_<adim>.log dosyasina yazilir; ozet ekrana basilir.
param([string[]] $Atla = @())

# -File ile cagrildiginda "a,b,c" tek dize olarak baglaniyor; virgulden ayir.
$Atla = @($Atla | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\kilit.ps1"

$kok = Split-Path -Parent $PSScriptRoot
$sonuc = [ordered]@{}

function Adim {
  param([string] $Ad, [string[]] $ArgListe, [int] $ZamanAsimi = 600)
  if ($Atla -contains $Ad) { $sonuc[$Ad] = 'ATLANDI'; return }
  $log = Join-Path $env:TEMP "kanca_$Ad.log"
  Write-Host "--- $Ad ---"
  $kod = Godot-Calistir $ArgListe $log $ZamanAsimi -KilitDisarda
  $sonuc[$Ad] = "exit=$kod"
  if (Test-Path "$log.err") {
    $hata = Select-String -Path "$log.err" -Pattern 'SCRIPT ERROR|Parse Error|ERROR:' -ErrorAction SilentlyContinue
    if ($hata) { $sonuc[$Ad] += " (hata satiri: $($hata.Count))" }
  }
  Write-Host "    exit=$kod  log=$log"
}

Kilit-Al
try {
  Adim 'varlik_sprite' @('--headless', '--path', $kok, '-s', 'res://tools/sprite_uret.gd')
  Adim 'varlik_ses'    @('--headless', '--path', $kok, '-s', 'res://tools/ses_uret.gd')
  Adim 'import'        @('--headless', '--path', $kok, '--import')
  # --fixed-fps: fizik kareleri gercek zamandan koparilir, yoksa bot kosusu
  # bolum basina ~4 dakika surer (bkz. tools/rota.gd basligi).
  Adim 'rota'          @('--headless', '--fixed-fps', '60', '--path', $kok, '--scene', 'res://tools/rota.tscn') 900
  Adim 'test'          @('--headless', '--path', $kok, '--scene', 'res://tests/test_kanca.tscn') 300
  Adim 'olcum'         @('--headless', '--path', $kok, '--scene', 'res://tools/olcum.tscn') 900
  Adim 'ekran'         @('--path', $kok, '--scene', 'res://tests/ekran.tscn') 300
  # On ayar adlarinda bosluk var; Start-Process -ArgumentList dizi elemanlarini
  # tirnaklamadan birlestiriyor, bu yuzden tirnaklar elle konuyor.
  Adim 'export_win'    @('--headless', '--path', $kok, '--export-release', '"Windows Masaustu"', 'build/windows/kanca.exe')
  Adim 'export_web'    @('--headless', '--path', $kok, '--export-release', '"Web (HTML5)"', 'build/web/index.html')
} finally {
  Kilit-Birak
}

Write-Host ''
Write-Host '=== OZET ==='
foreach ($k in $sonuc.Keys) { Write-Host ("{0,-14} {1}" -f $k, $sonuc[$k]) }
