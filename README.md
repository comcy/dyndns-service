# DynDNS Update Skript für INWX

Dieses Skript aktualisiert automatisch die IPv4- und IPv6-Adressen für einen bei INWX konfigurierten DynDNS-Eintrag.

## 1. Voraussetzungen & Installation

Stelle sicher, dass auf deinem System (z.B. dein Ubuntu LXC) **Node.js** und **npm** installiert sind.

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
    
    Füge folgenden Inhalt in die `.env`-Datei ein und ersetze die Platzhalter mit den Daten deines **DynDNS-Benutzers**:
    ```env
    INWX_USER=dein_dyndns_benutzername
    INWX_PASS=dein_dyndns_passwort
    ```

## 2. Ausführung als Dienst (empfohlen)

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