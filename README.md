# Kanca

**Kancanı tavana at, sarkaç gibi salın, tam zamanında bırak ve momentumla fırla —
bölümü en kısa sürede bitir.**

Hız odaklı 2B sallanma platform oyunu. Godot 4.7.2, GL Compatibility,
640×360 taban çözünürlük. Tema: **fırtınalı gökyüzü adaları**.

Durum: **v0.3 — rakip analizinden gelen oynanış turu.** 14 bölüm, gerçek pixel
art, ses ve müzik, ayarlar ekranı, madalyalar, hayalet tekrarı, kontrol noktaları;
üstüne puanlamalı hedefleme, kancada tampon + kojot, halat pompası, bırakma
bonusu, ileri bakan kamera, tek parmak dokunmatik şeması, tuş atama, rota ipucu
ve ustalık zinciri.

![Menü](docs/ekran/menu.png)
![13. bölüm](docs/ekran/bolum_13.png)

## Kontroller

| İş | Klavye / Fare | Gamepad |
|---|---|---|
| Koş / salınımı büyüt | `A` `D` veya `←` `→` | Sol çubuk, D-pad |
| Zıpla (kancalıyken: kopar + fırla) | `Boşluk` | `A` |
| Nişan al | Fare | Sağ çubuk |
| Kancayı at (basılı tut) / bırak | `Sol tık` | `RB` |
| Halatı kısalt / uzat | `W` `S` veya `↑` `↓` | D-pad yukarı/aşağı |
| Bölümü yeniden başla | `R` | `X` |
| Duraklat | `Esc` | `Start` |

Klavye atamaları **Ayarlar → Tuş atama** ekranından değiştirilir; fare ve gamepad
atamaları olduğu gibi kalır.

Nişan yoksa (fare hareketsiz, çubuk boşta) kanca, bakış yönündeki en uygun
noktaya gider. Seçili aday nokta beyaz halkayla vurgulanır ve araya **kesik
çizgi** çekilir, bağlı olan altın rengi yanar, **menzil dışındakiler grileşir**.

### Tek parmak şeması (mobil)

Mobilde otomatik açılır, masaüstünde **Ayarlar → Tek parmak şeması** ile denenir.

| Hareket | Sonuç |
|---|---|
| Koşu | Otomatik (ileri). Sallanırken pompalama da otomatik. |
| Dokun | Hedef varsa kanca atılır, yoksa yerdeyken zıplanır. |
| Parmağı kaldır | Halat bırakılır (fırlama bonusu geçerli). |
| Basılıyken dikey kaydır | Halatı kısaltır / uzatır. |

Nişan, parmağın ekranda bulunduğu noktaya bakar.

## Oynanış

- **Hedefleme puanlanır.** Menzildeki her kanca noktası için
  `puan = nişan hizası × 3 − uzaklık / menzil + hız yönüne uyum`; arada katı zemin
  varsa (ışın testi) nokta aday sayılmaz. Yani hızla sağa uçarken sağdaki nokta,
  aynı hizadaki soldakini yener — kritik anda kanca boşa gitmez.
  Nişan yardımının genişliği **Ayarlar → Nişan** kaydıracıyla ayarlanır
  (sol uç: geniş yardım, sağ uç: tam nişan).
- **Tampon + kojot-kanca.** Basış 0,12 sn saklanır: o sırada hedef belirirse
  kanca yine de takılır. Hedef menzilden yeni çıktıysa 0,12 sn daha tutulabilir.
- **Halat pompası.** Gergin halatı kısaltmak açı momentumunu korur — yayın
  dibinde kısaltmak hız kazandırır (Worms ninja halatı ustalığı).
  `POMPA_VERIMI` ile yumuşatılmıştır, hız tavanı yine `AZAMI_HIZ`.
- **Bırakma bonusu.** `BIRAKMA_ESIGI` (380 px/sn) üstünde bırakırsan
  `BIRAKMA_CARPANI` (×1,10) + altın parçacık + `firla` sesi; altında hıza
  hiç dokunulmaz. Doğru anda bırakmak artık duyuluyor ve görülüyor.
- **İleri bakan kamera.** Kamera hız yönüne kayar (en çok 84 px) ve yüksek hızda
  görüntü %9'a kadar genişler — nereye uçtuğun önceden görünür.
