# Tasarım — arayüz yenilemesi

Hedef: oyunu açan biri **tanıtım videosundaki dünyayı** bulsun — aynı renkler,
aynı yazı karakteri, aynı hareket dili. Çekirdek mekanik (kanca, halat
sarkacı, tampon/kojot, 14 bölüm, madalya, hayalet, günlük meydan okuma, bot
doğrulaması) **değişmedi**: fizik, bölüm verisi ve `scripts/rota_verisi.gd`
aynı, `tools/rota.gd --denetle` 14/14 bölümün hâlâ bittiğini ve altın
eşiklerin geçerli kaldığını gösteriyor. Bulgular `docs/DENETIM.md`'de.

## 1. Videodan çıkarılan stil rehberi

Kaynak: `assets/sosyal/kanca-dikey.mp4` (1080×1920, 15 sn) kareleri (ffmpeg);
renkler 2×2 piksel örneklenerek alındı (29 Eylül 2026, sıkıştırma payı ±2):

| Öğe | Videoda ölçülen | Oyunda kullanılan |
|---|---|---|
| Pencere / sarkaç zemini | `#0d1218` | gece zemini `#0d1218`, kâğıt temasının bloğu |
| Üst şerit | `#22202a` | (kullanılmadı; menü rayı için `#8a8595`) |
| Kâğıt yüzey (0/14 kartı, "SALLAN") | `#edf2f1` | gece bloğu `#edf2f1`, kâğıt zemini, kart zemini |
| Turkuaz top (oyuncu) | `#2ec3b6` | oyuncu `#2ec3b6`, her temada |
| Turuncu iz / vurgu ("KANCA" bandı) | `#fba117` / `#ff9e1b` | iz, seçili kanca, sahne geçişi bandı `#ff9e1b` |
| Kesik tavan çizgisi | `#8a8595` | menü tavan rayı |
| Çapa (beyaz nokta) | `#ebeef5` | menü çapası, sabit kanca noktası (blok rengi) |
| "Tarayıcıda oyna" düğmesi | `#f0b459` | birincil düğme dolgusu (marka tabanındaki camgöbeği yerine videonun kendi CTA rengi) |

Videoda tehlike rengi yok; tehlike marka tabanından (`#e94f36`, diken).
Ödül sarısı (`#ffc21a`) yalnız madalya ve "YENİ REKOR" damgasında.

**Düz renk, gölgesiz, dış çizgisiz.** Bir sahnede zemin + blok, oyuncu
(turkuaz), turuncu vurgu ve kırmızı tehlike. Yazı: **Instrument Sans**
(gövde, başlık) + **JetBrains Mono** (köşe etiketleri, büyük harf, `01 / İLK
TUTUŞ` biçimi); ikisi de OFL, `assets/fonts/` içinde lisans metniyle. Videodaki
başlık yazısı Archivo benzeri geniş bir grotesk, mono etiketler IBM Plex Mono
benzeri; marka tabanı (Instrument Sans + JetBrains Mono) korundu, videoyla en yakın
eşleşmeler bunlar. `★ ✓ ⟳ ● ← →` bu yazı tiplerinde yok: her yazı tipinin yedeği
`simgeler.ttf`; `_test_tema` Türkçe harflerin ve simgelerin bulunduğunu
sınıyor.

### İki tema

| Tema | Zemin | Blok | Bölümler |
|---|---|---|---|
| Gece | `#0d1218` | `#edf2f1` | 1–7 |
| Kâğıt | `#edf2f1` | `#0d1218` | 8–14 |

Gece videonun sarkaç panelidir, kâğıt "0 / 14" ve "SALLAN" kartlarıdır. Yüksek
kontrast ayarı bu oyunda yok (kanca oyununda hiç olmamıştı); iki tema zaten
%15'in üstünde luminans farkına sahip.

### Şekil dili

