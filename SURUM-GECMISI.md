# Sürüm geçmişi — Kanca

README'nin ilk ekranı bir sürüm dökümüyle doluydu; oyunu ilk kez görecek kişi
oynanışı görmeden önce on üç satırlık bir değişiklik listesi okuyordu. Liste
silinmedi, buraya taşındı.

Güncel sürümün notları GitHub'da da duruyor:
<https://github.com/Furkiozknn/kanca/releases>

## Yayınlanmadı — arayüz yenilemesi (29 Eylül 2026, `yenileme/arayuz` dalı)

Çekirdek mekanik, 14 bölüm, fizik ve bot eşikleri v0.5 ile aynı
(`tools/rota.gd --denetle`: 14/14 bölüm bitiyor, altın eşikler geçerli,
`rota_verisi.gd` değişmedi). Değişen: görünüm, arayüz, dil ve girdi tepkisi.

- **Görünüm:** oyun tanıtım videosundaki dünyaya taşındı — düz renk, gölgesiz;
  lacivert (1–7) ve kâğıt (8–14) tema, turkuaz hap oyuncu, turuncu iz ve seçili
  kanca, kırmızı diken. Pixel-art sprite'lar `_eski/` altına alındı, hiç PNG
  yok. Yazı: Instrument Sans + JetBrains Mono (OFL).
- **Arayüz:** menüde tek büyük **Oyna** + tek satır yardım, canlı sarkaç
  arka planı; HUD `01 / BÖLÜM ADI` + büyük süre + rozetler; duraklat ve bölüm
  sonu kartları (rekor damgası, madalya, Tekrar dene / Sonraki bölüm); iki
  sütunlu ayarlar; turuncu renk bandı geçişi; sıralı giriş; ölümde flaş.
- **Dil:** Türkçe / İngilizce. Varsayılan işletim sistemi / tarayıcı dili;
  menüde ve Ayarlar'da dil düğmesi; kayıtlı en iyi süreler ve ilerleme aynen
  korunur (yalnız yeni `ayarlar/dil` anahtarı).
- **His:** kanca at/bırak olay geldiği anda uygulanır (bırakma gecikmesi
  yüksek yenileme hızında ort. ~9 → ~2 ms; 60 Hz vsync'te fark ~0,7 ms).
  İlk oyunda ipucu yalnız hiç bitirilmemiş bölümde ve ilk kancadan sonra solar.
  Kayıtları sıfırla iki adımlı. Bölüm sonu `Enter` artık odaktaki düğmeyi
  çalıştırır (eskiden hep sonraki bölüm).
- **Test:** 115 → 157 (menü, duraklat, bölüm sonu, dil, çeviri, tema, erken
  girdi). `TEST_TABANI` 157.
- **Boyut:** web `index.pck` 473.128 → 722.620 bayt (+%0,62 toplam).
- **Araçlar:** `tools/tema_uret.gd`, `tools/fps.gd`, `tools/his_olc.gd`,
  `tools/kayit.ps1` (yazısız dikey oynanış klibi), `tests/ekran.gd` yenilendi.

## v0.5.2 — belge ve depo hijyeni turu (22 Eylül 2026)

Oynanış v0.5 ile aynı. MIT lisansı, `main`'e her push ve PR'da **115 testin**
koştuğu CI (Godot 4.7.2, Linux, Git LFS), 30 belge düzeltmesi ve README'ye ilk
kez dışa aktarma komutları. En önemli düzeltme: README "14/14 bölümün eşiği
ölçülmüş" diyordu, gerçek 13/14 — "Bilinen sınırlar"a madde eklendi.

## Önceki sürümler

Aşağıdaki döküm README'den olduğu gibi taşındı.

Durum: **v0.5.1 — MIT lisansı, her push'ta CI, PATH'ten Godot.** Oynanış v0.5
ile aynı: **bot hareketli noktada bekliyor ve frenliyor, akış tablosu,
tanıtım GIF'i.** 14 bölüm, gerçek pixel art, ses ve müzik, ayarlar ekranı,
madalyalar, hayalet tekrarı (kendi koşun ya da **altın hayalet**), kontrol
noktaları, günlük meydan okuma; puanlamalı hedefleme, kancada tampon + kojot,
halat pompası, bırakma bonusu, ileri bakan kamera, tek parmak dokunmatik
şeması, tuş atama, rota ipucu ve ustalık zinciri. v0.5 ile: **madalya
eşikleri 14 bölümün 13'ünde ölçülmüş bot koşusundan** (v0.4: 11; 2, 6 ve 7
artık ölçülmüş, yalnız 5 tahminde — bot canlı hedefe nişan alıyor, hareketli
noktayı platformda bekliyor, bitişe inişi bonuslu hızla ve bayrak alanıyla
hesaplıyor), **bölüm seçme ekranında akış zinciri rekoru**,
dokunmatikte **tuş adı kalmadı** (tek yardımcı, testle taranıyor) ve
`yayin/tanitim.gif`.
