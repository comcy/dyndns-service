# DynDNS Update Skript für INWX

Dieses Skript aktualisiert automatisch die IPv4- und IPv6-Adressen für einen bei INWX konfigurierten DynDNS-Eintrag.

## 1. Voraussetzungen & Installation

Stelle sicher, dass auf deinem System (z.B. dein Ubuntu LXC) **Node.js** und **npm** installiert sind.

**Empfehlung:** Verwende das `setup.sh`-Skript für eine automatisierte Einrichtung.

### 1.1 Automatisierte Einrichtung mit `setup.sh` (Empfohlen)

Das `setup.sh`-Skript automatisiert die Installation der Abhängigkeiten, die Erstellung der `.env`-Datei und die Einrichtung des systemd-Dienstes.

1.  **Projekt herunterladen/klonen:**
    ```bash
    git clone <repository_url>
    cd dyndns-service
    ```

2.  **Setup-Skript ausführen:**
    Führe das Skript mit Root-Rechten aus. Es wird dich interaktiv nach deinem INWX DynDNS-Benutzernamen und -Passwort fragen.
    ```bash
    sudo ./setup.sh
    ```
    Das Skript wird:
    *   Alle notwendigen Node.js-Abhängigkeiten installieren (`npm install`).
    *   Eine `.env`-Datei erstellen und deine INWX-Zugangsdaten sowie das Standard-Update-Intervall (300 Sekunden) darin speichern.
    *   Den `dyndns-update.service` systemd-Dienst korrekt konfigurieren, installieren, aktivieren und starten.

    Nach erfolgreicher Ausführung ist der Dienst aktiv. Du kannst den Status überprüfen mit:
    ```bash
    sudo systemctl status dyndns-update.service
    journalctl -u dyndns-update.service -f
    ```

### 1.2 Manuelle Konfiguration nach dem Setup-Skript oder bei Änderungen

Wenn du das Update-Intervall ändern oder andere manuelle Anpassungen vornehmen möchtest, folge diesen Schritten:

*   **Update-Intervall ändern:**
    Das Standardintervall ist 300 Sekunden (5 Minuten). Um es zu ändern, bearbeite die Datei `.env` im Projektverzeichnis und passe den Wert für `EXECUTION_INTERVAL` an (z.B. `EXECUTION_INTERVAL=600` für 10 Minuten).
    Nach der Änderung musst du den systemd-Dienst neu starten, damit die Änderungen wirksam werden:
    ```bash
    sudo systemctl restart dyndns-update.service
    ```

