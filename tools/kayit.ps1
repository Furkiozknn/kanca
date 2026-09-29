# Ham oynanis kaydi (sosyal medya klibi): yazisiz, sessiz, dikey 1080x1920.
#   powershell -ExecutionPolicy Bypass -File tools\kayit.ps1 [-Cikti yol.mp4] [-Bolumler 2,3,4] [-Hata 3] [-Kes 70]
#
# Botun (tools/rota.gd --kayit) oynadigi bolumler --write-movie ile PNG dizisine
# yazilir (kilit alinir, Godot pencereli calisir); ffmpeg oyunu 1080 genislige
# olcekleyip tema zemin renginde 1080x1920 tuvalin ortasina koyar, H.264
# yuv420p +faststart, ses yok (-an). Arayuz katmani gizli, ekranda yazi yok.
#
# Bu bir BOT kaydidir: sure kare sayisindan gelir, tepki gecikmesi 0,05-0,20 sn
# (insan bandi); --hata bolumunde ilk kanca bilerek erken birakilir.
param(
  [string] $Cikti = 'D:\Claude Projeleri\sosyal\medya\oyunlar\kanca.mp4',
  [string] $Bolumler = '1,2,3,4,8,9,11,1',
  [int] $Hata = 3,
  [int] $Kes = 70      # >0: her bolum bu kadar kare sonra kesilir (gecis cesitliligi); 0 = bolum bitene kadar; son bolum her zaman bitene kadar (bolum sonu flasi)
)
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\kilit.ps1"

$kok = Split-Path -Parent $PSScriptRoot
# Yolda bosluk olabilir (Start-Process argumanlari tirnaklamiyor): proje klasorune girip '.' ver.
Set-Location $kok
$gecici = Join-Path $env:TEMP 'kanca_kayit'
if (Test-Path $gecici) { Remove-Item $gecici -Recurse -Force }
New-Item -ItemType Directory -Force $gecici | Out-Null
$log = Join-Path $env:TEMP 'kanca_kayit.log'

# Pencere 1280x720 (proje ayari) kaydedilir; ffmpeg 1080 genislige indirir (608 yuksek).
$kod = Godot-Calistir @('--path', '.', '--write-movie', (Join-Path $gecici 'kare.png'),
  '--fixed-fps', '60',
  '--scene', 'res://tools/rota.tscn', '--', '--kayit', $Bolumler, '--hata', "$Hata", '--kes', "$Kes") $log 300
if (Test-Path $log) { Get-Content $log }
$kareler = @(Get-ChildItem $gecici -Filter 'kare*.png')
if ($kareler.Count -lt 300) { Write-Output "KAYIT BASARISIZ: $($kareler.Count) kare"; exit 1 }
Write-Output "kare sayisi: $($kareler.Count)"

# Zemin rengi: Tema.MUREKKEP (#0d1218), bolum 1-7 gece temasi.
$klasor = Split-Path $Cikti
New-Item -ItemType Directory -Force $klasor | Out-Null
$filtre = 'scale=1080:608:flags=lanczos,pad=1080:1920:0:656:color=0x0d1218,format=yuv420p'
& ffmpeg -y -loglevel error -framerate 60 -i (Join-Path $gecici 'kare%08d.png') -vf $filtre `
  -r 30 -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart -an $Cikti
if ($LASTEXITCODE -ne 0) { Write-Output "ffmpeg EXIT=$LASTEXITCODE"; exit $LASTEXITCODE }
Write-Output ("KAYIT HAZIR: {0} ({1:N0} bayt)" -f $Cikti, (Get-Item $Cikti).Length)
