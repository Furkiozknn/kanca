# Kanca — yol haritası

## Tur 0 — prototip (2026-09-16, sabah)

- [x] Şablondan proje kurulumu (GL Compatibility, 640×360 / 1280×720, nearest, fizik 60)
- [x] Temel hareket: koş, zıpla, kojot süresi, zıplama tamponu, değişken zıplama yüksekliği
- [x] Kanca: fare / gamepad sağ çubuk nişanı, nişan yoksa bakış yönüne otomatik seçim
- [x] Menzil sabiti + menzildeki adayın nişangâhta vurgulanması
- [x] Halat kısıtlı sarkaç fiziği, Line2D halat çizimi
- [x] Yukarı/aşağı ile halat kısaltma/uzatma (sınırlı)
- [x] Bırakınca momentumun korunması
- [x] Tehlikeler: çukur + diken → ölüm → bölüm başı
- [x] 8 bölüm, yatay ilerleyen, yumuşak kamera takibi, ilk 2'si öğretici
- [x] Süre sayacı, en iyi süre kaydı, ana menü / bölüm seç / duraklat / bitiş ekranı
- [x] Otomatik testler, Windows + Web dışa aktarma, ekran görüntüsüyle doğrulama

## Tur 1 — v0.2 "yayına hazır ilk sürüm" (2026-09-16)

### Altyapı
- [x] `CLAUDE.md` — kalıcı proje kuralları, komutlar, kilit kuralı, tuzak listesi
- [x] `tools/kilit.ps1` — Godot kilidi tek noktadan; `tam_dogrulama.ps1` kilidi bir kez alıyor
- [x] Test çalıştırıcıya zaman aşımı (parse hatasında sonsuza kadar asılmıyor)
- [x] `exclude_filter` — `tests/`, `tools/`, `docs/`, `yayin/`, `assets/audio/_ham/` pakete girmiyor

### Görsel kimlik
- [x] Tek sınırlı palet (`scripts/palet.gd`, Endesga 32 alt kümesi)
- [x] Bütün sprite'lar kodla üretiliyor (`tools/sprite_uret.gd`, deterministik)
- [x] Oyuncu 10 kare (bekle ×2, koş ×4, zıpla, düş, sallan ×2) — ASCII haritalardan
- [x] Karo seti (4×3 atlas) + **TileMapLayer'a geçiş**, 16 px ızgara
- [x] Kanca noktası 3 tür, diken, tavan dikeni, bayrak, kontrol noktası, madalya, logo
- [x] 3 katman parallaks (uzak ada / bulut bandı / yakın ada siluet) + gökyüzü degrade
- [x] Üretilen PNG'ler `docs/sprite_onizleme.png` üzerinden gözle kontrol edildi

### Ses
- [x] 10 efekt (rFXGen ham + `tools/ses_uret.gd` ile perde/kırpma pişirme)
- [x] 2 müzik parçası (oyun `hizli`, menü `sakin`)
- [x] `Muzik` / `Efekt` veri yolları, ses düzeyi veri yoluna yazılıyor
- [x] Web ses tuzağı kapatıldı (`default_playback_type.web=2`, `mix_rate.web=48000`)

### Ayarlar
- [x] Ayarlar ekranı: müzik/efekt seviyesi + aç-kapa, tam ekran, hayalet, sarsıntı
- [x] Duraklatma menüsünden de erişilebiliyor
- [x] `user://kayit.cfg` içinde saklanıyor

### Oyun hissi
- [x] Kanca uçuş süresi (55 ms) + takılma sarsıntısı + ses
- [x] Bırakmada hız izi (Line2D) ve parçacık
- [x] İniş / ölüm / toplama parçacıkları (CPUParticles2D)
- [x] Ekran sarsıntısı (ayarlanabilir), esneme-sıkışma, sahne geçişi (kararma)

### İçerik
- [x] 8 → **14 bölüm**, her yeni öğe tek tek tanıtılıyor
- [x] Hareketli kanca noktası (6), kırılgan nokta (8), rüzgâr (9), tavan dikeni (10)
- [x] Kontrol noktaları (11, 12, 13, 14) — süre durmuyor
- [x] Madalya süreleri (altın/gümüş/bronz), bitişte ve Bölüm Seç'te gösterim
- [x] Hayalet: en iyi koşu kaydı + tekrar oynatma, ayarlardan kapatılabilir
- [x] Sallanma sabitleri botla ölçüldü, karar README'de

