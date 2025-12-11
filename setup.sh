#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "=== DynDNS Service Setup ==="

# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss mit root-Rechten (sudo) ausgeführt werden."
  exit 1
fi

# 2. Automatically determine project path and user
# Use 'logname' or '$SUDO_USER' to get the original user who invoked sudo
if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER=$SUDO_USER
else
    # Fallback for cases where SUDO_USER is not set (e.g. direct root login)
    ORIGINAL_USER=$(logname 2>/dev/null || echo "user")
fi

# Get the absolute path to the directory containing this script
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Projektverzeichnis: $PROJECT_DIR"
echo "Benutzer: $ORIGINAL_USER"

# 3. Install Node.js dependencies
echo "Installiere Node.js-Abhängigkeiten (npm install)..."
# Run npm install as the original user to avoid permission issues in the home directory
sudo -u "$ORIGINAL_USER" npm install --prefix "$PROJECT_DIR"

echo "Abhängigkeiten installiert."

# 4. Create and configure .env file
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    echo ".env-Datei existiert bereits. Überspringe Erstellung."
else
    echo "Erstelle .env-Datei..."
    # Create file and set permissions for the original user
    touch "$ENV_FILE"
    chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$ENV_FILE"
    
    # Ask user for credentials. Run read command in a subshell as the original user.
    INWX_USER=$(sudo -u "$ORIGINAL_USER" bash -c 'read -p "Bitte gib deinen INWX DynDNS-Benutzernamen ein: " val; echo $val')
    INWX_PASS=$(sudo -u "$ORIGINAL_USER" bash -c 'read -s -p "Bitte gib dein INWX DynDNS-Passwort ein: " val; echo $val')
    echo "" # newline after password input
    
    # Write to .env file
    echo "INWX_USER=${INWX_USER}" >> "$ENV_FILE"
    echo "INWX_PASS=${INWX_PASS}" >> "$ENV_FILE"
    
    echo ".env-Datei erfolgreich erstellt."
fi

# 5. Configure the systemd service and timer files
SERVICE_TEMPLATE="$PROJECT_DIR/dyndns-update.service"
CONFIGURED_SERVICE_FILE="/etc/systemd/system/dyndns-update.service"
TIMER_TEMPLATE="$PROJECT_DIR/dyndns-update.timer"
CONFIGURED_TIMER_FILE="/etc/systemd/system/dyndns-update.timer"

echo "Konfiguriere systemd Service- und Timer-Dateien..."

# Replace placeholders in the service file
sed \
  -e "s|<BENUTZER>|$ORIGINAL_USER|g" \
  -e "s|<PFAD_ZUM_PROJEKT>|$PROJECT_DIR|g" \
  "$SERVICE_TEMPLATE" > "$CONFIGURED_SERVICE_FILE"

# Copy the timer file
cp "$TIMER_TEMPLATE" "$CONFIGURED_TIMER_FILE"

echo "Service- und Timer-Dateien erstellt unter /etc/systemd/system/"

# 6. Reload systemd, enable and start the timer
echo "Lade systemd neu und starte den Timer..."
systemctl daemon-reload
systemctl enable dyndns-update.timer
systemctl start dyndns-update.timer

echo "Timer 'dyndns-update.timer' wurde aktiviert und gestartet."
echo ""
echo "Setup abgeschlossen!"
echo "Der Dienst wird nun alle 5 Minuten ausgeführt. Status der Timer:"
echo "systemctl list-timers | grep dyndns"
echo "Die Logs der einzelnen Ausführungen findest du mit 'journalctl -u dyndns-update.service'."
