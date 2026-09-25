"""Web yapisi icin duman testi: paket tarayicida gercekten aciliyor ve oynaniyor mu?

Godot'nun disa aktarmasi basarili bitse de web paketi tarayicida acilmayabilir
(eksik dosya, bozuk pck, WebGL hatasi, SharedArrayBuffer isteyen bir ayar).
Bu betik disa aktarilmis klasoru yerelde sunar, Chromium'da acar ve uc sey
sorar:

1. Motor acildi mi?  Godot'nun yukleme perdesi (#status) zaman asimindan once
   kalkmali; sayfada yakalanmamis JS hatasi ya da konsolda "error" olmamali.
2. Menu girdiye cevap veriyor mu?  "Basla" dugmesine tiklaninca goruntu
   menuden belirgin bicimde farkli olmali (1. bolum yuklendi).
3. Oyuncu hareket ediyor mu?  Sag tus basili tutulunca kamera kayar;
   goruntu yine belirgin bicimde degismeli.

"Belirgin" = piksellerin en az ESIK kadari degismis. Karsilastirma
tarayicinin icinde, iki ekran goruntusu bir 2B tuvale cizilerek yapiliyor;
ek Python paketi (Pillow vb.) gerekmiyor.

Kullanim:
    python tools/web_duman.py build/web
    python tools/web_duman.py build/web --ekran duman.png --chromium /yol/chrome

Cikis kodu 0 = uc adim da gecti, 1 = biri dustu. Gereken tek paket:
`pip install playwright` + `python -m playwright install chromium`.

Not: FPS olculmuyor. Duman testi GPU'suz (yazilim WebGL) kosuyor; oradaki
kare hizi oyuncunun makinesi hakkinda bir sey soylemez.
"""
from __future__ import annotations

import argparse
import base64
import functools
import http.server
import sys
import threading
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

GENISLIK, YUKSEKLIK = 1280, 720
# Taban cozunurluk 640x360, pencereyi dolduracak sekilde olcekleniyor
# (canvas_resize_policy=2). "Basla" dugmesi menude ortada, ustten ~%39'da.
BASLA_DUGMESI = (GENISLIK // 2, int(YUKSEKLIK * 0.39))
ESIK = 0.10

_FARK_JS = """
async ([a, b]) => {
  const yukle = (src) => new Promise((ok, hata) => {
    const i = new Image(); i.onload = () => ok(i); i.onerror = hata; i.src = src;
  });
  const [ia, ib] = await Promise.all([yukle(a), yukle(b)]);
  const piksel = (img) => {
    const c = document.createElement('canvas');
    c.width = img.width; c.height = img.height;
    const x = c.getContext('2d'); x.drawImage(img, 0, 0);
    return x.getImageData(0, 0, c.width, c.height).data;
  };
  const pa = piksel(ia), pb = piksel(ib);
  let degisen = 0;
  for (let k = 0; k < pa.length; k += 4) {
    if (Math.abs(pa[k] - pb[k]) + Math.abs(pa[k+1] - pb[k+1]) + Math.abs(pa[k+2] - pb[k+2]) > 24) degisen++;
  }
  return degisen / (pa.length / 4);
}
"""


def _sunucu(klasor: Path) -> tuple[http.server.ThreadingHTTPServer, str]:
    isleyici = functools.partial(_SessizIsleyici, directory=str(klasor))
    sunucu = http.server.ThreadingHTTPServer(("127.0.0.1", 0), isleyici)
    threading.Thread(target=sunucu.serve_forever, daemon=True).start()
    return sunucu, f"http://127.0.0.1:{sunucu.server_address[1]}/index.html"


class _SessizIsleyici(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".js": "text/javascript"}

    def log_message(self, *_: object) -> None:
        pass


def _veri_url(png: bytes) -> str:
    return "data:image/png;base64," + base64.b64encode(png).decode()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("klasor", type=Path, help="disa aktarilmis web klasoru (index.html burada)")
    ap.add_argument("--ekran", type=Path, help="oyun icinden son ekran goruntusunu buraya yaz")
    ap.add_argument("--chromium", help="Playwright'in kendi Chromium'u yerine bu calistirilabilir")
    ap.add_argument("--zaman-asimi", type=float, default=60.0, help="motorun acilmasi icin sn (varsayilan 60)")
    arg = ap.parse_args()

    if not (arg.klasor / "index.html").is_file() or not (arg.klasor / "index.pck").is_file():
        print(f"DUSTU  {arg.klasor} icinde index.html + index.pck yok -- once web disa aktarmasi", file=sys.stderr)
        return 1

    sunucu, url = _sunucu(arg.klasor)
    hatalar: list[str] = []
    sonuc: list[tuple[bool, str]] = []
    try:
        with sync_playwright() as p:
            tarayici = p.chromium.launch(
                executable_path=arg.chromium,
                args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
            )
            sayfa = tarayici.new_page(viewport={"width": GENISLIK, "height": YUKSEKLIK})
            sayfa.on("pageerror", lambda e: hatalar.append(f"pageerror: {e}"))
            sayfa.on("console", lambda m: hatalar.append(f"console.{m.type}: {m.text}") if m.type == "error" else None)

            t0 = time.monotonic()
            sayfa.goto(url)
            try:
                sayfa.wait_for_function(
                    "() => { const s = document.getElementById('status');"
                    " return !s || getComputedStyle(s).display === 'none' || s.style.visibility === 'hidden'; }",
                    timeout=arg.zaman_asimi * 1000,
                )
                acilis = time.monotonic() - t0
                sonuc.append((not hatalar, f"motor acildi ({acilis:.1f} sn), hata yok" if not hatalar
                              else "motor acildi ama hata var"))
            except Exception:  # noqa: BLE001 -- zaman asimi da bir sonuc
                sonuc.append((False, f"motor {arg.zaman_asimi:.0f} sn icinde acilmadi"))

            if sonuc[-1][0]:
                time.sleep(2.0)                       # menu ilk karelerini cizsin
                menu = sayfa.screenshot()
                sayfa.mouse.move(*BASLA_DUGMESI)
                time.sleep(0.3)
                sayfa.mouse.down(); time.sleep(0.2); sayfa.mouse.up()
                time.sleep(4.0)                       # gecis + bolum kurulumu
                bolum = sayfa.screenshot()
                fark = sayfa.evaluate(_FARK_JS, [_veri_url(menu), _veri_url(bolum)])
                sonuc.append((fark >= ESIK, f"Basla -> 1. bolum: piksellerin %{fark * 100:.0f}'i degisti (esik %{ESIK * 100:.0f})"))

                sayfa.keyboard.down("d"); time.sleep(2.5); sayfa.keyboard.up("d")
                time.sleep(0.3)
                kosu = sayfa.screenshot()
                fark = sayfa.evaluate(_FARK_JS, [_veri_url(bolum), _veri_url(kosu)])
                sonuc.append((fark >= ESIK, f"D basili -> oyuncu/kamera ilerledi: piksellerin %{fark * 100:.0f}'i degisti"))
                if arg.ekran:
                    arg.ekran.write_bytes(kosu)
            tarayici.close()
    finally:
        sunucu.shutdown()

    for tamam, metin in sonuc:
        print(f"{'GECTI' if tamam else 'DUSTU'}  {metin}")
    for h in hatalar:
        print(f"  {h}")
    gecen = sum(1 for t, _ in sonuc if t)
    print(f"=== duman: {gecen}/3 ===")
    return 0 if gecen == 3 else 1


if __name__ == "__main__":
    sys.exit(main())