- **Ustalık zinciri ("Akış").** Yere değmeden art arda taktığın her kanca zinciri
  uzatır; sol üstte `Akış ×N` görünür, bölüm sonunda en uzun zincir süreden ayrı
  not olarak yazılır ve kaydedilir.
- **Rota ipucu.** Bir bölümde altın madalya kazandıktan sonra, bot rotasının
  kullandığı kanca noktaları altın tonda işaretlenir. Ayarlardan kapatılabilir.
- **Kanca anında takılmaz.** Sol tıkta halat uçmaya başlar, `KANCA_UCUS_SURESI`
  (55 ms ≈ 3 kare) sonra tutunur; tutunma anında küçük sarsıntı + ses var.
  Atışın bir ağırlığı olsun diye gerçek bir gecikme, ama tepkiyi bozmayacak kadar kısa.
- **Momentum senden geri alınmaz.** Bırakınca hıza dokunulmaz (yalnız küçük bir
  `BIRAKMA_CARPANI` bonusu). Hızlıyken arkanda hız izi çizilir.
- **Ölüm** = çukur, diken veya tavan dikeni. Kontrol noktası varsa oradan devam
  edersin ama **sayaç durmaz** — ölmek yine de süre kaybıdır.
- **Madalya:** her bölümün altın/gümüş/bronz hedef süresi var (ms hassasiyetinde,
  bot koşusundan üretilmiş — aşağıya bak); oyun içinde sol üstte altın hedefi,
  bitişte kazanılan madalya, Bölüm Seç ekranında bölüm başına madalya rozeti görünür.
- **Hayalet:** bir bölümü yeni rekorla bitirdiğinde koşun kaydedilir ve sonraki
  denemede yarı saydam hayalet olarak yanında oynar. Ayarlardan kapatılabilir.

### Bölüm öğeleri

| Öğe | Görünüm | Davranış |
|---|---|---|
| Sabit kanca noktası | gri halka | Yerinde durur. |
| Hareketli kanca noktası | camgöbeği halka | İki uç arasında gidip gelir; halat çapası da hareket eder. |
| Kırılgan kanca noktası | mor halka, çatlak kaya | Bir kez tutulur; bıraktığın an yanıp söner ve kırılır. |
| Rüzgâr / itici alan | mavi perde + akan çizgiler | İçindeyken sürekli ivme uygular. Halatı bırakıp akıntıya girmek en hızlı yol. |
| Diken / tavan dikeni | kırmızı testere | Değince ölüm. Tavan dikenleri halatı kısa tutmayı zorunlu kılar. |
| Kontrol noktası | direk + halka (yeşilken aktif) | Ölünce buradan devam; süre durmaz. |

## Bölümler

| # | Ad | Tanıttığı / kısayolu |
|---|---|---|
| 1 | İlk Tutuş | Öğretici: nişan al, tut, bırak. Üstteki yüksek nokta tek salınışta boşluğu geçirir. |
| 2 | Halat Boyu | Öğretici: halatı kısalt/uzat. Kısaltıp savurursan orta platforma hiç inmezsin. |
| 3 | Diken Tarlası | Diken = ölüm. Tek uzun salınımla tarlanın tamamı atlanır. |
| 4 | Uçurum | Üst hat zincirinde iki uçurum birden geçilir. |
| 5 | Yukarı | Yükselen platformlar; üst kanca hattı platformlara hiç değmeden taşır. |
| 6 | Sallanan Kayalar | **Hareketli nokta.** Nokta sana doğru gelirken tutarsan salınım bedava büyür. |
| 7 | Dar Geçit | Alçak tavan; halatı asgariye indirip tam tur atmak çıkışta yüksek hız verir. |
| 8 | Tek Kullanımlık | **Kırılgan nokta.** Duraklama; zinciri baştan planla. Alttaki sabit hat da çalışır ama yavaştır. |
| 9 | Rüzgâr | **İtici alan.** İlk akıntıya yatay girersen kanca atmadan karşıya taşınırsın. |
| 10 | Dikenli Tavan | **Tavan dikeni.** Halatı 28 px'e indirip alçaktan geçmek en hızlı yol. |
| 11 | Hız | En uzun düz bölüm, **kontrol noktalı**. y=64 sırası hiç yere inmeden bitişe gider. |
| 12 | Kırık Sarkaç | Hareketli + kırılgan bir arada. |
| 13 | Fırtına | Rüzgâr + tavan dikeni. Akıntıya alçaktan gir, halatı uzatma. |
| 14 | Final | Hepsinin karışımı, iki kontrol noktası. |

