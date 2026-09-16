# Kanca

**Kancanı tavana at, sarkaç gibi salın, tam zamanında bırak ve momentumla fırla — bölümü en kısa sürede bitir.**

Hız odaklı 2D platform oyunu. Godot 4.7.2, GL Compatibility, 640×360 taban çözünürlük.
Şu an **oynanabilir çekirdek prototip**: ana mekanik çalışıyor, 8 bölüm var, baştan sona
oynanıp bitirilebiliyor. Görseller yer tutucu; gerçek pixel art, ses ve cila sonraki aşamada.

![Menü](docs/ekran/menu.png)
![1. bölüm](docs/ekran/bolum_01.png)

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

Nişan yoksa (fare hareketsiz, çubuk boşta) kanca, bakış yönündeki en uygun noktaya gider.
Menzildeki aday nokta beyaz halkayla vurgulanır, bağlı olan sarı yanar.

## Nasıl çalıştırılır

```powershell
# Editörde
godot --path .

# Çalıştır
godot --path . --scene res://scenes/menu.tscn

# Testler (çıkış kodu 0 = hepsi geçti)
powershell -ExecutionPolicy Bypass -File tests\calistir.ps1

# Ekran görüntüsü üret (headless DEĞİL)
godot --path . --scene res://tests/ekran.tscn
```

Hazır yapılar: `build/windows/kanca.exe` ve `build/web/index.html`
(web çıktısı tek iş parçacıklı — düz statik sunucuda, COOP/COEP başlığı olmadan çalışır).

## Kod düzeni

| Dosya | Ne yapar |
|---|---|
| `scripts/ayarlar.gd` | **Tüm ayarlanabilir sabitler** (hız, yerçekimi, kanca menzili, halat sınırları, renkler). Oynanış hissi buradan ayarlanır. |
| `scripts/oyuncu.gd` | Koş/zıpla (kojot süresi + zıplama tamponu) ve halat kısıtlı sarkaç fiziği. |
| `scripts/kanca_noktasi.gd` | Kanca noktası; `kanca_noktasi` grubunda, görseli kodla çizilir. |
| `scripts/bolumler.gd` | 8 bölümün tamamının verisi (zemin, diken, kanca noktaları, başlangıç, bitiş). |
| `scripts/bolum.gd` | Bölümü veriden kurar; süre, ölüm, bitiş, duraklatma, arayüz. |
| `scripts/menu.gd` | Ana menü + bölüm seçme. |
| `scripts/kayit.gd` | `user://kayit.cfg` — açılan bölümler ve en iyi süreler. |

### Neden bölümler TileMapLayer değil de veri?

8 bölümün tamamı `scripts/bolumler.gd` içinde elle yazılmış sabit bir tabloda duruyor;
`scenes/bolumler/bolum_NN.tscn` dosyaları yalnızca `bolum_no` taşıyor ve geometriyi
`bolum.gd` kuruyor. Sebep: bu turda bölümler hızlı ve topluca ayarlanabilmeli
(bir boşluğu 20 px daraltmak tek sayı değişikliği), ve veri sabit olduğu için üretim
her çalıştırmada birebir aynı. Gerçek karo seti çizildiğinde TileMapLayer'a geçmek
`bolum.gd`'nin tek bir fonksiyonunu değiştirmek olacak.

### Sarkaç nasıl çalışıyor

Kanca takılıyken her fizik karesinde sırayla: yerçekimi → girdi teğetsel ivme olarak
eklenir → halat gergiyse **dışarı doğru hız bileşeni silinir** (halat uzamaz) →
`move_and_slide` → konum halat çemberine geri çekilir. Bırakınca hıza dokunulmaz
(sadece küçük bir `BIRAKMA_CARPANI` bonusu), momentum bu yüzden korunur.

## Bölümler

| # | Ad | Öğrettiği / kısayolu |
|---|---|---|
| 1 | İlk Tutuş | Öğretici: nişan al, tut, bırak. Üstteki yüksek nokta tek salınışta boşluğu geçirir. |
| 2 | Halat Boyu | Öğretici: halatı kısalt/uzat. Kısaltıp savurursan orta platforma hiç inmezsin. |
| 3 | Diken Tarlası | Diken = ölüm. Tek uzun salınımla tarlanın tamamı atlanır. |
| 4 | Uçurum | Üst hat zincirinde iki uçurum birden geçilir. |
| 5 | Yukarı | Yükselen platformlar; üst kanca hattı platformlara hiç değmeden taşır. |
| 6 | Dar Geçit | Alçak tavan; halatı asgariye indirip tam tur atmak çıkışta yüksek hız verir. |
| 7 | Hız | En uzun bölüm; y=60 sırası hiç yere inmeden bitişe kadar gider. |
| 8 | Final | Hepsinin karışımı. |

Her bölümde ölünce (çukur veya diken) bölüm başına dönülür ve süre sıfırlanır.
En iyi süreler kaydedilir, bölüm seçme ekranında görünür.

## Testler

`tests/test_kanca.gd` headless çalışır, çıkış koduyla bildirir (22 kontrol):

- Menzil dışındaki noktaya kanca takılmaz, menzil içindekine takılır.
- Kanca takılıyken oyuncu–nokta mesafesi 320 karelik simülasyonda halat boyunu aşmaz.
- Bırakınca yatay hız sıfırlanmaz, sonraki 30 karede de korunur.
- 8 bölüm sahnesi de yüklenir; her birinde başlangıç, bitiş ve en az 3 kanca noktası var.
- Her bölümdeki her boşluk kanca zinciriyle aşılabilir (bölüm verisi bozulursa yakalar).

## Durum

Prototip tamam. Sonraki adımlar `YOL-HARITASI.md` içinde.
