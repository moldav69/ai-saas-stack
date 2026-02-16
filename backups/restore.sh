#!/usr/bin/env bash

#############################################
# Script di restore per lo stack AI SaaS
# (n8n + AnythingLLM)
#
# Ripristina i dati da backup Google Drive
#############################################

set -euo pipefail

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory dello script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Restore Stack AI SaaS da Backup     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# Carica variabili d'ambiente
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    echo -e "${GREEN}✓${NC} Variabili caricate da .env"
else
    echo -e "${YELLOW}⚠${NC} File .env non trovato"
    echo "Se hai un backup di .env, puoi ripristinarlo durante il processo"
fi

# Verifica che rclone sia installato
if ! command -v rclone &> /dev/null; then
    echo -e "${RED}✗ rclone non è installato${NC}"
    echo "Installa rclone: https://rclone.org/install/"
    exit 1
fi

# Verifica Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker non è installato${NC}"
    exit 1
fi

# Parametro opzionale: data del backup da ripristinare
RESTORE_DATE="${1:-}"

# Funzione per selezionare automaticamente l'ultimo backup
select_latest_backup() {
    echo -e "\n${YELLOW}Ricerca dell'ultimo backup disponibile...${NC}"
    
    # Lista tutti i file sul remote
    REMOTE_FILES=$(rclone ls "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" 2>/dev/null || echo "")
    
    if [ -z "$REMOTE_FILES" ]; then
        echo -e "${RED}✗ Nessun backup trovato su ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}${NC}"
        exit 1
    fi
    
    # Estrae le date uniche dai nomi dei file
    DATES=$(echo "$REMOTE_FILES" | grep -oP '\d{4}-\d{2}-\d{2}-\d{4}' | sort -u | tail -1)
    
    if [ -z "$DATES" ]; then
        echo -e "${RED}✗ Nessun file di backup valido trovato${NC}"
        exit 1
    fi
    
    RESTORE_DATE="$DATES"
    echo -e "${GREEN}✓${NC} Trovato backup del: ${BLUE}$RESTORE_DATE${NC}"
}

# Se non è stata specificata una data, seleziona l'ultimo backup
if [ -z "$RESTORE_DATE" ]; then
    select_latest_backup
fi

# Mostra i file che verranno ripristinati
echo -e "\n${YELLOW}File da ripristinare:${NC}"
echo "  • n8n-${RESTORE_DATE}.tar.gz"
echo "  • anythingllm-${RESTORE_DATE}.tar.gz"
echo "  • env-${RESTORE_DATE}.tar.gz (opzionale)"

# Chiedi se ripristinare anche .env
RESTORE_ENV="n"
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "\n${YELLOW}⚠ Esiste già un file .env${NC}"
    read -p "Vuoi sovrascriverlo con il backup? (s/N): " RESTORE_ENV
else
    read -p "Vuoi ripristinare anche il file .env dal backup? (s/N): " RESTORE_ENV
fi

# Controlla se i container sono in esecuzione
CONTAINERS_RUNNING=$(docker compose -f "$PROJECT_ROOT/docker-compose.yml" ps -q 2>/dev/null | wc -l)

if [ "$CONTAINERS_RUNNING" -gt 0 ]; then
    echo -e "\n${YELLOW}⚠ Alcuni container sono attualmente in esecuzione${NC}"
    read -p "Vuoi fermarli automaticamente prima del restore? (s/N): " STOP_CONTAINERS
    
    if [[ "$STOP_CONTAINERS" =~ ^[sS]$ ]]; then
        echo "→ Arresto container..."
        cd "$PROJECT_ROOT"
        docker compose down
        echo -e "${GREEN}✓${NC} Container fermati"
    fi
fi

# Conferma finale prima di sovrascrivere i dati
echo -e "\n${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  ATTENZIONE: Questa operazione sovrascriverà          ║${NC}"
echo -e "${RED}║  TUTTI i dati esistenti in:                           ║${NC}"
echo -e "${RED}║  • n8n/data                                            ║${NC}"
echo -e "${RED}║  • anythingllm/storage                                 ║${NC}"
if [[ "$RESTORE_ENV" =~ ^[sS]$ ]]; then
echo -e "${RED}║  • .env                                                ║${NC}"
fi
echo -e "${RED}║                                                        ║${NC}"
echo -e "${RED}║  I dati attuali verranno CANCELLATI in modo PERMANENTE║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"

read -p "Scrivi YES (maiuscolo) per continuare: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo -e "${YELLOW}Restore annullato dall'utente${NC}"
    exit 0
fi

# Download dei backup da Google Drive
echo -e "\n${YELLOW}Download backup da ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}...${NC}"

cd "$SCRIPT_DIR"

