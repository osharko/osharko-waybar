#!/bin/bash

#
# Script per configurare automaticamente una connessione di rete bridge
# utilizzando l'interfaccia di rete primaria attiva.
#
# USO:
# 1. Salva questo file (es. configura_bridge.sh)
# 2. Rendilo eseguibile: chmod +x configura_bridge.sh
# 3. Eseguilo con sudo: sudo ./configura_bridge.sh
#

# Interrompe lo script in caso di errore
set -e

echo "--- Avvio dello script di configurazione del bridge di rete ---"

# --- 1. Pulizia preventiva ---
# Per rendere lo script eseguibile più volte, prima eliminiamo le vecchie
# configurazioni del bridge, se esistono. Gli errori vengono ignorati se non esistono.
echo "[1/5] Eseguo la pulizia di configurazioni bridge precedenti..."
(sudo nmcli con delete br0 && sudo nmcli con delete br0-slave) >/dev/null 2>&1 || true
echo "Pulizia completata."


# --- 2. Rilevamento dinamico dell'interfaccia ---
# Trova l'interfaccia di rete attualmente connessa a internet.
echo "[2/5] Rilevo l'interfaccia di rete attiva..."
ACTIVE_INTERFACE=$(ip route get 1.1.1.1 | grep -oP 'dev \K\S+')

if [ -z "$ACTIVE_INTERFACE" ]; then
    echo "ERRORE: Impossibile trovare un'interfaccia di rete attiva. Uscita."
    exit 1
fi

# Dobbiamo trovare anche il NOME della connessione associata a quell'interfaccia.
ACTIVE_CONNECTION=$(nmcli -t -f NAME,DEVICE con show --active | grep ":${ACTIVE_INTERFACE}$" | cut -d ':' -f 1)

if [ -z "$ACTIVE_CONNECTION" ]; then
    echo "ERRORE: Impossibile trovare un nome di connessione per l'interfaccia ${ACTIVE_INTERFACE}. Uscita."
    exit 1
fi

echo "Rilevata interfaccia attiva: '${ACTIVE_INTERFACE}' (usata dalla connessione: '${ACTIVE_CONNECTION}')"


# --- 3. Creazione del bridge ---
echo "[3/5] Creo la nuova connessione bridge 'br0'..."
# Crea la connessione bridge
sudo nmcli con add type bridge con-name br0 ifname br0
# Imposta il bridge per ottenere l'IP dal router (DHCP)
sudo nmcli con modify br0 ipv4.method auto
# Crea la connessione "slave" che lega l'interfaccia fisica al bridge
sudo nmcli con add type bridge-slave con-name br0-slave ifname "$ACTIVE_INTERFACE" master br0
echo "Bridge 'br0' e 'br0-slave' creati."


# --- 4. Attivazione del bridge ---
# Attivando il bridge, NetworkManager dovrebbe disattivare automaticamente la
# vecchia connessione che usava l'interfaccia fisica.
echo "[4/5] Attivo il bridge 'br0'..."
sudo nmcli con up br0
echo "Bridge attivato. Attendo un istante per l'assegnazione dell'IP..."
sleep 5 # Diamo qualche secondo alla rete per stabilizzarsi


# --- 5. Verifica e pulizia finale ---
# Controlliamo che br0 abbia ottenuto un IP prima di fare pulizia.
if ip -4 addr show br0 | grep -q "inet"; then
    echo "[5/5] Il bridge 'br0' è attivo e ha un IP. Rimuovo la vecchia connessione per sicurezza."
    sudo nmcli con delete "$ACTIVE_CONNECTION"
    echo ""
    echo "--- CONFIGURAZIONE COMPLETATA CON SUCCESSO! ---"
    echo "La tua rete ora passa attraverso il bridge 'br0'."
    ip -4 addr show br0 | grep "inet"
else
    echo ""
    echo "--- ERRORE ---"
    echo "Il bridge 'br0' non è riuscito a ottenere un indirizzo IP."
    echo "La configurazione potrebbe essere incompleta. Controlla lo stato con 'ip a' e 'nmcli con show'."
    exit 1
fi

exit 0