*   **Andere manuelle Änderungen:**
    Wenn du Änderungen am Service-Dateipfad, Benutzer oder anderen systemd-spezifischen Einstellungen vornehmen möchtest, musst du die Service-Datei unter `/etc/systemd/system/dyndns-update.service` direkt bearbeiten.
    Nach Änderungen an dieser Datei musst du `systemd` neu laden und den Dienst neu starten:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart dyndns-update.service
    ```

    Für Änderungen am Node.js-Skript selbst (z.B. in `src/dydns-update.js`), genügen diese systemd-Befehle, da der Dienst das Skript bei jedem Durchlauf neu startet.

---

### 1.3 Manuelle Einrichtung (Alternative zur automatisierten Einrichtung)

Falls du das `setup.sh`-Skript nicht verwenden möchtest, folge den Schritten für die manuelle Einrichtung:

1.  **Projekt herunterladen/kopieren:**
    Klone dieses Repository oder kopiere die Dateien auf dein System.
    ```bash
    git clone <repository_url>
    cd dyndns-service
    ```

2.  **Abhängigkeiten installieren:**
    Führe im Projektverzeichnis folgenden Befehl aus:
    ```bash
    npm install
    ```

3.  **.env Datei erstellen:**
    Erstelle im Hauptverzeichnis des Projekts eine Datei namens `.env`. Diese Datei enthält deine DynDNS-Zugangsdaten.

    **Wichtig:** Du musst im INWX Web-Interface unter "DynDNS" einen separaten DynDNS-Benutzer anlegen und diesem den zu aktualisierenden Hostnamen zuweisen.

    Füge folgenden Inhalt in die `.env`-Datei ein und ersetze die Platzhalter:
    ```env
    # --- INWX DynDNS Zugangsdaten ---
    # (Diese erhältst du im INWX Web-Interface unter "DynDNS")
    INWX_USER=dein_dyndns_benutzername
    INWX_PASS=dein_dyndns_passwort

    # --- Service Konfiguration ---
    # Intervall in Sekunden, in dem der Service nach Beendigung neu gestartet wird.
    EXECUTION_INTERVAL=300
    ```

## 2. Ausführung als Dienst

Hier sind zwei gängige Methoden, um das Skript automatisiert auszuführen.

### Methode A: Systemd Service (für moderne Linux-Systeme)

Diese Methode ist robust und sorgt dafür, dass das Skript automatisch nach einem Neustart gestartet und bei Fehlern neu versucht wird.

1.  **Service-Datei anpassen:**
    Öffne die mitgelieferte `dyndns-update.service`-Datei. Du musst zwei Platzhalter ersetzen:
    -   `<BENUTZER>`: Der Linux-Benutzer, unter dem das Skript laufen soll (z.B. `root` oder dein eigener Benutzer).
    -   `<PFAD_ZUM_PROJEKT>`: Der **absolute Pfad** zum `dyndns-service`-Verzeichnis auf deinem Server (z.B. `/home/cy/dyndns-service`).

2.  **Service-Datei installieren:**
    Kopiere die angepasste Datei in das systemd-Verzeichnis:
    ```bash
    sudo cp dyndns-update.service /etc/systemd/system/dyndns-update.service
    ```

3.  **Systemd aktivieren und starten:**
    Führe die folgenden Befehle aus, um den Dienst zu aktivieren und zu starten:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable dyndns-update.service
    sudo systemctl start dyndns-update.service
    ```

4.  **(Optional) Status überprüfen:**
    Du kannst jederzeit den Status des Dienstes und seine Log-Ausgaben überprüfen:
    ```bash
    sudo systemctl status dyndns-update.service
    journalctl -u dyndns-update.service -f
    ```
    Der Dienst wird nun alle 5 Minuten (siehe `RestartSec=300` in der `.service`-Datei) nach einem Fehler neu gestartet. Ein erfolgreicher Durchlauf beendet das Skript, und der nächste Restart-Timer wird gesetzt.

### Methode B: Cronjob

Ein Cronjob ist eine einfachere Alternative, die das Skript in einem festen Zeitintervall ausführt.

1.  **Crontab öffnen:**
    Öffne die Crontab-Datei für deinen Benutzer:
    ```bash
    crontab -e
    ```

2.  **Cronjob hinzufügen:**
    Füge die folgende Zeile am Ende der Datei hinzu. Ersetze `<PFAD_ZUM_PROJEKT>` mit dem **absoluten Pfad** zum Projektverzeichnis.

    ```crontab
    # Führe das DynDNS-Update alle 15 Minuten aus
    */15 * * * * /usr/bin/node <PFAD_ZUM_PROJEKT>/src/dydns-update.js >> <PFAD_ZUM_PROJEKT>/dyndns.log 2>&1
    ```

    -   `*/15 * * * *`: Führt den Befehl alle 15 Minuten aus.
    -   `/usr/bin/node`: Der absolute Pfad zu Node.js. Du kannst den Pfad auf deinem System mit `which node` überprüfen.
    -   `>> ... 2>&1`: Leitet die gesamte Ausgabe (Standard und Fehler) in eine Log-Datei namens `dyndns.log` im Projektverzeichnis um. Das ist nützlich für die Fehlersuche.

Speichere und schließe die Datei. Der Cronjob ist damit aktiv.
