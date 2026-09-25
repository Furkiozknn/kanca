#!/usr/bin/env bash
# Test kapisi: test_kanca.tscn'in cikis kodu tek basina yeterli bir sinyal degil.
#
#   tests/kapi.sh <test-gunlugu> <en-az-gecen>          # tests/test_kanca.tscn
#   tests/kapi.sh --bot <bot-gunlugu> <en-az-bolum>     # tools/rota.tscn -- --denetle
#
# test_kanca.gd `quit(_kalan)` ile cikiyor. Oysa GDScript'te bir calisma
# zamani hatasi (null erisimi, int == bool, eksik metot) yalnizca o
# fonksiyonu keser: motor "SCRIPT ERROR" yazar, fonksiyonun kalan
# _bildir() cagrilari hic yapilmaz -- toplam da kuculur -- ve takim yine
# "=== N/N gecti ===" ile 0 dondurur. Yani bir test bolumu sessizce yarida
# kalabilir ve CI yesil kalir. Bot denetimi icin de ayni.
#
# Test kipi gunlugu okuyup uc seyi zorunlu kilar:
#   1. "=== G/T gecti ===" satiri var (takim sonuna kadar kostu) ve G == T,
#   2. G >= en-az-gecen (ci.yml -> TEST_TABANI; sayi bilinen tabanin altina
#      dusmedi),
#   3. gunlukte "SCRIPT ERROR" / "Parse Error" yok.
# Bot kipi: "denetim temiz" ve "=== denetim bitti: K/N bolum kosuldu ==="
# satirlari var, K == N, N >= en-az-bolum, betik hatasi yok.
#
# Motorun cikista yazdigi "ERROR: N resources still in use at exit" satiri
# test sonucuyla ilgili degil; onu bilerek aramiyoruz.
#
# Sinamasi: tests/kapi_sinama.sh (Godot gerektirmez).
set -euo pipefail

kip=test
if [ "${1:-}" = "--bot" ]; then
  kip=bot
  shift
fi
if [ "$#" -ne 2 ]; then
  echo "kullanim: $0 [--bot] <gunluk> <en-az>" >&2
  exit 2
fi
gunluk="$1"
alt_sinir="$2"

if [ ! -r "$gunluk" ]; then
  echo "KAPI: gunluk okunamadi: $gunluk" >&2
  exit 1
fi

if grep -anE 'SCRIPT ERROR|Parse Error' "$gunluk" >&2; then
  echo "KAPI: gunlukte betik hatasi var (yukarida). Bir bolum yarida kesilmis olabilir." >&2
  exit 1
fi

if [ "$kip" = bot ]; then
  if ! grep -aqE '^denetim temiz: [0-9]+ bolumun hepsi bitiyor' "$gunluk"; then
    echo "KAPI: 'denetim temiz' satiri yok; denetim temiz bitmedi." >&2
    exit 1
  fi
  satir="$(grep -aoE '^=== denetim bitti: [0-9]+/[0-9]+ bolum kosuldu ===$' "$gunluk" | tail -n 1 || true)"
  if [ -z "$satir" ]; then
    echo "KAPI: '=== denetim bitti: K/N bolum kosuldu ===' satiri yok." >&2
    exit 1
  fi
  kosulan="$(sed -E 's#^=== denetim bitti: ([0-9]+)/([0-9]+) .*$#\1#' <<<"$satir")"
  toplam="$(sed -E 's#^=== denetim bitti: ([0-9]+)/([0-9]+) .*$#\2#' <<<"$satir")"
  if [ "$kosulan" -ne "$toplam" ]; then
    echo "KAPI: denetim $kosulan/$toplam bolum kostu." >&2
    exit 1
  fi
  if [ "$toplam" -lt "$alt_sinir" ]; then
    echo "KAPI: denetim $toplam bolum, taban $alt_sinir." >&2
    exit 1
  fi
  echo "KAPI: denetim temiz, $kosulan/$toplam bolum (taban $alt_sinir), betik hatasi yok."
  exit 0
fi

sonuc="$(grep -aoE '^=== [0-9]+/[0-9]+ gecti ===$' "$gunluk" | tail -n 1 || true)"
if [ -z "$sonuc" ]; then
  echo "KAPI: '=== G/T gecti ===' satiri yok; takim sonuna kadar kosmadi." >&2
  exit 1
fi

gecen="$(sed -E 's#^=== ([0-9]+)/([0-9]+) gecti ===$#\1#' <<<"$sonuc")"
toplam="$(sed -E 's#^=== ([0-9]+)/([0-9]+) gecti ===$#\2#' <<<"$sonuc")"

if [ "$gecen" -ne "$toplam" ]; then
  echo "KAPI: $((toplam - gecen)) test kaldi ($gecen/$toplam)." >&2
  exit 1
fi
if [ "$gecen" -lt "$alt_sinir" ]; then
  echo "KAPI: $gecen test gecti, taban $alt_sinir. Bir bolum atlanmis ya da yarida kalmis." >&2
  exit 1
fi

echo "KAPI: $gecen/$toplam gecti (taban $alt_sinir), betik hatasi yok."
