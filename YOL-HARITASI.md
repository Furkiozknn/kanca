# Kanca — yol haritası

## Bu turda yapıldı (2026-09-16)

- [x] Şablondan proje kurulumu (GL Compatibility, 640×360 / 1280×720, nearest, fizik 60)
- [x] Temel hareket: koş, zıpla, kojot süresi, zıplama tamponu, değişken zıplama yüksekliği
- [x] Kanca: fare / gamepad sağ çubuk nişanı, nişan yoksa bakış yönüne otomatik seçim
- [x] Menzil sabiti + menzildeki adayın nişangâhta vurgulanması
- [x] Halat kısıtlı sarkaç fiziği, Line2D halat çizimi
- [x] Yukarı/aşağı ile halat kısaltma/uzatma (sınırlı)
- [x] Bırakınca momentumun korunması
- [x] Tehlikeler: çukur + diken → ölüm → bölüm başı
- [x] 8 bölüm, yatay ilerleyen, yumuşak kamera takibi, ilk 2'si öğretici
- [x] Her bölümde en az bir kısayol (iyi bir salınışla atlanabilen kısım)
- [x] Süre sayacı, en iyi süre kaydı, bitişte süre + en iyi süre gösterimi
- [x] Ana menü, bölüm seçme, duraklatma, bitiş ekranı — hepsi Türkçe
- [x] İlerleme kaydı (`user://kayit.cfg`)
- [x] Klavye + gamepad girdisi
- [x] Otomatik testler (22 kontrol, headless, çıkış koduyla)
- [x] Windows + Web dışa aktarma
- [x] Ekran görüntüsüyle görsel doğrulama (`tests/ekran.gd`)

## Sonraki aşama — oynanış

- [ ] **Gerçek oyun testi (insan).** Bot ve statik kontroller "geçilebilir" diyor ama
      *iyi hissettiriyor mu* sorusunu cevaplamıyor. Sabitleri (`scripts/ayarlar.gd`)
      elde oynayarak ayarla: `SALLANMA_IVMESI`, `SALLANMA_SONUMU`, `BIRAKMA_CARPANI`.
- [ ] Kanca atış animasyonu: halat anında değil, uçarak gitsin (görsel gecikme)
- [ ] Kontrol noktası (checkpoint) — uzun bölümlerde baştan başlamak yerine
- [ ] Hava kontrolü / duvara tutunma gibi ikincil hareketler
- [ ] Hayalet (ghost) koşu: en iyi denemeni yanında gör
- [ ] Bölüm sonu madalyaları (altın/gümüş/bronz süre eşikleri)

## Sonraki aşama — görsel ve ses

- [ ] Pixelorama ile gerçek sprite: oyuncu (koşu/salınım/düşüş), kanca noktası, diken
- [ ] Karo seti + TileMapLayer'a geçiş (`bolum.gd` içindeki `_kati_blok` yerine)
- [ ] Arka plan katmanları (paralaks)
- [ ] Hız hissi: iz (trail) efekti, ekran sarsıntısı, hız çizgileri
- [ ] rFXGen ile ses: kanca takılma, kopma, zıplama, ölüm, bölüm bitişi
- [ ] Müzik (tek parça, döngülü). **Dikkat:** web'de pitch/volume/döngü sessizce
      bozuluyor — tek bir proje ayarı çözüyor, masaüstünde görünmüyor.

## Sonraki aşama — içerik

- [ ] 8 → 16 bölüm; son 4'ü gerçekten zor
- [ ] Bölüm başına altın/gümüş süre hedefi
- [ ] Hareketli kanca noktaları, kopan noktalar (tek kullanımlık)
- [ ] Rüzgâr / itici alanlar

## Sonraki aşama — mobil ve yayın

- [ ] Dokunmatik kontrol (ekrana dokunulan yere nişan, tek parmak kanca)
- [ ] Android dışa aktarma
- [ ] itch.io sayfası + butler ile yükleme — **Furki'nin onayı gerekiyor**
- [ ] Steam kapsülü / mağaza sayfası (çok sonra)

## Bilinen sınırlar

- Görseller yer tutucu (renkli dikdörtgen + şablon sprite'ı).
- Ses yok.
- Kontrol noktası yok; ölünce bölüm başı.
- `tests/` klasörü dışa aktarılan pakete de giriyor (~5 KB, zararsız).
  Temizlemek için export presetlerine `exclude_filter="tests/*"` eklenebilir.
