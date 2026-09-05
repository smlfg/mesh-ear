#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
TTS_DIR="${HOME}/.local/share/pycoach-tts"
PATH_MARKER="# === vorlesen (Interconnect) ==="

mkdir -p "$BIN_DIR" "$TTS_DIR"

OS="$(uname -s)"
case "$OS" in
  Linux)
    SPEAK_SRC="$SCRIPT_DIR/bin/pycoach-speak.linux"
    ;;
  Darwin)
    SPEAK_SRC="$SCRIPT_DIR/bin/pycoach-speak.macos"
    ;;
  *)
    echo "install.sh: unsupported OS: $OS" >&2
    exit 1
    ;;
esac

if [[ ! -f "$SPEAK_SRC" ]]; then
  echo "install.sh: fehlende Quelle: $SPEAK_SRC" >&2
  exit 1
fi

install -m 755 "$SCRIPT_DIR/bin/vorlesen" "$BIN_DIR/vorlesen"
install -m 755 "$SCRIPT_DIR/bin/mesh-ear-lock.sh" "$BIN_DIR/mesh-ear-lock.sh"
install -m 755 "$SPEAK_SRC" "$BIN_DIR/pycoach-speak"

add_path_block() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  if grep -qF "$PATH_MARKER" "$rc" 2>/dev/null; then
    return 0
  fi
  cat >>"$rc" <<EOF

$PATH_MARKER
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  export PATH="$BIN_DIR:\$PATH"
fi
EOF
}

add_path_block "${HOME}/.bashrc"
add_path_block "${HOME}/.zshrc"

echo "✓ vorlesen installiert nach $BIN_DIR"
echo ""
echo "Piper-Modell (nicht im Repo — manuell installieren):"
echo "  Zielverzeichnis: $TTS_DIR"
echo "  Benötigt:"
echo "    de_DE-thorsten-high.onnx"
echo "    de_DE-thorsten-high.onnx.json"
echo ""
echo "Beispiel (Rhasspy Piper-Stimmen, URLs je nach Release prüfen):"
echo "  mkdir -p $TTS_DIR"
echo "  cd $TTS_DIR"
echo "  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx"
echo "  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high/de_DE-thorsten-high.onnx.json"
echo ""
echo "Piper-Binary: pip install piper-tts  oder  https://github.com/rhasspy/piper/releases"
echo ""
echo "Mesh-Ohr (ein Lautsprecher über mehrere Maschinen): siehe docs/MESH-EAR.md"
echo "  Standard Ear-Host: pop-os  (überschreiben: export MESH_EAR_HOST=…)"
echo ""
echo "Nutzung:"
echo "  vorlesen \"Hallo Welt\""
echo "  echo \"Text\" | vorlesen"
