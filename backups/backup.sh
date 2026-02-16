#!/usr/bin/env bash

#############################################
# Script di backup automatico per lo stack
# AI SaaS (n8n + AnythingLLM)
#
# Backup verso Google Drive tramite rclone
#############################################

set -euo pipefail

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory dello script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}=== Backup Stack AI SaaS ===${NC}"
echo "Inizio backup: $(date '+%Y-%m-%d %H:%M:%S')"

# Carica variabili d'ambiente
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
    echo -e "${GREEN}✓${NC} Variabili caricate da .env"
else
    echo -e "${RED}✗ File .env non trovato in $PROJECT_ROOT${NC}"
    exit 1
fi

# Verifica che rclone sia installato
if ! command -v rclone &> /dev/null; then
    echo -e "${RED}✗ rclone non è installato${NC}"
    echo "Installa rclone: https://rclone.org/install/"
    exit 1
fi

# Verifica configurazione rclone
if ! rclone listremotes | grep -q "^${RCLONE_REMOTE_NAME}:$"; then
    echo -e "${RED}✗ Remote rclone '${RCLONE_REMOTE_NAME}' non configurato${NC}"
    echo "Configura il remote con: rclone config"
    exit 1
fi

# Crea timestamp per i file di backup
DATE=$(date +%F-%H%M)
BACKUP_DIR="$SCRIPT_DIR"

echo -e "\n${YELLOW}Creazione archivi compressi...${NC}"

# Backup n8n
if [ -d "$PROJECT_ROOT/n8n/data" ]; then
    echo "→ Backup n8n/data..."
    tar -czf "$BACKUP_DIR/n8n-$DATE.tar.gz" -C "$PROJECT_ROOT/n8n" data
    echo -e "${GREEN}✓${NC} n8n-$DATE.tar.gz creato ($(du -h "$BACKUP_DIR/n8n-$DATE.tar.gz" | cut -f1))"
else
    echo -e "${YELLOW}⚠${NC} Directory n8n/data non trovata, salto backup n8n"
fi

# Backup AnythingLLM
if [ -d "$PROJECT_ROOT/anythingllm/storage" ]; then
    echo "→ Backup anythingllm/storage..."
    tar -czf "$BACKUP_DIR/anythingllm-$DATE.tar.gz" -C "$PROJECT_ROOT/anythingllm" storage
    echo -e "${GREEN}✓${NC} anythingllm-$DATE.tar.gz creato ($(du -h "$BACKUP_DIR/anythingllm-$DATE.tar.gz" | cut -f1))"
else
    echo -e "${YELLOW}⚠${NC} Directory anythingllm/storage non trovata, salto backup AnythingLLM"
fi

# Backup file .env (contiene configurazione e chiavi)
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "→ Backup .env..."
    tar -czf "$BACKUP_DIR/env-$DATE.tar.gz" -C "$PROJECT_ROOT" .env
    echo -e "${GREEN}✓${NC} env-$DATE.tar.gz creato"
    echo -e "${YELLOW}⚠ ATTENZIONE: env-$DATE.tar.gz contiene dati sensibili!${NC}"
else
    echo -e "${YELLOW}⚠${NC} File .env non trovato"
fi

# Upload su Google Drive con rclone
echo -e "\n${YELLOW}Upload backup su ${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}...${NC}"

for file in "$BACKUP_DIR"/*-"$DATE".tar.gz; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "→ Upload $filename..."
        if rclone copy "$file" "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_PATH}" --progress; then
            echo -e "${GREEN}✓${NC} $filename caricato con successo"
        else
            echo -e "${RED}✗${NC} Errore durante l'upload di $filename"
        fi
    fi
done

# Pulizia backup locali vecchi
echo -e "\n${YELLOW}Pulizia backup locali più vecchi di ${BACKUP_RETENTION_DAYS} giorni...${NC}"
DELETED=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete -print | wc -l)

if [ "$DELETED" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $DELETED file eliminati"
else
    echo "Nessun file da eliminare"
fi

echo -e "\n${GREEN}=== Backup completato con successo ===${NC}"
echo "Fine backup: $(date '+%Y-%m-%d %H:%M:%S')"
