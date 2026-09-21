# Sesler nasıl üretildi

İki adım: rFXGen'den 7 ham ön ayar, sonra `tools/ses_uret.gd` ile 12 oyun efekti.

## 1. Ham ön ayarlar

rFXGen komut satırı **deterministik** — aynı ön ayar her çalıştırmada birebir
aynı dosyayı üretiyor. Bu yüzden "4-6 aday üret, en iyisini seç" yolu işe
yaramadı; onun yerine 7 ham sesi alıp kodla işledik.

```powershell
$rfx = '<rFXGen kurulumunun yolu>\rfxgen.exe'   # yerel kurulum, depoda degil
foreach ($on in @('coin','laser','explosion','powerup','hit','jump','blip')) {
  & $rfx --generate $on --output "assets\audio\_ham\$on.wav" --format 22050,16,1
}
```

## 2. Oyun efektleri

```powershell
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/ses_uret.gd
```

`tools/ses_uret.gd` içindeki `RECETE` tablosu: her efekt için kaynak ön ayar,
perde, kazanç ve azami süre. Perde ve kırpma **dosyaya pişirilir**, çalma anında
`pitch_scale` kullanılmaz — Godot'un web dışa aktarması varsayılan Sample
yolunda `pitch_scale`'i sessizce yok sayıyor.

| Efekt | Ham | Perde | Kazanç | Süre |
|---|---|---|---|---|
| `kanca_at` | laser | 1,45 | 0,55 | 0,22 sn |
| `kanca_tak` | hit | 1,10 | 0,85 | 0,13 sn |
| `kanca_birak` | blip | 0,80 | 0,50 | 0,13 sn |
| `zipla` | jump | 1,15 | 0,65 | 0,26 sn |
| `olum` | explosion | 0,80 | 0,95 | 0,17 sn |
| `bitis` | powerup | 1,00 | 0,90 | 0,54 sn |
| `menu` | blip | 1,50 | 0,40 | 0,07 sn |
| `kontrol` | coin | 1,25 | 0,70 | 0,23 sn |
| `kirilma` | explosion | 1,75 | 0,65 | 0,08 sn |
| `madalya` | coin | 0,78 | 0,90 | 0,36 sn |
| `firla` | powerup | 1,70 | 0,55 | 0,20 sn |
| `akis` | coin | 1,60 | 0,45 | 0,16 sn |

`firla` eşik üstü hızda bırakmanın ödülü (v0.3), `akis` ustalık zinciri uzayınca çalar.

`hit` ve `explosion` ikişer efekte kaynaklık ediyor; ayrışma perde farkından
geliyor (`kanca_tak` tok, `kirilma` tiz ve kısa).

## 3. Müzik

```powershell
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav --ruh hizli --tohum 3
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik_menu.wav --ruh sakin --tohum 5
```

Oyun içi `hizli` (12,8 sn döngü), menü `sakin` (20,9 sn döngü). Beğenilmezse
yalnız `--tohum` değiştir.

Döngü web'de güvenilmez olduğu için `scripts/ses.gd` parça bitince `play()`
çağırıyor (`_muzik_bitti`).