## Nasıl çalıştırılır

Godot'u **her zaman kilitle** çalıştır (aynı anda 3 oyun oturumu olabilir):

```powershell
# Oyunu çalıştır
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --path . --scene res://scenes/menu.tscn

# Testler (çıkış kodu 0 = hepsi geçti, 99 = zaman aşımı)
powershell -ExecutionPolicy Bypass -File tests\calistir.ps1

# Her şey sırayla: varlık üretimi + import + test + ölçüm + ekran + dışa aktarma
powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1
```

Ayrıntı ve tuzaklar: `CLAUDE.md`.

## Kod düzeni

| Dosya | Ne yapar |
|---|---|
| `scripts/ayarlar.gd` | **Tüm ayarlanabilir sabitler.** Oynanış hissi buradan ayarlanır. |
| `scripts/palet.gd` | Tek palet (Endesga 32 alt kümesi). Her renk buradan gelir. |
| `scripts/oyuncu.gd` | Koş/zıpla, halat kısıtlı sarkaç, kanca uçuşu, esneme-sıkışma, hız izi. |
| `scripts/kanca_noktasi.gd` | Kanca noktası: sabit / hareketli / kırılgan. |
| `scripts/karo_seti.gd` | `karo.png` üzerinden TileSet'i kodla kurar (ayrı `.tres` yok). |
| `scripts/bolumler.gd` | 14 bölümün tamamının verisi + madalya eşiği seçimi + karo hizalama + görüş hattı. |
| `scripts/rota_verisi.gd` | **Üretilmiş** — `tools/rota.gd`'nin yazdığı bot süreleri, madalya eşikleri ve rotalar. |
| `scripts/tuslar.gd` | Tuş atama: kayıttaki özel tuşları `InputMap`'e uygular. |
| `scripts/tus_dugmesi.gd` | Ayarlardaki tek eylemlik tus yakalama düğmesi. |
| `scripts/bolum.gd` | Bölümü veriden kurar; süre, ölüm, kontrol noktası, madalya, hayalet, parçacık, sarsıntı, arayüz. |
| `scripts/hayalet.gd` | En iyi koşunun yarı saydam tekrarı. |
| `scripts/menu.gd` | Ana menü + bölüm seçme + ayarlar. |
| `scripts/kayit.gd` | `user://kayit.cfg` — ilerleme, en iyi süreler, ayarlar. Hayaletler `user://hayalet_NN.dat`. |
| `scripts/ses.gd` | `Muzik` / `Efekt` veri yolları, efekt havuzu, döngülü müzik. |
| `scripts/gecis.gd` | Sahne geçişi (kararma → değiştir → açılma). |

Autoload sırası: `Ayarlar`, `Kayit`, `Ses`, `Gecis`.

## Varlıklar kodla üretilir

GUI aracı kullanılamadığı için **bütün sprite'lar ve sesler betikle üretiliyor**.
Çıktılar deterministik: aynı tohum, aynı PNG.

```powershell
# Sprite'lar (+ docs/sprite_onizleme.png — 4x büyütülmüş kontrol sayfası)
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/sprite_uret.gd

# Ses efektleri (rFXGen ham dosyalarından)
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . -s res://tools/ses_uret.gd
```

- `tools/sprite_uret.gd` — oyuncu (10 kare), karo seti, kanca noktaları, diken,
  bayrak, kontrol noktası, madalya, logo, parçacık, rüzgâr çizgisi ve
  3 parallaks arka plan katmanı.
- `tools/ses_uret.gd` + `tools/sesler.md` — 12 efekt, reçete tablosu dosyada.
- `tools/muzik_uret.gd` — chiptune döngü (oyun `hizli`, menü `sakin`).

Oyuncu sprite'ı ASCII haritalarla yazılıyor (üst gövde + bacak blokları ayrı,
kareler bunların birleşimi) — bir pozu değiştirmek birkaç satır düzenlemek demek.

### Palet

Endesga 32'den 18 renk (`scripts/palet.gd`). Tema kararı: kaya ve gökyüzü soğuk
gri-mavi, yosun yeşil, **oyuncu turuncu** — arka plandan ve zeminden net ayrışsın
diye. Tehlike kırmızı, rüzgâr camgöbeği, hiçbir başka öğe bu iki rengi kullanmıyor.

