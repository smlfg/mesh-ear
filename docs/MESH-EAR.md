# Mesh-Ohr (MESH-EAR)

## Warum ein Ohr?

In einem Mesh aus mehreren Rechnern und Agenten (Hermes, Cursor, Skripte) soll **nur eine Spur** gleichzeitig über die Lautsprecher laufen. Ohne Koordination würden parallele TTS-Aufrufe sich überlagern.

Das **Mesh-Ohr** ist ein verteilter Mutex: ein Lockfile auf dem Ear-Host, den alle Teilnehmer respektieren — lokal per `flock`, von anderen Maschinen per SSH.

## Ear-Host

Standard: **`pop-os`** (alternativ lokale Ear-Maschinen: `thinkpad`).

| Umgebung | Verhalten |
|----------|-----------|
| Hostname `pop-os` oder `thinkpad` | Lokales `flock` auf dem Lockfile |
| Anderer Host | SSH zu `MESH_EAR_HOST`, Remote-`flock` bis Freigabe |

Lockfile (Datei, kein Verzeichnis):

```
~/.local/share/pycoach-tts/mesh-ear.lock
```

Elternverzeichnis wird bei Bedarf erstellt; die Datei wird mit `: >> lockfile` angelegt.

## Umgebungsvariable

```bash
export MESH_EAR_HOST=pop-os   # Standard, falls unset
```

Überschreibt den Ziel-Host für Remote-Sperren. Wenn `MESH_EAR_HOST` dem lokalen Hostnamen entspricht, wird lokal gesperrt.

## Ablauf (Remote)

1. Client: `… warte auf Mesh-Ohr (eine Spur)` auf stderr
2. SSH zum Ear-Host startet Hintergrundprozess
3. Remote: `flock -x` auf `mesh-ear.lock`, dann Hold-Token in `/tmp/mesh-ear-<pid>-<ts>.hold`
4. Client pollt `/tmp/…ready`, sobald Lock gehalten ist → Synthese/Wiedergabe
5. `mesh_ear_release`: Hold-Token entfernen → Remote-`flock` endet, SSH-Prozess beendet

Lokal (Ear-Host): ein Dateideskriptor + `flock -x`, Freigabe per `flock -u`.

## Hermes / speak.py

Hermes-`speak.py` (oder andere Python-Aufrufer) sollten **dieselbe Lockdatei** mit `fcntl.flock` verwenden — gleicher Pfad, gleiche Semantik. So teilen sich Shell- und Python-Pfade eine Spur.

## Voraussetzungen (Remote)

- **Tailscale** (oder vertrauenswürdiges Netz) zwischen den Maschinen
- **SSH** ohne Passwort zum Ear-Host (`BatchMode=yes`): Schlüssel in `~/.ssh/authorized_keys` auf pop-os
- Hostname `pop-os` / `thinkpad` per SSH erreichbar (oder `MESH_EAR_HOST` setzen)

## API (sourceable)

```bash
source mesh-ear-lock.sh
mesh_ear_acquire    # blockiert bis Spur frei
# … Audio …
mesh_ear_release    # optional; pycoach-speak nutzt trap EXIT
```

`pycoach-speak` bindet acquire/release automatisch ein.

## Fehler

- SSH fehlgeschlagen → Meldung auf stderr, kein stilles Scheitern
- Zeitüberschreitung (~150 s Warten auf Remote-Ready) → Abbruch mit Cleanup
