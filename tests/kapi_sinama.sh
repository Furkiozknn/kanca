#!/usr/bin/env bash
# tests/kapi.sh'in kendi sinamasi. Godot gerektirmez; CI'da her push'ta kosar.
# Gunluk ornekleri gercek Godot 4.7.2 ciktisinin bicimini izler
# (25 Eylul 2026: 115/115 test; bot denetimi 14 bolum).
set -uo pipefail

kok="$(cd "$(dirname "$0")" && pwd)"
kapi="$kok/kapi.sh"
gecici="$(mktemp -d)"
trap 'rm -rf "$gecici"' EXIT
basarisiz=0

# $1 ad, $2 beklenen cikis (0 gecer / 1 duser), $3.. kapi.sh bayraklari + taban,
# stdin gunluk
bekle() {
  local ad="$1" beklenen="$2" dosya="$gecici/$1.log" kod
  shift 2
  cat >"$dosya"
  local arg=("$@")
  local taban="${arg[-1]}"
  unset 'arg[-1]'
  bash "$kapi" "${arg[@]}" "$dosya" "$taban" >/dev/null 2>&1
  kod=$?
  if [ "$kod" -eq "$beklenen" ]; then
    echo "  tamam  $ad (cikis $kod)"
  else
    echo "  HATA   $ad: beklenen $beklenen, gelen $kod"
    basarisiz=$((basarisiz + 1))
  fi
}

echo "[test kapisi]"

bekle temiz 0 115 <<'EOF2'
=== Kanca testleri ===
  GECTI  menzil disindaki noktaya kanca takilmaz
  GECTI  olculmus esikler
=== 115/115 gecti ===
WARNING: 40 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 3 resources still in use at exit (run with --verbose for details).
EOF2

bekle tabandan_fazla 0 115 <<'EOF2'
=== 120/120 gecti ===
EOF2

bekle test_kaldi 1 115 <<'EOF2'
  KALDI  menzil icindeki noktaya kanca takilir
=== 114/115 gecti ===
EOF2

# Asil kapattigi aciklik: bir test fonksiyonu calisma zamani hatasiyla
# kesildi, kalan _bildir() cagrilari yapilmadi -- toplam da kuculdu -- ama
# takim yine "N/N" ile 0 dondu.
bekle betik_hatasi_sessiz_atlama 1 115 <<'EOF2'
SCRIPT ERROR: Invalid access to property or key 'konum' on a base object of type 'Nil'.
          at: _test_ruzgar (res://tests/test_kanca.gd:600)
=== 111/111 gecti ===
EOF2

bekle betik_hatasi_sayi_tam 1 115 <<'EOF2'
SCRIPT ERROR: Invalid operands 'int' and 'bool' in operator '=='.
=== 115/115 gecti ===
EOF2

bekle derleme_hatasi 1 115 <<'EOF2'
SCRIPT ERROR: Parse Error: Identifier "Bolumler" not declared in the current scope.
EOF2

bekle tabanin_alti 1 115 <<'EOF2'
=== 110/110 gecti ===
EOF2

bekle sonuc_satiri_yok 1 115 <<'EOF2'
=== Kanca testleri ===
  GECTI  menzil disindaki noktaya kanca takilmaz
EOF2

bekle bos_gunluk 1 115 </dev/null

echo "[bot denetim kapisi]"

bekle bot_temiz 0 --bot 14 <<'EOF2'
DENETIM KIPI: dosya yazilmaz, yazilmis esikler yeniden olculup sinanir
--- denetim: yayimlanan esik vs bugunku kosu ---

denetim temiz: 14 bolumun hepsi bitiyor, her altin esigi botun bugunku ortancasini kaldiriyor.
=== denetim bitti: 14/14 bolum kosuldu ===
ERROR: 9 resources still in use at exit (run with --verbose for details).
EOF2

bekle bot_betik_hatasi 1 --bot 14 <<'EOF2'
SCRIPT ERROR: Invalid call. Nonexistent function 'kos' in base 'Nil'.
denetim temiz: 14 bolumun hepsi bitiyor, her altin esigi botun bugunku ortancasini kaldiriyor.
=== denetim bitti: 14/14 bolum kosuldu ===
EOF2

bekle bot_eksik_kosu 1 --bot 14 <<'EOF2'
denetim temiz: 14 bolumun hepsi bitiyor, her altin esigi botun bugunku ortancasini kaldiriyor.
=== denetim bitti: 13/14 bolum kosuldu ===
EOF2

bekle bot_tabanin_alti 1 --bot 14 <<'EOF2'
denetim temiz: 13 bolumun hepsi bitiyor, her altin esigi botun bugunku ortancasini kaldiriyor.
=== denetim bitti: 13/13 bolum kosuldu ===
EOF2

bekle bot_basarisiz 1 --bot 14 <<'EOF2'
DENETIM BASARISIZ: 1 bulgu.
=== denetim bitti: 14/14 bolum kosuldu ===
EOF2

if [ "$basarisiz" -ne 0 ]; then
  echo "=== test kapisi: $basarisiz sinama basarisiz ==="
  exit 1
fi
echo "=== test kapisi: tum sinamalar gecti ==="