## Sallanma sabitleri nasıl seçildi

`tools/olcum.gd` botla ölçüm yapar: sarkacı "iyi oyuncu" gibi pompalar (her karede
teğetsel hızın işaretine basar) ve üç tarama üretir. Sonuçlar
`raporlar/2026-09-16-kanca-gelistirme-1.md` içinde tam tabloyla.

Seçilen değerler (`scripts/ayarlar.gd`):

| Sabit | Değer | Neden |
|---|---|---|
| `SALLANMA_IVMESI` | 1250 | 500 px/sn'ye ~1,2 sn'de çıkıyor — iki salınımda hız hissi var, üçüncüde tavan. |
| `SALLANMA_SONUMU` | **0,10** | v0.3'te sert halat kısıtı enerji kaçağını kapattı: aynı sayı artık çok daha az sönüm demek (girdisiz 4 sn sonra kalan enerji 0,05'te %71 → %86). 0,10 v0.2'nin amaçladığı %70 bandını geri veriyor, 500 px/sn'ye ulaşma maliyeti 0,03 sn. |
| `SALLANMA_YERCEKIMI` | 1,30 | Salınım periyodu 2,52 → 2,20 sn (tepede asılı kalma gidiyor), 500 px/sn'ye hâlâ bir salınımda çıkılıyor. 1,50+ hız kurmayı belirgin yavaşlatıyor. |
| `BIRAKMA_CARPANI` | 1,10 | Bırakma sonrası uçuş bir bölüm boşluğunu (≈300–380 px) rahat kapatıyor. |
| `KANCA_MENZIL` | 240 | 14 bölümde nokta başına ortalama komşu sayısı makul; kopuk nokta yok. |

Bu dördü bilerek `const` değil `var` — ölçüm botu çalışma anında tarayabilsin diye.
**İnsan testi hâlâ yapılmadı**; bot "geçilebilir ve hızlanabilir" diyor, "iyi
hissettiriyor" demiyor.

## Madalya süreleri nasıl üretildi

v0.2'de eşikler bölüm uzunluğundan formülle hesaplanıyordu ve gerçek bir koşuyla
doğrulanmamıştı. v0.3'te `tools/rota.gd` bunu ölçüme çeviriyor:

1. **Plan.** Her bölümün kanca noktalarından graf kurulur (kenar = zincir menzili
   içinde *ve* arada katı zemin yok), başlangıçtan bitişe en düşük maliyetli
   zincir Dijkstra ile bulunur.
2. **Koşu.** Bot bu rotayı **gerçek fizikle** oynar: hedefe kanca atar,
   salınımı pompalar, hız yönü bir sonraki noktaya döndüğünde ve `BIRAKMA_ESIGI`
   aşıldığında bırakır. Her karar anına 0,05–0,20 sn arası rastgele tepki
   gecikmesi eklenir (Neon White'ın "geliştirici kendi oyununda fazla iyi"
   sorununa karşı aynı çözüm).
3. **Eşik.** Bölüm başına 5 koşu; altın = ortanca × 1,25, gümüş × 1,70,
   bronz × 2,30, **ms hassasiyetinde**. Botu birebir hedef yapmak
   (× 1,08) Neon White'ın düştüğü tuzak olurdu — bot hiçbir kancayı kaçırmaz.

Ölçüm üç kuralla gürültüden temizlenir: en iyinin 1,5 katından kötü koşular
(kaçırılan kanca, ölüm) ortancaya girmez; ölçek bölüm oranlarının **ortancası**
alınır; ölçeğin 2 katından yavaş kalan bölüm de tahmine devredilir.

Süre kare sayısından hesaplanır (kare / 60), gerçek zamandan değil — headless'ta
`_process` deltası gerçek zamana bağlı, fizik karesi ise sabit.

```powershell
powershell -ExecutionPolicy Bypass -File tools\kilitli.ps1 -- --headless --path . --scene res://tools/rota.tscn
```

Çıktı `scripts/rota_verisi.gd` (üretilmiş dosya, elle düzenleme).
`Bolumler.madalya_esikleri()` üretilmiş değeri tercih eder, yoksa tablodaki
yedek değere düşer. Aynı veri **rota ipucunu** da besler.

