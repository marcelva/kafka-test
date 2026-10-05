# Heizbericht am Abend – Home Assistant Blueprint

Schickt jeden Abend einen Bericht, **in welchem Raum wie oft (und wie lange) geheizt wurde**. Räume, in denen nicht geheizt werden soll, werden mit 🚨 markiert.

[![Blueprint in Home Assistant importieren](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2FDEIN-USER%2FDEIN-REPO%2Fblob%2Fmain%2Fheizbericht_abend.yaml)

Beispiel:

```text
🔥 Heizbericht Montag, 05.10.2026
Räume mit Heizphasen: 3/4 · Heizphasen gesamt: 11

⚠️ Wohnzimmer: 6× · 3 h 06 min
🚨 Bad: 3× · 1 h 20 min – sollte aus sein!
• Küche: 2× · 45 min

Nicht geheizt: Schlafzimmer
Keine Daten: Flur
```

## Voraussetzungen

- Home Assistant 2025.12 oder neuer
- Thermostate als `climate`-Entität mit dem Attribut `hvac_action` (Prüfen: Entwicklerwerkzeuge → Zustände). Gilt z. B. für Rademacher/HomePilot nicht automatisch, siehe Hinweise.

## Schritt 1: Sensoren pro Raum anlegen

Ein Blueprint kann keine Helfer erzeugen. Pro Raum brauchst du:

1. **Template → Binärsensor** (Einstellungen → Geräte & Dienste → Helfer):
   `{{ is_state_attr('climate.bad', 'hvac_action', 'heating') }}`
2. **Verlaufsstatistik** auf diesen Binärsensor: Status `on`, Typ **Anzahl**, Start `{{ today_at() }}`, Ende `{{ now() }}`
3. *(optional)* **Verlaufsstatistik** wie in 2., Typ **Zeit**

Alternativ per YAML:

```yaml
template:
  - binary_sensor:
      - name: "Heizen Bad"
        unique_id: heizen_bad
        state: "{{ is_state_attr('climate.bad', 'hvac_action', 'heating') }}"

sensor:
  - platform: history_stats
    name: "Heizen Bad Anzahl"
    unique_id: heizen_bad_anzahl
    entity_id: binary_sensor.heizen_bad
    state: "on"
    type: count
    start: "{{ today_at() }}"
    end: "{{ now() }}"
  - platform: history_stats
    name: "Heizen Bad Zeit"
    unique_id: heizen_bad_zeit
    entity_id: binary_sensor.heizen_bad
    state: "on"
    type: time
    start: "{{ today_at() }}"
    end: "{{ now() }}"
```

## Schritt 2: Blueprint importieren

Auf den Button oben klicken oder: Einstellungen → Automatisierungen & Szenen → Blaupausen → Blaupause importieren → URL der YAML-Datei einfügen.

## Schritt 3: Automation anlegen

- **Räume:** Pro Raum Name, Sensor „Anzahl“, optional Sensor „Zeit“. „Hier sollte nicht geheizt werden“ aktivieren, wenn dort jede Heizphase unerwartet wäre.
- **Aktion zum Senden:** Standard ist eine Meldung in der Oberfläche. Für das Handy „Benachrichtigung senden“ wählen, Titel `{{ report_title }}`, Nachricht `{{ report_message }}`.
- **Uhrzeit / Wochentage:** Standard 21:00, täglich.

## Variablen für eigene Aktionen

| Variable | Inhalt |
| --- | --- |
| `report_title` | Titel mit Wochentag und Datum |
| `report_message` | Fertiger Berichtstext |
| `report_rows` | Liste je Raum: `name`, `valid`, `count`, `minutes`, `heated`, `expect_off` |
| `report_alert` | `true`, wenn in einem als „sollte aus sein“ markierten Raum geheizt wurde |

## Hinweise

- Den Zeitraum (z. B. „heute“) bestimmen die History-Stats-Sensoren, nicht der Blueprint.
- „Anzahl“ zählt Wechsel in den Zustand `on`. Läuft das Heizen über Mitternacht, kann „Anzahl“ 0 sein, „Zeit“ aber größer als 0. Der Raum zählt dann trotzdem als geheizt.
- Fehlt `hvac_action` an deiner Entität, ist ein Ersatz möglich (ungenauer): `{{ state_attr('climate.bad', 'current_temperature') | float(99) < state_attr('climate.bad', 'temperature') | float(0) }}`
- Bei der Rademacher-Integration steht der Auto-Modus als HVAC-Modus der `climate`-Entität. Ein Raum auf `auto` kann also nach dem HomePilot-Zeitprogramm heizen.

## Vor dem Veröffentlichen anpassen

In `heizbericht_abend.yaml`: `author` und `source_url`. In dieser README: `DEIN-USER/DEIN-REPO` in der Badge-URL. Der Pfad in `source_url` muss zum Speicherort im Repository passen.

## Status

Syntax und Templates sind gegen die offizielle Blueprint-Dokumentation (Home Assistant 2026.9) und mit lokalen Render-Tests geprüft. Ein Lauf auf einer echten Instanz steht aus: Beim ersten Durchlauf bitte die Ablaufverfolgung der Automation ansehen.