### Yayın
- [x] `yayin/itch-sayfa.md` (İngilizce + Türkçe), `butler-komutlari.md`
- [x] 4 ekran görüntüsü 1280×720, kapak 630×500 (motor içinden)
- [x] Windows + Web dışa aktarma, `v0.2` etiketi

## Tur 2 — v0.3 "rakip analizinden iyileştirmeler" (2026-09-16)

Kaynak: `D:\Claude Projeleri\oyun-terminalleri\tasarim\kanca-rakip-analizi.md`

### Hedefleme
- [x] Puanlama: nişan hizası ×3 − uzaklık/menzil + hız yönüne uyum
- [x] Görüş hattı (`intersect_ray`) — duvarın arkasındaki nokta aday değil
- [x] Hedef önizlemesi: seçili nokta parlar + kesik çizgi, menzil dışı gri
- [x] Kanca tamponu 0,12 sn + kojot-kanca 0,12 sn (menzil payı ×1,2)
- [x] Nişan hassasiyeti ayarı (geniş yardım ↔ tam nişan)

### Sallanma hissi
- [x] Sert halat kısıtı: konum yansıtma **+ kalan radyal hızın silinmesi**
- [x] Sallanırken yerçekimi ×1,3 (ölçümle seçildi, `SALLANMA_YERCEKIMI`)
- [x] Halat pompası: gergin halatı kısaltmak açı momentumunu koruyor
- [x] Bırakma bonusu yalnız eşik üstünde (×1,10 + altın parçacık + `firla` sesi)
- [x] İleri bakan kamera: hız yönüne ofset + yüksek hızda %9 uzaklaşma

### Süre ve rota
- [x] `tools/rota.gd` — rota planlayıcı (Dijkstra) + gerçek fizikte oynayan bot
- [x] Madalya süreleri bot koşusundan, rastgele tepki gecikmesiyle, **ms hassasiyetinde**
- [x] `scripts/rota_verisi.gd` üretilmiş dosya; `Bolumler.madalya_esikleri()` onu tercih ediyor
- [x] Süre gösterimi ms (`00:06.284`)

### Girdi
- [x] Mobil tek parmak şeması (koşu otomatik, dokun = kanca/zıpla, bırak = fırla,
      dikey kaydırma = halat boyu); masaüstünde ayardan denenebiliyor
- [x] Tuş atama ekranı (`scripts/tuslar.gd`, `scripts/tus_dugmesi.gd`) — fare/gamepad korunuyor

### Farklılaştıranlar
- [x] Rota ipucu: altın madalyadan sonra rotanın kullandığı noktalar işaretli
- [x] Ustalık zinciri ("Akış ×N"): yere değmeden art arda kanca, süreden ayrı not