**Bot 14 bölümün 5'ini bitirebiliyor** (1, 2, 4, 6, 8). Kalan 9 bölümün süresi,
bitirdiklerinden ölçülen rota hızından (sn/px) türetilir ve kayıtta
`"tahmin": true` ile işaretlenir (`RotaVerisi.tahmin_mi()`).

Bot tam bir insan oyuncu değil: halat pompasını kullanmıyor ve rotayı
değiştirmiyor. Yani altın eşiği iyi bir oyuncu için ulaşılabilir, mükemmel
oyuncu için bolca pay bırakır.

**`--fixed-fps 60` şart:** headless'ta bile fizik kareleri gerçek zamanda akar
(60 Hz), yani 2700 karelik bir koşu gerçekten 45 saniye sürer. Bayrak zamanı
gerçek saatten koparır; ölçüm kare sayısından geldiği için sonuç değişmez.

## Ses

`Muzik` ve `Efekt` iki ayrı veri yolu; ses düzeyi **oynatıcıya değil veri yoluna**
yazılıyor (`AudioServer.set_bus_volume_db`). Efekt perdeleri dosyaya pişirilmiş.

**Neden:** Godot'un web dışa aktarması varsayılan olarak Sample yolunu kullanıyor;
orada `pitch_scale` ve `volume_db` sessizce yok sayılıyor, döngü güvenilmez oluyor —
ve masaüstünde test ederek hiçbiri görünmüyor. `project.godot` içinde
`general/default_playback_type.web=2` (Stream) ve `driver/mix_rate.web=48000`
var; müzik döngüsü ayrıca `finished` sinyalinde elle yeniden başlatılıyor.

## Testler

`tests/test_kanca.gd` headless çalışır, çıkış koduyla bildirir:

- Menzil dışına takılmaz, menzil içine takılır.
- **Kanca aynı karede takılmaz**, ~3 kare sonra tutunur (uçuş süresi).
- Takılıyken oyuncu–nokta mesafesi 320 karelik simülasyonda halat boyunu aşmaz.
- Bırakınca yatay hız sıfırlanmaz, sonraki 30 karede de korunur.
- **Kırılgan nokta** bir kez tutulur, sonra kullanılamaz.
- **Hareketli nokta** iki uç arasında kalır (taşmıyor).
- **Rüzgâr alanı** oyuncuyu yönünde hızlandırıyor.
- 14 bölüm sahnesi yüklenir; her birinde başlangıç, bitiş, TileMapLayer karoları
  ve veri tablosuyla aynı sayıda kanca noktası var.
- **Tüm zeminler 16 px karo ızgarasında** (veri ile oynanan dünya aynı yerde).
- **Madalya eşikleri** artan ve doğru sınıflandırıyor.
- **Hayalet kaydı** yazılıp geri okunuyor.
- **Her bölümdeki her boşluk kanca zinciriyle aşılabilir** (bölüm verisi bozulursa yakalar).
- **Hedefleme puanlaması:** hizalı uzak nokta hizasız yakını yener, eşit hizada
  yakın olan kazanır, hız yönündeki nokta seçilir.
- **Görüş hattı:** arada duvar varken kanca takılmaz, duvar kalkınca takılır.
- **Tampon ve kojot-kanca** pencereleri hem tutuyor hem zamanında kapanıyor.
- **Bırakma bonusu** yalnız eşik üstünde uygulanıyor.
- **Pompa:** halatı kısaltarak sallanan oyuncu, kısaltmayana göre belirgin hızlı.
- **İleri bakan kamera** hız yönüne kayıyor ve yüksek hızda uzaklaşıyor.
- **Tuş atama** `InputMap`'e yazılıyor, fare atamasını silmiyor, sıfırlanabiliyor.
- **Üretilmiş rota verisi** tutarlı: her adım gerçek bir kanca noktası, ardışık
  noktalar zincir menzilinde ve aralarında katı zemin yok; eşikler ms hassasiyetinde.

## Yayın paketi

`yayin/` — itch.io sayfa metni (İngilizce + Türkçe), 4 ekran görüntüsü (1280×720),
kapak (630×500), butler komutları. **Hiçbir şey yüklenmedi**, komutlar
çalıştırılmadı; karar Furki'nin.

Web yapısı tek iş parçacıklı (`thread_support=false`) — itch.io'da
**SharedArrayBuffer kutusu işaretlenmemeli**.

## Sonraki adımlar

`YOL-HARITASI.md`.
