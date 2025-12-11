#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "=== DynDNS Service Uninstaller ==="

# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss mit root-Rechten (sudo) ausgeführt werden."
  exit 1
fi

echo "Stoppe und deaktiviere den systemd Timer und Service..."

# 2. Stop and disable the systemd timer and service
# Use '|| true' to ignore errors if the service/timer does not exist
systemctl stop dyndns-update.timer || true
systemctl disable dyndns-update.timer || true

systemctl stop dyndns-update.service || true
systemctl disable dyndns-update.service || true

echo "Entferne systemd-Dateien..."

# 3. Remove the systemd files
rm -f /etc/systemd/system/dyndns-update.timer
rm -f /etc/systemd/system/dyndns-update.service

# 4. Reload systemd daemon
echo "Lade systemd neu..."
systemctl daemon-reload

echo "Der DynDNS systemd Service wurde erfolgreich deinstalliert."
echo ""

# 5. Ask to remove the project directory
# Get the absolute path to the directory containing this script
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if the directory exists before asking
if [ -d "$PROJECT_DIR" ]; then
    read -p "Soll das Projektverzeichnis '$PROJECT_DIR' ebenfalls gelöscht werden? (enthält deine .env Konfiguration) [j/N]: " choice
    case "$choice" in
      j|J|y|Y )
        echo "Lösche Projektverzeichnis: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        echo "Verzeichnis gelöscht."
        ;;
      * )
        echo "Das Projektverzeichnis wurde nicht gelöscht."
        echo "Du kannst es bei Bedarf manuell entfernen: rm -rf $PROJECT_DIR"
        ;;
    esac
fi

echo ""
echo "Deinstallation abgeschlossen."
