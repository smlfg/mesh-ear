---
name: vorlesen
description: Text auf Deutsch mit Thorsten (Piper) vorlesen — vorlesen/lies vor/TTS. Mesh-Ohr-Sperre, Status auf stderr, nie still scheitern.
---

# vorlesen (Mesh-Ohr / Thorsten TTS)

## Wann diese Skill nutzen

Aktiviere diese Skill, wenn der Nutzer u. a. sagt:

- **vorlesen**, lies vor, vorlesen bitte
- **TTS**, Text-to-Speech, Sprachausgabe
- **Thorsten**, Piper, pycoach-speak
- „Lies mir das vor“, „sprich den Text“

## Grundregeln

1. **Immer Status melden** — stderr des `vorlesen`-Kommandos zeigt Fortschritt; bei Fehlern die Meldung an den Nutzer weitergeben.
2. **Nie still fehlschlagen** — wenn `vorlesen` fehlschlägt (fehlendes Modell, piper, SSH), Ursache kurz erklären.
3. **Keine Cloud-TTS** — nur lokales `vorlesen` / Piper; keine externen APIs.
4. **Mesh-Ohr** — parallele Vorlese-Aufrufe blockieren sich; das ist gewollt (eine Spur).

## Aufruf

```bash
vorlesen "Zu vorlesender Text"
```

```bash
echo "Mehrzeiliger oder piped Text" | vorlesen
```

Markdown in Argumenten wird grob bereinigt (`**`, `` ` ``, Links, Überschriften).

## Typische stderr-Ausgabe

| Zeile | Bedeutung |
|-------|-----------|
| `▶ Nachricht angenommen` | Wrapper hat Text angenommen |
| `… warte auf Mesh-Ohr (eine Spur)` | Wartet auf Mesh-Sperre |
| `… verarbeite` | Piper synthetisiert |
| `… Audio bereit` | WAV fertig |
| `▶ lese vor` | Wiedergabe startet |
| `✓ fertig` | Erfolg |

## Installation prüfen

Falls `vorlesen` nicht im PATH:

```bash
cd /path/to/mesh-ear && ./install.sh
```

Modell: `~/.local/share/pycoach-tts/de_DE-thorsten-high.onnx` (+ `.onnx.json`).

## Mesh-Ohr kurz

Ear-Host standardmäßig `pop-os`. Von anderen Hosts SSH + `flock`. Details: `docs/MESH-EAR.md` im Repo.

## Sprache

Nutzerfreundliche Antworten **auf Deutsch**; technische Logs können die stderr-Zeilen von `vorlesen` zitieren.
