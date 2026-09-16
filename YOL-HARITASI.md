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

## Sonraki tur — v0.3

### Önce yapılması gereken
- [ ] **İnsan testi.** Bot "geçilebilir ve hızlanabilir" diyor; "iyi hissettiriyor"
      sorusu hâlâ açık. Özellikle: kanca uçuş süresi 55 ms yeterince his veriyor mu,
      rüzgâr alanları kontrolü elden alıyor mu, kırılgan noktalar sinir bozucu mu.
- [ ] **Madalya süreleri elle ayarlanmalı.** Şu anki değerler bölüm uzunluğundan
      hesaplandı (≈300 px/sn ortalama + 1,5 sn), gerçek koşuyla doğrulanmadı.
      Altın hedefleri muhtemelen fazla cömert.

### Oynanış
- [ ] Duvara tutunma / duvardan sekme (dar geçitlerde ikinci bir seçenek)
- [ ] Kanca noktasına çekilme (winch) — halatı hızlı kısaltma tuşu
- [ ] Bölüm sonu "en iyi 3 koşu" listesi
- [ ] Toplanabilir (isteğe bağlı zor yol) — şu an bölümlerde hiç yok

### Görsel ve ses
- [ ] Yağmur / şimşek katmanı (tema "fırtına" ama hava olayı yok)
- [ ] Kanca noktalarına idle animasyonu (hafif salınım)
- [ ] Bölüme göre müzik değişimi (şu an tek parça)
- [ ] Rüzgâr için sürekli ambiyans sesi

### İçerik
- [ ] 14 → 20 bölüm; son 3'ü gerçekten zor
- [ ] Öğelerin ikinci seviye kullanımları (hareketli + rüzgâr, kırılgan + tavan dikeni)

### Mobil ve yayın
- [ ] Dokunmatik kontrol (ekrana dokunulan yere nişan, tek parmak kanca)
- [ ] Android dışa aktarma
- [ ] itch.io'ya yükleme — **Furki'nin onayı gerekiyor**, komutlar `yayin/` altında hazır

## Bilinen sınırlar

- **İnsan testi yapılmadı.** Bütün denge kararları bot ölçümü ve statik analiz.
- **Madalya süreleri formülle üretildi**, gerçek koşuyla doğrulanmadı.
- Web yapısı tek iş parçacıklı; Stream ses yolunun gecikme bedeli var
  (thread_support açılırsa itch.io'da SharedArrayBuffer kutusu şart olur).
- Bölümlerde toplanabilir yok; tek hedef süre.
- Çıkışta 2 ObjectDB sızıntısı uyarısı var (önbelleğe alınan TileSet) — zararsız,
  ama v0.3'te `KaroSeti._onbellek` sahne değişiminde temizlenebilir.