### Doğrulama
- [x] 21 yeni test (45 → **66**), import 0 hata, Windows + Web dışa aktarma
- [x] `SALLANMA_SONUMU` 0,05 → 0,10 (sert kısıt enerji kaçağını kapattı)
- [x] Ekran görüntüleri yenilendi, `yayin/` güncellendi, `v0.3` etiketi
- [x] Görsel kontrol iki düzen hatası yakaladı (madalya simgesi çakışması,
      ayarlar kutusunun 360 px'i taşması)

## Tur 3 — v0.4 "akıllı bot, altın hayalet, günlük meydan okuma" (2026-09-16)

### Bot
- [x] **Halat pompası:** güvenlik (yay dibi diken/zemin üstünde) + hız
      (dipte kısalt, uçlarda uzat), 520 px/sn'de kesiliyor
- [x] **Rota araması:** bitiremediği rotada en çok ölünen düğüme plan cezası,
      Dijkstra yeniden (en çok 4 deneme)
- [x] **Kurtarma kancası:** rota adımı menzilde değilken düşerken yoldaki
      noktaya tutunma; bitişten ötedeki noktaya tutunmak yasak
- [x] **İniş kontrolü:** balistik yol bitiş platformunu aşacaksa bırakma yok
- [x] **14/14 bölüm gerçek koşuyla bitiyor** (v0.3: 5/14); 11 bölümün eşiği
      ölçülmüş koşudan, 3'ü (2, 6, 7) aykırı değer kuralıyla tahmin
- [x] Madalya çarpanları 1,25/1,70/2,30 → **1,45/1,95/2,60** (gerekçe README'de)
- [x] Tanı kipi artık üretilmiş dosyayı yazmıyor; boş sonuç da dosyaya dokunmuyor

### Hayalet
- [x] Örnekleme 20 Hz → **10 Hz** (kayıt yarıya indi), aralık kayda yazılıyor
- [x] **Altın hayalet:** botun koşusu (`RotaVerisi.iz`), altın madalyadan sonra
- [x] Ayar üç seçenekli: Kapalı / En iyi koşun / Altın hayalet

### Dokunmatik
- [x] Ölümden sonra tek dokunuşluk **"Baştan başla"** düğmesi
- [x] Yanlışlıkla tetiklenmeye karşı 0,7 sn bekleme + tam ekran değil küçük düğme

### Günlük meydan okuma
- [x] Tarihten tohum → bölüm + değiştirici (kısa halat / yan rüzgâr)
- [x] Ayrı kayıt yuvası (`[gunluk]`), ana ilerlemeyi bozmuyor
- [x] Menüde günün bölümü, değiştiricisi ve bugünkü en iyi süre

## Sonraki tur — v0.5

### Önce yapılması gereken
- [ ] **İnsan testi.** Hâlâ yapılmadı. Merak konusu: halat pompası fazla güçlü
      mü (bot onunla bölümleri yarı sürede bitiriyor), kamera uzaklaşması pixel
      art'ta titriyor mu, tek parmak şeması gerçek telefonda ne hissettiriyor,
      yeni (daha sıkı) altın eşikleri insan için ulaşılabilir mi.
- [ ] **Bot 6. ve 7. bölümde kötü oynuyor** (ölçeğin 2 katından yavaş):
      hareketli noktada zamanlama bekleyemiyor, dar geçitte savruluyor.
      2. bölümde bitirebiliyor ama çok dolambaçlı.

### Oynanış
- [ ] Duvara tutunma / duvardan sekme (dar geçitlerde ikinci bir seçenek)
- [ ] Kanca noktasına çekilme (winch) — halatı hızlı kısaltma tuşu
- [ ] Bölüm sonu "en iyi 3 koşu" listesi
- [ ] Toplanabilir (isteğe bağlı zor yol) — şu an bölümlerde hiç yok
- [ ] Rüzgâr pompası: akıntıda doğru anda halat kısaltmaya bölüme özgü ödül
- [ ] Günlük meydan okumaya üçüncü değiştirici (şu an iki tane)

### Görsel ve ses
- [ ] Yağmur / şimşek katmanı (tema "fırtına" ama hava olayı yok)
- [ ] Kanca noktalarına idle animasyonu (hafif salınım)
- [ ] Bölüme göre müzik değişimi (şu an tek parça)
- [ ] Rüzgâr için sürekli ambiyans sesi
- [ ] Akış zinciri için yükselen perde (zincir uzadıkça ses tizleşsin)

### İçerik
- [ ] 14 → 20 bölüm; son 3'ü gerçekten zor
- [ ] Öğelerin ikinci seviye kullanımları (hareketli + rüzgâr, kırılgan + tavan dikeni)

### Mobil ve yayın
- [ ] Android dışa aktarma (tek parmak şeması hazır, dışa aktarma yok)
- [ ] Dokunmatik için büyük dokunma alanları / duraklat düğmesi
- [ ] itch.io'ya yükleme — **Furki'nin onayı gerekiyor**, komutlar `yayin/` altında hazır

## Bilinen sınırlar

- **İnsan testi yapılmadı.** Bütün denge kararları bot ölçümü ve statik analiz.
- Madalya süreleri 11 bölümde gerçek bot koşusundan, 3 bölümde (2, 6, 7)
  ölçülmüş rota hızından tahmin (`"tahmin": true`) — bot oralarda kötü oynuyor.
- Bot artık pompalıyor ve rota arıyor; altın eşikleri v0.3'e göre bazı
  bölümlerde belirgin biçimde **sıkıldı**. İnsanla doğrulanmadı.
- Web yapısı tek iş parçacıklı; Stream ses yolunun gecikme bedeli var
  (thread_support açılırsa itch.io'da SharedArrayBuffer kutusu şart olur).
- Bölümlerde toplanabilir yok; hedef süre ve akış zinciri var.
- Çıkışta 2 ObjectDB sızıntısı uyarısı var (önbelleğe alınan TileSet) — zararsız.