| Öğe | Şekil |
|---|---|
| Oyuncu | 12×20 px hap (çarpışma kutusuyla aynı), turkuaz, tek gözlü; göz nişan yönüne bakar. |
| Blok | Düz dikdörtgen, blok rengi; karo dokusu yok (çarpışma `TileMapLayer`'da, çizim ayrı). |
| Diken | Her 16 px'te bir üçgen, `#e94f36`. |
| Sabit kanca | Dolu disk (videodaki çapanın aynısı). |
| Hareketli kanca | Disk + **turuncu halka**. |
| Kırılgan kanca | **Kesik halka** (sekiz yay). |
| Aday / bağlı kanca | Turuncuya döner, büyür. Menzil dışı: %28 opak. |
| Rota ipucu | Turkuaz halka (altın madalyadan sonra). |
| Rüzgâr | Blok renginde %6 perde + akan ince çizgiler. |
| Kontrol noktası | İnce direk + flama; pasif blok rengi %45, aktif turkuaz. |
| Bitiş | Yüksek direk + turuncu bayrak. |
| Halat | 1,5 px, blok rengi; iz turuncu. |
| Arka plan | Üç katman eğik uzun bant (doğrusal parallaks, blok renginde %2–3,2 opaklık). |

### Hareket dili

| Öğe | Süre | Yumuşatma |
|---|---|---|
| Menü öğeleri girişi | 220 ms, 40 ms arayla sırayla | ease-out cubic |
| Düğme basışı | 90 ms %96'ya küçülür, 120 ms geri | ease-out |
| Ekran geçişi | turuncu bant 260 ms örter, 200 ms açar | ease-out / ease-in cubic |
| Duraklat / bölüm sonu kartı | 180 ms alfa, 220 ms ölçek 0,96 → 1 | ease-out |
| Ölüm | 300 ms tehlike rengi flaş (alfa 0,34 → 0) | ease-out; **girdiyi kilitlemez** |
| İlk kanca ipucu | 6 sn sonra 400 ms'de solar | doğrusal |
| Oyuncu | iniş / sıçrama ezilmesi, adım sarkması, nefes (`Oyuncu._gorsel_guncelle`) | rehberin tek yaylanma istisnası |

## 2. Ekranlar

| Ekran | Sahne | İçerik |
|---|---|---|
| **Başlangıç** | `menu.tscn` | Büyük `OYNA` (birincil, ilk odak), altında ikincil `Bölüm Seç` · `Günün Bölümü` · `Ayarlar` (· `Çıkış` yalnız masaüstü). `KANCA.` başlığı (turuncu nokta = videonun kapanış karesi), **tek satır** kontrol yardımı, en altta mono bilgi: sıradaki bölüm, günün bölümü, ilerleme. Sol üstte `HIZ · 14 BÖLÜM`, sağ üstte dil düğmesi. Arka planda videodaki sarkaç (kesik tavan rayı, beyaz çapa, turkuaz top, turuncu iz) canlı oynar. |
| **Oyun içi HUD** | `bolum.gd` | Sol üst: `01 / İLK TUTUŞ` etiketi, büyük süre (mono), iki ve üstü zincirde `AKIŞ ×N`. Sağ üst: madalya + `EN İYİ`, `ALTIN` hedefi, masaüstünde tuş ipucu / dokunmatikte `Duraklat`. Etiketler zemin renginde %88 opak küçük rozette, yazı blok renginde: hem boşlukta hem blok önünde okunuyor. Alt orta: ipucu — yalnız o bölüm hiç bitirilmediyse. |
| **Duraklatma** | `bolum.gd` | Perde + koyu kart: **Devam** (birincil, ilk odak) · Bölümü baştan · Ayarlar · Menüye dön. `Esc`; dokunmatikte `Duraklat` düğmesi. |
| **Bölüm sonu** | `bolum.gd` | Kâğıt kart: `01 / İLK TUTUŞ`, büyük süre, sarı `YENİ REKOR` damgası (yalnız rekorda), madalya, `EN İYİ` + `AKIŞ ×N`, üç eşik. **Tekrar dene** ve **Sonraki bölüm** yan yana iki büyük düğme; altın madalya alınmadıysa ya da son bölümse birincil ve ilk odak *Tekrar dene*'de, altın alındıysa *Sonraki bölüm*'de. `R` / `Enter` / `Esc` kısayolları. Günlük kipte yalnız Tekrar dene. |
| **Ayarlar** | `ayar_panel.gd` | İki sütun. **SES VE GÖRÜNTÜ**: müzik, efekt (kaydırıcı + anahtar), **Dil** (Türkçe ⇄ English), tam ekran. **OYNANIŞ**: nişan, hayalet, sarsıntı, rota ipucu, tek parmak. Altta `Tuş atama` ve `Geri`. |
| **Bölüm Seç** | `menu.gd` | 5×3 ızgara (numara, ad, süre, madalya, akış rozeti), tek satır açıklama. `Kayıtları sıfırla` artık **iki adımlı**: ilk dokunuş "Emin misin? Tekrar dokun" der, 3 sn içinde ikincisi siler. |

### Önce / sonra

| Önce (v0.5.2) | Sonra |
|---|---|
| ![](tasarim/once-menu.png) | ![](ekran/menu_tr.png) |
| ![](tasarim/once-oyun.png) | ![](ekran/bolum_06.png) |
| ![](tasarim/once-ayarlar.png) | ![](ekran/ayarlar_tr.png) |
| ![](tasarim/once-bolum-sec.png) | ![](ekran/bolum_sec_tr.png) |
| ![](tasarim/once-duraklat.png) | ![](ekran/duraklat_tr.png) |
| ![](tasarim/once-bitis.png) | ![](ekran/bitis_tr.png) |

Kâğıt teması ve rüzgâr alanı:

![13. bölüm](ekran/bolum_13.png)
![9. bölüm](ekran/bolum_09.png)

İngilizce (tarayıcı dili Türkçe değilse varsayılan):

![menü](ekran/menu_en.png)
![duraklat](ekran/duraklat_en.png)
![bölüm sonu](ekran/bitis_en.png)

## 3. Uygulama

- **Tema**: `assets/tema.tres`, `gui/theme/custom` olarak bağlı; `tools/tema_uret.gd`
  üretiyor (`godot --headless --path . -s res://tools/tema_uret.gd`, sonra
  `--import`). Kaydırıcı tutamağı ve anahtar simgeleri de orada kodla çiziliyor
  (temaya gömülü, PNG yok). Tür varyasyonları: `Baslik`, `Govde`, `Etiket`,
  `EtiketKalin`, `KartBaslik/KartYazi/KartEtiket`, `Birincil`, `Kucuk`,
  `KartDugme`, `KartMetin`, `Perde`, `Rozet`, `Kagit`.
- **Renkler**: `scripts/tema.gd` (`Tema`): iki tema, bölüm → tema eşlemesi,
  kutu/etiket yardımcıları. Eski `palet.gd` (Endesga 32 alt kümesi) kaldırıldı.
- **Dünya çizimi**: hiç PNG yok. Blok, diken, kanca noktası, oyuncu, bayrak,
  madalya `_draw`/`Polygon2D` ile vektör (`scripts/cizim.gd`, `isaret.gd`,
  `kanca_noktasi.gd`, `oyuncu.gd`); her ölçekte keskin. Eski pixel-art sprite'lar ve
  üretici `_eski/` altında (`.gdignore` + dışa aktarma filtresi). Çarpışma
  `TileMapLayer`'da kaldı (`visible=false`; fizik görünürlüğe bağlı değil) —
  botun 14 bölümü aynı sonuçla bitirmesi bunun kanıtı.
- **Sahne geçişi**: `scripts/gecis.gd` + `assets/gecis.gdshader` (`Gecis.git`, `kapat`, `ac`, `acilis`, `ara`, `yanip_son`); ayrıntı §7.
- **Menü animasyonu**: `scripts/ui.gd` (`UI.sirayla_gir`, `UI.dugmeleri_bagla`).
- **TR/EN**: `scripts/ceviri.gd`. Kaynak dil Türkçe: `tr("Türkçe metin")`
  (static metotlarda `Ceviri.t`); İngilizce tablo `Ceviri.EN`. Varsayılan dil
  `OS.get_locale_language()` (web'de `navigator.language`): `tr` → Türkçe, değilse
  İngilizce. Menüde ve Ayarlar'da dil düğmesi; seçim `user://kayit.cfg` içinde
  **yeni** `ayarlar/dil` anahtarı, **eski anahtarlara dokunulmaz** (`sureler`,
  `akis`, `ilerleme`, `gunluk`, `tuslar`, hayaletler aynen; `_test_dil_kaydi` eski
  biçimli kaydı okuyup sürenin bozulmadığını sınıyor). Duraklat → Ayarlar'da dil
  değişince HUD ve kartlar anında yeniden kurulur, bölüm ve süre korunur.
  `_test_ceviri`: koddaki her `tr()` metni, her bölüm adı/ipucu, madalya, günlük
  değiştirici ve tuş adı İngilizce tabloda var mı, `%d %s` belirteçleri ceviride
  aynı mı.
- **Dikey telefon**: pencere dikeyse 4 sn "cihazını yatay çevir" kartı (`Gecis`).

## 4. Oynanış hissi — neden, ne ölçüldü

| Değişiklik | Neden | Ölçü |
|---|---|---|
| Kanca at / bırak, tuş/fare olayı geldiği anda uygulanır (`Oyuncu._input`); fizik adımı beklenmez. Fizik zaman çizelgesi aynı: durum şimdi değişir, konum sonraki adımda ilerler. Duraklatma ve dokunmatik yolu ayrı (fizik kapalıyken olay yok sayılır). Bot ve testler `Input.action_press` ile bastığı için bu yola girmez: **çözülebilirlik ölçümü ve `rota_verisi.gd` aynı**. | Ses, parçacık ve uçuş sayacı fizik adımına (60 Hz) bağlıydı. | `tools/his_olc.gd`, pencereli, vsync kapalı, 80 deneme × 2 koşu, olay → `kanca_koptu`: **ortalama 9,1 / 8,6 → 2,0 / 2,1 ms, %95 16,4 / 17,4 → 2,4 / 2,5 ms**. Tutunma ~60 ms → ~60 ms (uçuşun 55 ms'si bilinçli). 60 Hz vsync'te fark yok denecek kadar küçük: 16,5 → 15,8 ms (olay dağıtımı ve fizik aynı karede). |
| Menüde tek büyük `OYNA`, tek satır kontrol yardımı. | Denetim: beş eşit düğme + iki satır soluk yardım. | `_test_menu_akisi` (iki dilde: odak Oyna'da, yardım tek satır, ikincil 3 düğme). |
| İlk oyunda öğretme: ipucu yalnız o bölüm hiç bitirilmediyse görünür ve ilk kancadan 6 sn sonra solar; aday kanca turuncuya döner, kesik nişan çizgisi zaten vardı. | Denetim: ipucu bitirilmiş bölümde bile hep duruyordu. | `_test_ilk_oyun_ipucu`. |
| Bölüm sonu: birincil düğme duruma göre (altın değilse *Tekrar dene*, altınsa *Sonraki*); rekor damgası; `Enter` artık odaktaki düğmeye gidiyor (eskiden hep sonraki bölüme). | Hız oyununda asıl döngü tekrar; denetim: tekrar için fareye gitmek gerekiyordu. | `_test_bolum_sonu_karti` (dört durum). |
| Ölümde 0,22 sn'lik karartma yerine 0,30 sn tehlike rengi flaşı; girdiyi kilitlemez. | Karartma yeniden doğuşu gizlemiyordu; flaş "vurdun" diyor. | Görsel doğrulama (`kanit/kanca/sonra`), kayıt karelerinde. |
| Bölüm bitince 2 birim kamera sarsıntısı + turuncu parçacık; çeşitli renkler temaya bağlandı (iniz tozu blok renginde). | Tema tutarlılığı; bitiş geri bildirimi zayıftı. | Görsel. |
| Kayıt sıfırlama iki adımlı. | Tek tıkla ilerleme siliniyordu. | `_test_menu_akisi`. |

**Değişmeyenler (bilerek).** Kanca tamponu 0,12 sn, kanca kojotu 0,12 sn,
zıplama tamponu 0,12 sn, zıplama kojotu 0,12 sn: platform oyunlarındaki yaygın
aralıkta (0,08–0,15 sn); 240 px/sn'lik bir hızda kojot ≈29 px, 900 px/sn'de ≈108
px pay demek. Testler sınıyor ve `rota_verisi.gd` bu değerlerle ölçüldü;
değişirse bot eşikleri yeniden üretilmeli. **Bu değerler bir insanla
denenmedi**; bot ölçümü insan hissini kanıtlamaz. Atış uçuşu (55 ms) da
korundu: hem atışa ağırlık veriyor hem madalya süreleri ona göre ölçülü.

## 5. Performans ve boyut (önce / sonra)

Ölçüm: `tools/fps.gd` (gerçek render, Intel UHD, vsync kapalı, 90 kare ısınma +
600 kare, sağ tuş basılı, kanca 0,7 sn'de bir); web paketi `build/web_*`.
Makinede aynı anda birkaç Godot süreci çalıştığı için eski ve yeni yapı
**aralıklı** (A/B) beşer kez koşuldu, tabloda medyanlar var.

| | Önce (`687a67e`) | Sonra |
|---|---|---|
| Kare süresi, 10. bölüm (ort. / %99, medyan) | 3,71 ms / 14,27 ms (≈270 FPS) | 4,22 ms / 12,09 ms (≈237 FPS) |
| Kare süresi, 14. bölüm | 3,75 ms / 15,49 ms | 3,81 ms / 6,53 ms |
| `index.pck` | 473.128 bayt | 722.620 bayt (+249.492; dört yazı tipi + tema) |
| `index.wasm` | 39.514.754 bayt | 39.514.754 bayt (motor, aynı) |
| `index.js` | 279.815 bayt | 279.815 bayt |
| Toplam (pck+wasm+js) | 40.267.697 bayt | 40.517.189 bayt (+%0,62) |
| Test | 115 | 157 |

10. bölümde ortalama kare süresi %14 arttı (dünya artık her karede vektör
çiziliyor, HUD rozetleri, menüde canlı sarkaç); %99 kare süresi düştü. Hepsi
hedef 60 FPS'nin çok üstünde (vsync kapalı sınırsız FPS). Sessiz makinede ilk
koşu: 10. bölüm 2,68 ms → 3,0–3,4 ms.

## 6. Bilinen sınırlar

- Dikey telefonda oyun 16:9 şerit olarak kalır (oda kamerası kararı); yalnız
  yatay tutma uyarısı eklendi.
- Ekran görüntülerindeki ölçüm ve tarayıcı denetimi masaüstü Chromium'dadır;
  gerçek telefon, Safari ve Firefox denenmedi.
- Web konsolunda `Attachment has zero size` WebGL uyarıları var (eski yapıda da
  vardı); hata değil, kaynağı doğrulanmadı.
- 5. bölümün madalya eşiği hâlâ tahmin (README "Bilinen sınırlar").
- Kanca / kojot / tampon süreleri bir insanla denenmedi.
- Videodaki başlık yazı tipi (Archivo benzeri) oyunda yok; marka tabanı yazı
  tipi Instrument Sans kullanıldı.

## 7. Günlük video imkânlarından alınanlar

Ek istek (29 Eylül 2026): günlük videolarda kullanılan renk ve geçiş imkânları
oyuna da girdi. **Oyunun kendi kimliği ağır bastı:** kancanın tanıtım
videosundaki düz renk dünya (lacivert gece, kâğıt, turkuaz oyuncu, turuncu iz,
kırmızı diken) **değişmedi**; akış paletleri ve geçişler yalnız geçişlerde, süre
chip'inde ve rekor damgasında.

**Kaynaklar:** `sosyal/uret/tema.mjs` → `TEMALAR` (palet `akis.vurgular`, geçiş
havuzu `gecis`), `sosyal/uret/sahne.js` → `GECIS` (ailelerin hareketi),
`tema.mjs` okunurluk eşiği; canlı örnek `videolar/*/_yapim/kontak-*.jpg`.
Shader ve `Gecis` mantığı yercekimi-cevir referans uygulamasından (244fb12)
uyarlandı; paletler ve havuzlar kancanın dünyasına göre ayrıca seçildi.

| Oyun teması | Video teması | Vurgu renkleri (sırayla döner) | Geçiş havuzu |
|---|---|---|---|
| Gece (bölüm 1–7, menü) | **harita** (lacivert zemin, turuncu/kum/camgöbeği/nane) | `#ff9e1b` (oyunun turuncusu) `#62d6ff #ffd166 #7bf1a8 #ff9ebb` | itme, iris, glitch, zoom, bloklar (harita `itme/zoom`, neon `iris/glitch`, klasik `bloklar`) |
| Kâğıt (8–14) | **kâğıt** (risograf mürekkepleri) | `#c1121f #1f45c9 #13632f #6a1b9a #9a3a00` | perde, kararma, bloklar, itme (kâğıt `perde/yatay/kararma`, limon `bloklar`) |

Neden: gece dünyası videonun lacivert sarkaç paneli, harita teması aynı
lacivert+turuncu ruhta; ilk renk oyunun kendi turuncusu, yani eski turuncu bant
kimliği (`itme`) korunuyor. Açık/koyu uç renkler oyunun kâğıt/mürekkebi
(`#edf2f1`, `#0d1218`). Neon/arcade/fosfor/poster/uzay/klasik/limon paletleri
düz dünyayı boğacağı için alınmadı.

**Geçiş aileleri:** tek `canvas_item` shader'ı (GL Compatibility, ekran dokusu
yalnız glitch ve zoom'da okunur): iris, glitch (28 dilim, 30 Hz), bloklar (12x7
kare), itme, perde, flaş, kararma, zoom. Örtme 260 ms, açma 200 ms. Tür havuzu
sırayla gezilir, art arda tekrar yok (`Gecis.sec`).

| Yer | Ne oluyor |
|---|---|
| Menü açılışı | İlk açılışta iris ortadan açılır |
| Menü → bölüm, bölüm → sonraki, bölüm → menü | Havuzdan sıradaki aile; çıkılan bölümün teması. Eski turuncu bant yerine |
| Bölüm sonu | Tek flaş vuruşu; **yeni rekorda** "YENİ REKOR" damgası palet renginde döner (90 ms adım, dışa doğru genişleyip oturur) ve ödül sarısında durur |
| Oyun sonu (14. bölüm) | Kart iris ile ortadan açılır |
| Süre/skor sayacı | Kontrol noktasında ve zincir (AKIŞ) uzadıkça sol chip palet rengine adımla döner, 0,30 sn sonra normale; en çok ~3/sn |
| Duraklat | Perde ailesi açılır |
| Dil değişimi | Menüde ve Ayarlar'da glitch örtüsünün altında yeniden kurulur (`Gecis.ara`) |
| Ölüm | Tehlike flaşı aynı; sade kipte yok |

**Okunurluk:** yazı rengi vurgu üzerinde kodla seçilir (`Tema.yazi_rengi`).
Eşik 4,5:1; testte tüm paletler doğrulanıyor (ölçülen en düşük çift testin
çıktısında yazıyor). **Hareket azaltma:** Ayarlar'da yeni "Sade geçişler" ya da
tarayıcıda `prefers-reduced-motion` → geçiş anında, bekleme yok, chip/damga
animasyonu ve ölüm flaşı kapalı. Kayıtlı diğer ayarlara dokunulmadı.

**Performans (Intel UHD, `tools/fps.gd`, vsync kapalı, 10. bölüm):**

| | Önce | Sonra |
|---|---|---|
| Oynanış karesi | ort. 2,72 ms, %99 4,36 ms (368 FPS) | ort. 2,63 / 2,49 ms, %99 4,18 / 3,80 ms (iki koşu) |
| Geçiş süren kareler (`fps.gd 10 1600 gecis`, 11 geçiş) | yok | ort. 3,51 ms (285 FPS), %99 5,28 ms, en kötü 6,27 ms |

İlk çalıştırmada ilk geçişte shader derlemesi tek 153 ms kare yaptı (sürücü
önbelleğinden sonra kaybolur); menü açılışı bu maliyeti oyuna girmeden örtünün
altında öder. Geçişler `await` yalnız örtmede (260 ms, eski bantla aynı);
açma oyun akışını beklemez.

**Test:** `_test_gecis` (59 yeni doğrulama, 157 → 216): palet okunurluğu, havuz/tekrar,
shader, sekiz ailenin örtüp açması, süre, `ara`, hareket azaltma, ayar anahtarı,
chip vurgusu, duraklat perdesi, dil glitch'i, damga, oyun sonu iris, menü açılışı.
Çekirdek mekanik ve `rota_verisi.gd` değişmedi (`--denetle` 14/14).
Kanıt kareleri: `kanit/kanca/sonra/gecis_*.png`, `sayac_*.png` (`tests/ekran.tscn -- <klasor> gecis`).
Ham kayıt: `sosyal/medya/oyunlar/kanca.mp4` (`tools/kayit.ps1`, 16 sn).
