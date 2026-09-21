# Kanca — proje kuralları

Bu dosya her Claude oturumunda otomatik yüklenir. Kısa ve güncel tut.
Depo: `D:\Repolar\kanca` · Motor: **Godot 4.7.2** ·
Godot yolu: `C:\Users\furki\AppData\Local\Microsoft\WinGet\Links\godot.exe` (PATH'te `godot`).

## Değişmez teknik kararlar

- **Renderer: GL Compatibility.** Tümleşik Intel UHD hedefi. `gl_compatibility`
  hem masaüstü hem mobil için ayarlı; değiştirme.
- **Pixel art:** taban çözünürlük 640×360, pencere 1280×720, `stretch/mode=canvas_items`,
  `aspect=keep`, doku filtresi **nearest** (`default_texture_filter=0`),
  `snap_2d_transforms_to_pixel` ve `snap_2d_vertices_to_pixel` açık.
- **Karo boyutu 16 px.** Bütün bölüm geometrisi 16'nın katı (`Bolumler.karola()` zorlar).
- **Fizik 60 Hz.**
- **Metin dosyaları BOM'suz UTF-8.** Arayüz metni Türkçe; kod ve yorumlar ASCII
  (GDScript'te Türkçe karakter yok — dosya adları ve tanımlayıcılar ASCII kalsın).
- **Web ses tuzağı:** `project.godot` içindeki `[audio] general/default_playback_type.web=2`
  ve `driver/mix_rate.web=48000` satırlarını silme. Varsayılan Sample yolunda
  tarayıcıda `pitch_scale`, `volume_db` ve döngü sessizce bozulur. Ses düzeyi
  ayrıca oynatıcıya değil **veri yoluna** yazılır (`scripts/ses.gd`).
  Efekt perdeleri dosyaya pişirilmiştir (`tools/ses_uret.gd`).

## Klasör düzeni

| Yol | Ne var |
|---|---|
| `scripts/` | Oyun kodu. Autoload'lar: `Ayarlar`, `Kayit`, `Ses`, `Gecis` (bu sırayla). |
| `scripts/rota_verisi.gd` | **Üretilmiş** — `tools/rota.gd` yazar. Elle düzenleme. Madalya eşiği, rota ipucu ve **altın hayalet izi** bu dosyadan gelir. |
| `scripts/gunluk.gd` | Günlük meydan okuma: tarihten tohum → bölüm + değiştirici. |
| `scenes/` | `menu.tscn`, `oyuncu.tscn`, `bolumler/bolum_NN.tscn` (sadece `bolum_no` taşır). |
| `assets/sprites/` | **Üretilmiş** PNG'ler — elle düzenleme, `tools/sprite_uret.gd`'yi düzenle. |
| `assets/audio/` | **Üretilmiş** WAV'lar. `_ham/` rFXGen çıktısı, kök dizin işlenmiş efektler. |
| `tools/` | Varlık üretim ve çalıştırma betikleri. Dışa aktarmaya girmez. |
| `tests/` | Otomatik testler + ekran görüntüsü aracı. Dışa aktarmaya girmez. |
| `docs/` | Ekran görüntüleri, sprite önizleme. `.gdignore` var. |
| `yayin/` | itch.io paketi (sayfa metni, görseller, butler komutları). |
| `build/` | Dışa aktarma çıktısı, `.gitignore`'da. |

## Katman sırası (z_index)

Yeni bir şey eklerken bu sıraya uy — yanlış katman sessizce oyuncuyu zeminin
arkasında bırakır:

| z | Ne |
|---|---|
| CanvasLayer −10 | Gökyüzü degradesi (kameradan bağımsız) |
| −9 … −7 | Parallaks: uzak ada, bulut, yakın ada |
| CanvasLayer −1 | Fırtına rüzgâr çizgileri (ekran uzayında) |
| 1 | Zemin `TileMapLayer` |
| 2 | Diken, tavan dikeni, bayrak, kontrol noktası |
| 3 | Hayalet, rüzgâr alanı perdesi + parçacıkları |
| **4** | **Oyuncu** |
| 5 | Halat |
| 6 | Kanca noktası |
| 7 | Parçacıklar |

## Hayalet ve günlük meydan okuma

Hayalet iki kaynaktan gelebilir (`Kayit.ayar("hayalet_kip")`): `1` oyuncunun
kendi en iyi koşusu (`user://hayalet_NN.dat`), `2` **altın hayalet** — botun
koşusu (`RotaVerisi.iz()`), yalnız o bölümde altın madalya kazanıldıysa.
Örnekleme **10 Hz**, aradaki kareler doğrusal ara değerle. Örnekleme aralığı
kayıt dosyasına yazılıyor: `Hayalet.ARALIK` değişirse eski kayıtlar yanlış
hızda oynamasın (sürümsüz eski dosya yok sayılır).

Günlük meydan okuma ana ilerlemeden ayrı: `Gunluk.aktif` bayrağıyla açılır,
süre `[gunluk]` bölümüne yazılır, bölüm açmaz, en iyi süreyi ve hayaleti
bozmaz. Değiştirici **oyuncuya** uygulanır (`oyuncu.azami_halat`,
`oyuncu.sabit_ruzgar`) — `Ayarlar` autoload'ındaki global sabitlere yazmak
normal bölümlere sızardı.

## Madalya süreleri ve rota

Madalya eşikleri **elle yazılmaz**: `tools/rota.gd` her bölümü bot ile gerçek
fizikte koşar (rastgele tepki gecikmeleriyle) ve `scripts/rota_verisi.gd`
dosyasını üretir. `Bolumler.madalya_esikleri()` üretilmiş değeri tercih eder,
yoksa `Bolumler.VERI[...]["madalya"]` yedeğine düşer. Aynı veri rota ipucunu
(altın madalyadan sonra işaretlenen noktalar) da besler.

Bölüm geometrisini değiştirdiysen `rota` adımını **testten önce** çalıştır —
testler üretilmiş veriyi denetliyor.

Tanı kipi (`--scene res://tools/rota.tscn -- --tani 3`) tek bölüm koşar ve
dosyayı **yazmaz**; bot bir bölümde neden öldüğünü anlamanın en hızlı yolu.
Tam koşu deterministik (aynı kodla iki koşu birebir aynı sonucu verir) ama
tanı kipi süreç geçmişi farklı olduğu için aynı tohumla **farklı süre**
verebilir: tanı davranışı gösterir, süreyi değil. Boş makinede tam koşu
~15 sn, üç oyun oturumu aynı anda çalışırken ~8 dk.

## Denge sabitleri nerede

`scripts/ayarlar.gd` — **tek yer**. Sallanma dörtlüsü (`SALLANMA_IVMESI`,
`SALLANMA_SONUMU`, `BIRAKMA_CARPANI`, `KANCA_MENZIL`) bilerek `const` değil `var`:
`tools/olcum.gd` bunları tarayarak ölçüm yapabilsin diye. Bu yüzden başka bir
betikte `const X := Ayarlar.KANCA_MENZIL` yazma — parse hatası verir.

v0.3 ile eklenen `SALLANMA_YERCEKIMI` de aynı sebeple `var` (ölçüm botu tarıyor).
Hedefleme puanlaması (`NISAN_PUAN_*`), tampon/kojot süreleri, pompa verimi,
bırakma eşiği ve kamera ayarları da `ayarlar.gd` içinde.

Renkler `scripts/palet.gd` (Endesga 32 alt kümesi). Yeni renk eklemeden önce
paletteki bir rengi kullanmayı dene.

## Komutlar

Godot'u **her zaman** kilitle çalıştır (aynı anda 3 oyun oturumu olabilir, RAM dar):

```powershell
# Tek seferlik
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --import

# Testler (çıkış kodu 0 = hepsi geçti, 99 = zaman aşımı)
powershell -ExecutionPolicy Bypass -File tests\calistir.ps1

# Varlık üretimi (deterministik, her çalıştırmada aynı çıktı)
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/sprite_uret.gd
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/ses_uret.gd
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/muzik_uret.gd -- --cikti res://assets/audio/muzik.wav --ruh hizli --tohum 3

# Ölçüm botu (sallanma sabitlerini tarar)
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --scene res://tools/olcum.tscn

# Rota + madalya süreleri (scripts/rota_verisi.gd üretir) — TESTTEN ÖNCE
# --fixed-fps 60 şart: yoksa fizik gerçek zamanda akar, koşu saatlerce sürer.
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --fixed-fps 60 --path . --scene res://tools/rota.tscn

# Ekran görüntüleri (headless DEĞİL)
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --path . --scene res://tests/ekran.tscn

# Tanıtım GIF'i (headless DEĞİL): tools/gif.tscn kareleri build/gif/ altına yazar,
# ffmpeg yayin/tanitim.gif yapar (3,6 sn, 20 fps, 640x360)
powershell -ExecutionPolicy Bypass -File tools\gif.ps1

# Her şeyi sırayla (kilidi bir kez alır): varlık → import → test → ölçüm → ekran → dışa aktarma
powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1

# Bazı adımları atla
powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1 -Atla varlik_sprite,varlik_ses,olcum
```

Adım adları: `varlik_sprite`, `varlik_ses`, `import`, `rota`, `test`, `olcum`,
`ekran`, `export_win`, `export_web`. Her adımın çıktısı `%TEMP%\kanca_<adim>.log`.

### Kilit kuralı

`D:\Repolar\.godot-kilit`. `tools\kilit.ps1` içindeki `Kilit-Al`/`Kilit-Birak`
bunu yönetir: dolu ve 15 dk'dan yeniyse 30 sn bekler; sahibi `kanca` ise ve
hiç Godot süreci yoksa hemen devralır. **Godot'u kilitsiz çalıştırma.**
İş bitince kilit silinir; süreç öldürülürse elle sil.

## Tuzaklar (hepsi bu depoda yaşandı)

1. **`Select-Object -First N` native komut çıktısında asıyor.** Godot çıktısını
   dosyaya yönlendir, sonra oku.
2. **Yuvalanmış `Start-Process` stdout yönlendirmesini yutuyor.** Godot tek
   seviyeden çağrılmalı (`tools\kilit.ps1` bunu yapıyor).
3. **Betik parse hatası verirse Godot boş sahneyle sonsuza kadar çalışır.**
   Zaman aşımı olmadan test çalıştırma.
4. **TileSet:** `add_source()` **karoları oluşturmadan önce** çağrılmalı, yoksa
   `TileData` fizik katmanını göremez (`p_layer_id = 0 is out of bounds`).
5. **`set_anchors_preset()` tek başına offset ayarlamaz** — `set_anchors_and_offsets_preset()`
   kullan, yoksa menü kutuları sol üstte sıkışır.
6. **Yeni kurulan `Area2D` aynı karede bayat örtüşmeyi `body_entered` sayar.**
   `monitoring = false` ile kur, bir fizik karesi sonra aç (`_alanlari_ac`).
7. **Autoload sırası:** `Kayit`, `Ses`'ten önce yüklenir; `Kayit._ready()` içinden
   `Ses`'e dokunma.
8. **`Rect2.intersects_segment` Godot 4'te yok** (Godot 3'te vardı). Doğru parçası
   – dikdörtgen kesişimi için `Bolumler.kesisiyor()` (slab yöntemi) kullan.
9. **Headless'ta `_process` deltası gerçek zamandır**, fizik karesi değil. Bu
   yüzden bot süreyi `Bolum._sure`'den değil **fizik karesi sayısından** ölçer
   (`kare / 60`). Aynı sebeple `KancaNoktasi` hareketi `_physics_process`'e
   taşındı — yoksa headless'ta hareketli noktalar uçuyordu.
9b. **Headless fizik karesi gerçek zamanda akar** (60 Hz): `await physics_frame`
   ile 2700 kare beklemek gerçekten 45 saniye sürer. Uzun simülasyonları
   **`--fixed-fps 60`** ile çalıştır — zaman gerçek saatten kopar, ölçüm
   kare sayısından geldiği için sonuç değişmez. `tools/rota.gd` bunu şart koşuyor.
10. **`class_name` yeni dosyada tanımlıysa** o dosya bir kez import edilmeden
   (`--import`) diğer betiklerden görünmez: "Identifier not declared" parse
   hatası alırsın. Yeni bir `class_name` ekledikten sonra önce import et.
11. **Telefon tarayıcısında `OS.has_feature("mobile")` FALSE döner.** Web dışa
   aktarımı `web` + `web_android`/`web_ios` bildirir. Girdi şemasını tek yerden
   sor: **`Ayarlar.dokunmatik_mi()`** (oyuncu girdisi, menü yardımı, bölüm ipuçları
   ve HUD aynı işlevi okur). Testlerde `Ayarlar.dokunmatik_zorla` ile ezilir.
12. **`PackedVector2Array([...])` sabit ifade DEĞİL.** `const VERI := {...}`
   içinde kullanınca dosya parse edilmez ve `RotaVerisi` sınıfı hiç yüklenmez —
   hata mesajı "Nonexistent function 'madalya' in base 'GDScript'" gibi alakasız
   çıkar. Üretilmiş dosyaya **düz `Array`** yaz, okurken dönüştür
   (`RotaVerisi.iz()`). `Vector2(1, 2)` sabit ifadedir, sorun ondan değil.
13. **Üretilmiş dosyayı yazan araç, üretemediğinde dosyaya DOKUNMAMALI.**
   `tools/rota.gd` başarısız bir koşuda `rota_verisi.gd`'yi boşaltıyordu; bir
   kez de tanı kipi 13 bölümün verisini sildi. İkisi de kapatıldı (boş sonuç =
   yazma yok, tanı kipi = yazma yok).
14. **HUD metni dünya çiziminin önünde ama saydam.** Yeni bir HUD etiketini
   `Bolum._serit(...)` ile sar; yoksa bir kanca noktası sprite'ının üzerinde
   okunmaz olur (v0.3.1 web bulgusu).
15. **Ölümden sonra bölüm dünyayı yeniden kurar** (`_dunya.queue_free()`):
   kanca noktası düğümlerine tutulan referanslar serbest bırakılmış olur.
   Tipli parametreye (`n: Node2D`) serbest bırakılmış nesne geçince SCRIPT
   ERROR çıkar, çağıran coroutine ölür ve `quit()` hiç çağrılmaz — headless
   Godot **%100 CPU ile sonsuza kadar döner** (tuzak 3'ün çalışma zamanı
   hâli). Düğüm tutan bot/test kodu her karede `is_instance_valid` ile
   yeniden çözsün (`tools/rota.gd` `_dugum_bul`). Godot'u zaman aşımsız
   çalıştırma; `.log.err` dosyasına bak.
16. **Bırakma bonusu uçuşu %10 uzatır.** Balistik iniş tahmini
   (`_inise_uygun`) bırakma ANINDAKİ hızla değil, `Oyuncu.kanca_birak`'ın
   uygulayacağı bonuslu hızla (`_birakma_hizi`) yapılmalı; inişten sonraki
   durma mesafesi (`v²/2a`) de platforma sığmalı. İkisi de eksikken bot
   2. bölümde bayrağın ötesine inip kenardan aşağı koşuyordu.
17. **Tuş adı yazan her etiket `Ayarlar.kisayol(metin, tus)` üzerinden
   geçer.** Dokunmatikte ek düşer ("Geri" / "Tekrar dene"); tuş atama ekranı
   dokunmatikte hiç kurulmaz. `tests/test_kanca.gd` bütün ekranları tarayıp
   `Esc`, `(R)`, `Enter`, `W/S`, `Fare`… geçen etiket arıyor — yeni bir
   etikete tuş adını elle yazma.
18. **Gerçek bölüm sahnesi koşan her araç `Kayit.salt_okunur = true` ile
   başlar.** `Bolum._bitise_degdi` rekoru, hayaleti ve açılan bölümü
   oyuncunun `user://kayit.cfg`'sine yazar; bot v0.3'ten v0.5'e kadar
   oyuncunun "en iyi süreleri"ni sessizce ezdi, GIF aracı 1. bölümün
   hayaletini sildi. Testler henüz bu bayrağı kullanmıyor (hayalet dosyasını
   gerçekten yazıp okuyan test var) — 98/99 yuvaları ve günlük tohumu
   1999-01-01/02 kayda giriyor.

## Bu depoda yapılmayacaklar

- **Push yok, GitHub deposu yok, itch.io'ya yükleme yok.** Yayın paketi yalnız
  `yayin/` altında hazırlanır; yükleme kararı Furki'nin.
- **Silme yok.** Gereksiz dosyayı `_eski/` altına taşı.
- Başka oyun depolarına (`yercekimi-cevir`, `derin-kazi`, `tek-tus-kosu`) dokunma.
