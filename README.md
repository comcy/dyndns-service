# DynDNS Update Skript für INWX

Dieses Skript aktualisiert automatisch die IPv4- und IPv6-Adressen für einen bei INWX konfigurierten DynDNS-Eintrag.

## 1. Funktionsweise

Das Skript wird periodisch mittels eines **systemd Timers** ausgeführt. Bei jeder Ausführung:
1.  Ermittelt es die aktuelle öffentliche IPv4- und IPv6-Adresse des Systems.
2.  Sendet es diese Adressen an die INWX DynDNS API.
3.  Protokolliert es den gesamten Vorgang im systemd Journal.

## 2. Einrichtung

### 2.1 Speicherort (Empfehlung)

Für einen systemweiten Dienst ist es empfehlenswert, das Projekt nicht im Home-Verzeichnis eines Benutzers, sondern an einem zentralen Ort wie `/opt` abzulegen.

```bash
# Beispiel für das Klonen nach /opt
sudo git clone <repository_url> /opt/dyndns-service
cd /opt/dyndns-service
```

### 2.2 Automatisierte Einrichtung mit `setup.sh` (Empfohlen)

Das `setup.sh`-Skript automatisiert die komplette Einrichtung.

1.  **Voraussetzungen:** Stelle sicher, dass `git`, `node` und `npm` installiert sind.
2.  **Skript ausführen:** Führe das Skript mit Root-Rechten aus. Es wird dich interaktiv nach deinem INWX DynDNS-Benutzernamen und -Passwort fragen.
    ```bash
    sudo ./setup.sh
    ```
    Das Skript wird:
    *   Alle notwendigen Node.js-Abhängigkeiten installieren (`npm install`).
    *   Eine `.env`-Datei für deine INWX-Zugangsdaten erstellen.
    *   Den `dyndns-update.service` und den `dyndns-update.timer` korrekt konfigurieren, installieren, aktivieren und starten.

    Nach erfolgreicher Ausführung ist der Timer aktiv.
    
    *   **Timer-Status prüfen:**
        ```bash
        sudo systemctl list-timers | grep dyndns
        ```
    *   **Logs einsehen:**
        ```bash
        sudo journalctl -u dyndns-update.service -f
        ```

### 2.3 Manuelle Konfiguration und Änderungen

*   **Update-Intervall ändern:**
    Das Standardintervall ist in der Datei `dyndns-update.timer` auf 5 Minuten (`OnUnitActiveSec=5min`) festgelegt. Um es zu ändern, bearbeite die Datei direkt im Projektverzeichnis und führe danach das `setup.sh`-Skript erneut aus. Das Skript kopiert die geänderte Datei an die richtige Stelle und lädt den systemd-Daemon neu.
    Alternativ kannst du die installierte Datei `/etc/systemd/system/dyndns-update.timer` direkt bearbeiten und danach folgende Befehle ausführen:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart dyndns-update.timer
    ```

*   **Zugangsdaten ändern:**
    Bearbeite die `.env`-Datei im Projektverzeichnis. Ein Neustart des Dienstes ist nicht nötig, da die Datei bei jeder Ausführung neu eingelesen wird.

*   **Manuelle Einrichtung (ohne `setup.sh`):**
    1.  Installiere die Abhängigkeiten: `npm install`
    2.  Erstelle die `.env`-Datei manuell (siehe `setup.sh` als Vorlage).
    3.  Passe die Platzhalter `<BENUTZER>` und `<PFAD_ZUM_PROJEKT>` in der `dyndns-update.service`-Datei an.
    4.  Kopiere die `dyndns-update.service` und `dyndns-update.timer` nach `/etc/systemd/system/`.
    5.  Führe folgende Befehle aus:
        ```bash
        sudo systemctl daemon-reload
        sudo systemctl enable dyndns-update.timer
        sudo systemctl start dyndns-update.timer
        ```

## 3. Deinstallation

Um den Dienst vollständig von deinem System zu entfernen, wird ein Deinstallations-Skript mitgeliefert.

1.  **Wechsle in das Projektverzeichnis:**
    ```bash
    cd /pfad/zum/dyndns-service
    ```

2.  **Deinstallations-Skript ausführen:**
    Führe das Skript mit Root-Rechten aus.
    ```bash
    sudo ./uninstall.sh
    ```
    Das Skript wird:
    *   Den systemd Timer und Service stoppen und deaktivieren.
    *   Die systemd-Dateien aus `/etc/systemd/system` entfernen.
    *   Dich fragen, ob das gesamte Projektverzeichnis (inklusive deiner Konfiguration) ebenfalls gelöscht werden soll.

## 4. Alternative Methode: Cronjob (Veraltet)

Ein Cronjob kann ebenfalls verwendet werden, die empfohlene Methode ist jedoch der systemd Timer, da er eine bessere Integration in das System (Logging, Status-Abfragen) bietet.
```bash
# Führe das DynDNS-Update alle 15 Minuten aus
*/15 * * * * /usr/bin/node <PFAD_ZUM_PROJEKT>/src/dydns-update.js >> <PFAD_ZUM_PROJEKT>/dyndns.log 2>&1
```
