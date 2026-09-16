# butler komutları — **ÇALIŞTIRILMADI**

Bu dosyadaki hiçbir komut çalıştırılmadı. itch.io'ya yükleme dışarı açılan bir
işlem; kararı Furki'nin. Sayfa da oluşturulmadı (itch.io'nun sayfa oluşturma
API'si yok, form elle doldurulur).

## Ön koşullar

```powershell
# butler kurulu mu
butler version

# Giriş yapılmış mı (anahtar butler_creds içinde)
butler status furkiozknn/kanca
```

Giriş yoksa:

```powershell
butler login
```

## Yapıları üret

```powershell
cd D:\Repolar\kanca
powershell -ExecutionPolicy Bypass -File tools\tam_dogrulama.ps1
```

Çıktılar:

- `build\windows\kanca.exe` (+ yanındaki `.pck`)
- `build\web\` (`index.html`, `index.wasm`, `index.pck`, …)

## Yükleme

```powershell
cd D:\Repolar\kanca

# Web (tarayıcıda oynanan sürüm)
butler push build\web furkiozknn/kanca:html5 --userversion 0.4.0

# Windows masaüstü
butler push build\windows furkiozknn/kanca:windows --userversion 0.4.0
```

## Yükleme sonrası

```powershell
# Durum
butler status furkiozknn/kanca
```

itch.io sayfasında elle yapılacaklar:

1. `html5` kanalını **"This file will be played in the browser"** olarak işaretle.
2. Embed boyutu **1280×720**, "Fullscreen button" açık, "Click to run" kapalı.
3. **SharedArrayBuffer kutusunu İŞARETLEME** — bu yapı tek iş parçacıklı
   (`variant/thread_support=false`), işaretlenirse oyun hiç açılmaz.
4. Kapak: `yayin\kapak.png`, ekran görüntüleri: `yayin\ekran_1..4.png`.
5. Sayfa metni: `yayin\itch-sayfa.md` (önce İngilizce, altında Türkçe).

## Sürüm etiketi

Depo yerelde `v0.4` etiketiyle işaretli:

```powershell
git -C D:\Repolar\kanca tag -l
```

**Push yok** — depo yerel, GitHub'a gönderilmedi.
