# Kanca

**Kancanı tavana at, sarkaç gibi salın, tam zamanında bırak ve momentumla fırla —
bölümü en kısa sürede bitir.**

Hız odaklı 2B sallanma platform oyunu. Godot 4.7.2, GL Compatibility,
640×360 taban çözünürlük. Tema: **fırtınalı gökyüzü adaları**.

Durum: **v0.2 — yayına hazır ilk sürüm.** 14 bölüm, gerçek pixel art, ses ve
müzik, ayarlar ekranı, madalyalar, hayalet tekrarı, kontrol noktaları.

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

Nişan yoksa (fare hareketsiz, çubuk boşta) kanca, bakış yönündeki en uygun
noktaya gider. Menzildeki aday nokta beyaz halkayla vurgulanır, bağlı olan
altın rengi yanar.

## Oynanış

- **Kanca anında takılmaz.** Sol tıkta halat uçmaya başlar, `KANCA_UCUS_SURESI`
  (55 ms ≈ 3 kare) sonra tutunur; tutunma anında küçük sarsıntı + ses var.
  Atışın bir ağırlığı olsun diye gerçek bir gecikme, ama tepkiyi bozmayacak kadar kısa.
- **Momentum senden geri alınmaz.** Bırakınca hıza dokunulmaz (yalnız küçük bir
  `BIRAKMA_CARPANI` bonusu). Hızlıyken arkanda hız izi çizilir.
- **Ölüm** = çukur, diken veya tavan dikeni. Kontrol noktası varsa oradan devam
  edersin ama **sayaç durmaz** — ölmek yine de süre kaybıdır.
- **Madalya:** her bölümün altın/gümüş/bronz hedef süresi var; oyun içinde
  sol üstte altın hedefi, bitişte kazanılan madalya, Bölüm Seç ekranında
  bölüm başına madalya rozeti görünür.
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
| `scripts/bolumler.gd` | 14 bölümün tamamının verisi + madalya süreleri + karo hizalama. |
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
- `tools/ses_uret.gd` + `tools/sesler.md` — 10 efekt, reçete tablosu dosyada.
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
| `SALLANMA_SONUMU` | 0,05 | 0,02'de sarkaç hiç durmuyor (kontrolsüz), 0,15'te pompalama boşa gidiyor. |
| `BIRAKMA_CARPANI` | 1,10 | Bırakma sonrası uçuş bir bölüm boşluğunu (≈300–380 px) rahat kapatıyor. |
| `KANCA_MENZIL` | 240 | 14 bölümde nokta başına ortalama komşu sayısı makul; kopuk nokta yok. |

Bu dördü bilerek `const` değil `var` — ölçüm botu çalışma anında tarayabilsin diye.
**İnsan testi hâlâ yapılmadı**; bot "geçilebilir ve hızlanabilir" diyor, "iyi
hissettiriyor" demiyor.

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

## Yayın paketi

`yayin/` — itch.io sayfa metni (İngilizce + Türkçe), 4 ekran görüntüsü (1280×720),
kapak (630×500), butler komutları. **Hiçbir şey yüklenmedi**, komutlar
çalıştırılmadı; karar Furki'nin.

Web yapısı tek iş parçacıklı (`thread_support=false`) — itch.io'da
**SharedArrayBuffer kutusu işaretlenmemeli**.

## Sonraki adımlar

`YOL-HARITASI.md`.
