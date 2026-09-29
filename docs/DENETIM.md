# Denetim — arayüz yenilemesi öncesi durum (29 Eylül 2026)

Kapsam: `main` dalının `687a67e` hâli (v0.5.2 + README düzeltmesi). Oyun bu
makinede (Windows 11, Intel UHD, Godot 4.7.2) gerçekten açılıp oynandı;
yalnızca kod okunmadı. Bulguların görsel kanıtı `docs/tasarim/once-*.png`
(bu belgede geçen "önce" kareleri).

## Nasıl denetlendi

| Yol | Ne yapıldı |
|---|---|
| Masaüstü (Godot) | `tests/ekran.tscn` ile menü / Bölüm Seç / Ayarlar / duraklat / bölüm sonu / oynanış 1280×720 karelere alındı; `tools/fps.gd` ile kare süresi ölçüldü. |
| Web, yerel | `main`'den `--export-release "Web (HTML5)"`, `build/web_once` içinde `python -m http.server`; Claude Browser ile açıldı, `Enter` / `D` ile oynandı, konsol okundu. |
| Web, canlı | `https://furkiozknn.github.io/kanca/` açıldı (masaüstü Chromium): menü geldi, `Enter` 1. bölümü yükledi, `D` ile koşuldu, konsolda hata yok. Canlı sayfa `main`'in yapısı; kare süresi ve boyut ölçümü yerel dışa aktarmadan. |
| Mobil | Tarayıcıda 375×812 emülasyonu (yeni yapıda). Eski yapıda dikey telefon için hiçbir ipucu yoktu. **Gerçek telefonda denenmedi.** |
| Girdi gecikmesi | `tools/his_olc.gd`: tuş olayından kancanın tutunmasına / kopmasına süre, 60–80 deneme, rastgele faz. Eski kod için `main`'in ayrı bir çalışma ağacı (git worktree) kullanıldı. |
| Bot | `tools/rota.gd --denetle` (14 bölüm × 5 koşu): bölümler hâlâ bitiyor mu, eşikler geçerli mi. |

## Bulgular

### İlk 30 saniye anlaşılıyor mu?

Kısmen.

