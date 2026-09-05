# mesh-ear / vorlesen

**Ein Ohr im Mesh** — lokale Text-zu-Sprache mit Piper (Thorsten, Deutsch), koordiniert über mehrere Maschinen per `flock` und SSH.

*English: Single-ear TTS CLI for a Tailscale mesh — Piper Thorsten voice, mesh-wide audio lock, no cloud APIs.*

## Überblick

| Komponente | Zweck |
|------------|--------|
| `vorlesen` | Einstieg: nimmt Text (Argument oder stdin) und spricht vor |
| `pycoach-speak` | Piper-Synthese + Wiedergabe, Mesh-Sperre |
| `mesh-ear-lock.sh` | Eine Spur Audio — lokales `flock` oder Remote-SSH auf dem Ear-Host |

Statusmeldungen erscheinen auf **stderr** (z. B. `▶ Nachricht angenommen`, `… warte auf Mesh-Ohr`, `✓ fertig`).

## Installation

```bash
git clone git@github.com:smlfg/mesh-ear.git
cd mesh-ear
./install.sh
```

Danach `~/.local/bin` im PATH (install.sh ergänzt `.bashrc` / `.zshrc` idempotent).

### Piper-Modell (nicht im Repo)

Dateien nach `~/.local/share/pycoach-tts/`:

- `de_DE-thorsten-high.onnx`
- `de_DE-thorsten-high.onnx.json`

Quelle: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices) — Stimme `de_DE/thorsten/high`.

Piper-Binary: `pip install piper-tts` oder Release von [rhasspy/piper](https://github.com/rhasspy/piper/releases).

## Nutzung

```bash
vorlesen "Guten Morgen, das Mesh hat ein Ohr."
echo "Markdown **fett** und \`code\` werden bereinigt." | vorlesen
```

## Mesh-Ohr

Nur **ein** Vorlese-Vorgang gleichzeitig im gesamten Mesh (pop-os / thinkpad als Ear-Hosts). Andere Rechner warten per SSH auf `flock` am Ear-Host.

Details: [docs/MESH-EAR.md](docs/MESH-EAR.md)

## Lizenz

MIT — Copyright (c) 2026 Samuel Fleig. Siehe [LICENSE](LICENSE).
