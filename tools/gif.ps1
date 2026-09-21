# Tanitim GIF'i: tools/gif.tscn kareleri yazar (kilitle, headless DEGIL),
# ffmpeg bunlari yayin/tanitim.gif yapar.
#   powershell -ExecutionPolicy Bypass -File tools\gif.ps1
# ffmpeg: winget kurulumu PATH'e ekler (%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe).
$ErrorActionPreference = 'Continue'
. "$PSScriptRoot\kilit.ps1"

$kok = Split-Path -Parent $PSScriptRoot
$log = Join-Path $env:TEMP 'kanca_gif.log'

# Eski kareler kalmasin: kisa bir kosu eski karelerle karisir.
$kareKlasor = Join-Path $kok 'build\gif'
if (Test-Path $kareKlasor) { Remove-Item (Join-Path $kareKlasor 'kare_*.png') -Force -ErrorAction SilentlyContinue }

$kod = Godot-Calistir @('--path', $kok, '--scene', 'res://tools/gif.tscn') $log 120
if (Test-Path $log) { Get-Content $log }
if (Test-Path "$log.err") { Get-Content "$log.err" }
# Start-Process'in ExitCode'u bu ortamda bos donuyor (tam_dogrulama'da da
# "exit=" bos); basari, senaryonun son asamaya (2 = birakti, ucuyor) ulastigini
# yazan satirdan ve karelerin varligindan okunur.
$bitti = (Test-Path $log) -and (Select-String -Path $log -Pattern 'asama 2' -Quiet)
if (-not $bitti -or -not (Test-Path (Join-Path $kareKlasor 'kare_000.png'))) {
  Write-Output "GIF senaryosu bitmedi (log: $log)"; exit 1
}

$kareler = Join-Path $kok 'build\gif\kare_%03d.png'
$cikti = Join-Path $kok 'yayin\tanitim.gif'
# Pixel art: titreme (dither) yok, 128 renk yeter; palet tum karelerden.
$filtre = 'split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=none:diff_mode=rectangle'
& ffmpeg -y -loglevel error -framerate 20 -i $kareler -vf $filtre -loop 0 $cikti
if ($LASTEXITCODE -ne 0) { Write-Output "ffmpeg EXIT=$LASTEXITCODE"; exit $LASTEXITCODE }
$boyut = (Get-Item $cikti).Length
Write-Output ("GIF hazir: {0} ({1:N0} bayt)" -f $cikti, $boyut)