- Menüde beş **eşit ağırlıklı**, koyu-gri düz düğme var (`Başla — 14. bölüm`,
  `Bölüm Seç`, günlük, `Ayarlar`, `Çıkış`). Asıl eylem belli değil; günlük
  düğmesi iki satırlık uzun bir metin ("Günlük: 10. Dikenli Tavan — Yan rüzgâr /
  Henüz koşulmadı") ile ana düğmeden daha kalabalık.
- Kontroller menünün altında **iki satır**, soluk mavi-gri ve 10 px: "Fare:
  nişan • Sol tık: kanca • A/D: koş & salın / Boşluk: zıpla • W/S: halatı
  kısalt/uzat • R: yeniden". Tek bakışta okunmuyor.
- Başlık pixel-art logo, ama oyunun asıl hareketi (sarkaç) hiçbir yerde
  gösterilmiyor. Tanıtım videosundaki dünya (lacivert zemin, beyaz çapa,
  turkuaz top, turuncu iz, düz renk) ile oyunun görünümü (fırtınalı gökyüzü
  adaları, yosunlu pixel-art kaya) **hiç örtüşmüyor**.
- Oyuncu 640×360 tabanda 16×24 px: 1280×720'de bile küçük, halat ve kanca
  noktalarının yanında ilk bakışta seçilmiyor (bkz. `once-oyun.png`).
- 1. bölüm ipucu ("Fare ile nişan al, SOL TIK basılı tut…") yalnız altta,
  sarı 11 px bir şeritte; **bölüm bitirilmiş olsa bile her seferinde
  gösteriliyor** ve hiç solmuyor.
- HUD dört ayrı satır: `Süre 00:00.849` (16 px), `En iyi …` (11), `6. Sallanan
  Kayalar` (11, soluk), `Altın hedefi …` (10, sarı) — hepsi ayrı yarı saydam
  koyu şerit içinde; şeritler oyun nesnelerinin üstüne biniyor.

![önce: menü](tasarim/once-menu.png)
![önce: oyun](tasarim/once-oyun.png)

### Kontrol tepkisi

- Kanca at / bırak tuşu `_physics_process` içinde okunuyordu; olay 60 Hz fizik
  adımını bekliyordu. Ölçüm (`tools/his_olc.gd`, pencereli, vsync kapalı,
  kare sınırı yok = yüksek yenileme hızlı ekran benzetimi, 80 deneme ×2 koşu):
  **bırakma olayından kancanın kopmasına ortalama 9,1 ve 8,6 ms, %95 = 16,4 ve
  17,4 ms**. Tutunma ~60 ms: bunun 55 ms'si bilinçli atış uçuşu
  (`KANCA_UCUS_SURESI`), yani sorun değil.
- 60 Hz vsync'te (kare başına tam bir fizik adımı) aynı ölçüm bırakmada ortalama
  16,5 ms çıktı ve yeni kodla 15,8 ms: orada kazanç ≈0,7 ms, çünkü olay dağıtımı
  ile fizik adımı aynı karede ardışık çalışıyor. Yani gecikme kazancı
  yalnızca 60 Hz'in üstünde yenileme hızında (144 Hz ekran) anlamlı.
- Affetme değerleri: kanca tamponu 0,12 sn, kanca kojotu 0,12 sn, zıplama
  tamponu 0,12 sn, zıplama kojotu 0,12 sn (`scripts/ayarlar.gd`). Platform
  oyunlarında yaygın aralık (0,08–0,15 sn) ve testler (`_test_kanca_tamponu`,
  `_test_kojot_kanca`) bunları sınıyor. `rota_verisi.gd`'deki madalya eşikleri
  bu değerlerle ölçüldü, o yüzden **değiştirilmedi**.
- Çıkış (bölüm sonu) yolunda `Enter` doğrudan **sonraki bölüme** atlıyordu;
  tekrar denemek için fareyle düğmeye gitmek ya da `R` gerekiyordu.

### Zorluk eğrisi adil mi?

Bot ölçümü (`tools/rota.gd --denetle`, tepki 0,05–0,20 sn, 14 bölüm × 5
koşu, dosya yazılmaz): **14/14 bölüm bitiyor, yayımlanan her altın eşiği
botun bugünkü ortancasını aşıyor** (pay 0,00 ile 3,86 sn; 5. bölümde pay 0,00
çünkü eşik hâlâ **tahmin**, ölçülmüş değil). Botun ortancaları:

| Bölüm | 1 | 2 | 3 | 4 | 5* | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Bot ortancası (sn) | 2,38 | 5,40 | 4,18 | 3,30 | 11,10 | 4,85 | 5,87 | 3,88 | 8,30 | 3,32 | 5,50 | 4,28 | 7,93 | 8,58 |

Eğri düzgün bir rampa değil (4. bölüm 3,3 sn, 5. bölüm tahmin 11,1 sn, 8. ve 10.
bölüm yine 3–4 sn): bölümlerin tanıttığı mekanik sırayla ilerliyor (hareketli
nokta 6, kırılgan 8, rüzgâr 9, tavan dikeni 10), süre ise değil. Bu bir **bot**
ölçümüdür; bir insan bandı değildir (bkz. hafıza notu "bot ölçümü insanı temsil
etmez"). "İnsan tepkisiyle çözülebilir"in kanıtıdır, "zevkli"nin değil.
**İnsan elinde zorluk bu denetimde ölçülmedi.**

### Oyun sonu ve bölüm sonu

- Bölüm sonu paneli: beş satır düz beyaz metin (`1. bölüm — İlk Tutuş / Süre /
  En iyi / Madalya: Altın / Akış: ×3`) ve üç aynı boyutlu düğme. Yeni rekor
  yalnız "YENİ REKOR!" metniyle anılıyor; madalya bir kelime, simge yok.
- Ölüm: 0,22 sn'lik koyu karartma-açılma; yeniden doğuş karartmanın altında
  hemen gerçekleşiyor, yani karartma geri bildirim değil "göz kırpma".
- Kayıtları sıfırla düğmesi (Bölüm Seç ekranı) **tek tıkla bütün ilerlemeyi
  siliyor** — onay yok.

![önce: duraklat](tasarim/once-duraklat.png)
![önce: bölüm sonu (dokunmatik)](tasarim/once-bitis.png)

### Ayarlar

- Tek sütunda on satır; "Rota ipucu (altın madalyadan sonra)" ve "Tek parmak
  şeması (dokunmatik)" uzun etiketler, ekran 360 px'e yaklaşıyor. **Dil seçeneği
  yok**; oyun yalnızca Türkçe. Videolar X ve YouTube'da İngilizce yayınlanıyor,
  oradan gelen oyuncu ilk ekranda Türkçe metinle karşılaşıyordu.

![önce: ayarlar](tasarim/once-ayarlar.png)
![önce: bölüm seç](tasarim/once-bolum-sec.png)

### Mobil ve dokunmatik

- Tek parmak şeması var ve iyi düşünülmüş (dokun = kanca / zıpla, kaldır =
  bırak, dikey kaydır = halat). "Duraklat" düğmesi küçük ve metinli.
- Oran `keep` (oda kamerası 640×360'a kilitli): dikey telefonda oyun ekranın
  üçte birinde küçük bir şerit ve **kullanıcıya telefonu yatay tutmasını
  söyleyen hiçbir şey yoktu** (`once-telefon.png` yatay çekim; dikey durum yalnız
  yeni yapıda denendi).

### Konsol

Canlı sayfada hata seviyesinde konsol satırı yok. Yerel eski dışa aktarmada
menü → 1. bölüm akışında `GL_INVALID_FRAMEBUFFER_OPERATION … Attachment has
zero size` uyarısı iki kez (her seferinde `glClear`, `glDrawArrays`,
`glBlitFramebuffer`: 6 satır) görüldü; hata yok, görüntü etkilenmiyor. Kaynağı
doğrulanmadı (yeniden boyutlanırken çıkan WebGL uyarısı olabilir). Yeni
yapıda menü → bölüm → duraklat → ayarlar → dil akışında aynı üçlüden üç
tane (9 satır) görüldü; başka uyarı ya da hata yok.

### Ölçümler (önce)

| | Değer |
|---|---|
| Kare süresi, 10. bölüm | ort. 2,68 ms, %99 3,83 ms (ilk koşu); aynı makinede başka Godot süreçleri çalışırken 3,6–3,9 ms, %99 11–16 ms |
| Kare süresi, 14. bölüm | ort. 2,21 ms, %99 3,43 ms (ilk koşu); yoğun makinede 3,2–3,9 ms |
| Web `index.pck` | 473.128 bayt |
| Web `index.wasm` | 39.514.754 bayt |
| Web `index.js` | 279.815 bayt |
| Toplam (pck+wasm+js) | 40.267.697 bayt |
| Test | 115/115 |
| Bot | 14/14 bölüm bitiyor |

Ölçüm gürültüsü: bu makinede aynı anda birkaç Godot oturumu çalışıyor
(zamanlanmış görevler dahil); ilk sessiz koşu ile yoğun koşu arasında kare
süresi %40'a kadar oynuyor. "Sonra" tablosu (TASARIM.md) bu yüzden **aynı
zaman diliminde aralıklı** (A/B) koşulardan alındı.

## Bu denetimin kapsamadıkları

- Gerçek telefon, Safari, Firefox.
- İnsan zorluğu / eğlence (yalnızca bot).
- Ses (yalnız var olduğu ve web'de çaldığı doğrulandı; içerik değerlendirilmedi).