# Download n8n
echo "→ Download n8n-${RESTORE_DATE}.tar.gz..."
if rclone copy "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}/n8n-${RESTORE_DATE}.tar.gz" . --progress; then
    echo -e "${GREEN}✓${NC} n8n backup scaricato"
else
    echo -e "${RED}✗ Errore durante il download del backup n8n${NC}"
    exit 1
fi

# Download AnythingLLM
echo "→ Download anythingllm-${RESTORE_DATE}.tar.gz..."
if rclone copy "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}/anythingllm-${RESTORE_DATE}.tar.gz" . --progress; then
    echo -e "${GREEN}✓${NC} AnythingLLM backup scaricato"
else
    echo -e "${RED}✗ Errore durante il download del backup AnythingLLM${NC}"
    exit 1
fi

# Download .env se richiesto
if [[ "$RESTORE_ENV" =~ ^[sS]$ ]]; then
    echo "→ Download env-${RESTORE_DATE}.tar.gz..."
    if rclone copy "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}/env-${RESTORE_DATE}.tar.gz" . --progress; then
        echo -e "${GREEN}✓${NC} .env backup scaricato"
    else
        echo -e "${YELLOW}⚠${NC} Impossibile scaricare il backup .env (continuo comunque)"
    fi
fi

# Pulizia directory esistenti
echo -e "\n${YELLOW}Pulizia dati esistenti...${NC}"

# Cancella n8n/data
if [ -d "$PROJECT_ROOT/n8n/data" ]; then
    echo "→ Rimozione $PROJECT_ROOT/n8n/data..."
    rm -rf "$PROJECT_ROOT/n8n/data"/*
    echo -e "${GREEN}✓${NC} n8n/data pulita"
fi

# Cancella anythingllm/storage
if [ -d "$PROJECT_ROOT/anythingllm/storage" ]; then
    echo "→ Rimozione $PROJECT_ROOT/anythingllm/storage..."
    rm -rf "$PROJECT_ROOT/anythingllm/storage"/*
    echo -e "${GREEN}✓${NC} anythingllm/storage pulita"
fi

# Estrazione backup
echo -e "\n${YELLOW}Estrazione backup...${NC}"

# Estrai n8n
echo "→ Estrazione n8n-${RESTORE_DATE}.tar.gz..."
tar -xzf "$SCRIPT_DIR/n8n-${RESTORE_DATE}.tar.gz" -C "$PROJECT_ROOT/n8n/"
echo -e "${GREEN}✓${NC} n8n ripristinato"

# Estrai AnythingLLM
echo "→ Estrazione anythingllm-${RESTORE_DATE}.tar.gz..."
tar -xzf "$SCRIPT_DIR/anythingllm-${RESTORE_DATE}.tar.gz" -C "$PROJECT_ROOT/anythingllm/"
echo -e "${GREEN}✓${NC} AnythingLLM ripristinato"

# Estrai .env se richiesto
if [[ "$RESTORE_ENV" =~ ^[sS]$ ]] && [ -f "$SCRIPT_DIR/env-${RESTORE_DATE}.tar.gz" ]; then
    echo "→ Estrazione env-${RESTORE_DATE}.tar.gz..."
    tar -xzf "$SCRIPT_DIR/env-${RESTORE_DATE}.tar.gz" -C "$PROJECT_ROOT/"
    echo -e "${GREEN}✓${NC} .env ripristinato"
fi

# Pulizia file temporanei
echo -e "\n${YELLOW}Pulizia file temporanei...${NC}"
rm -f "$SCRIPT_DIR/n8n-${RESTORE_DATE}.tar.gz"
rm -f "$SCRIPT_DIR/anythingllm-${RESTORE_DATE}.tar.gz"
rm -f "$SCRIPT_DIR/env-${RESTORE_DATE}.tar.gz"

echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Restore completato con successo!     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Prossimi passi:${NC}"
echo ""
echo "1. Verifica il file .env sia configurato correttamente:"
echo "   ${YELLOW}cat $PROJECT_ROOT/.env${NC}"
echo ""
echo "2. (Opzionale) Se vuoi usare le STESSE versioni delle immagini"
echo "   del momento del backup, NON eseguire 'docker compose pull'."
echo "   Altrimenti, per aggiornare alle ultime versioni:"
echo "   ${YELLOW}cd $PROJECT_ROOT && docker compose pull${NC}"
echo ""
echo "3. Avvia i container:"
echo "   ${YELLOW}cd $PROJECT_ROOT${NC}"
echo "   ${YELLOW}docker compose up -d${NC}"
echo ""
echo "4. Verifica lo stato dei container:"
echo "   ${YELLOW}docker compose ps${NC}"
echo "   ${YELLOW}docker compose logs -f${NC}"
echo ""
