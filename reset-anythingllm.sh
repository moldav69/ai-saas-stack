#!/bin/bash

# Script Reset AnythingLLM - Ripristino Setup Iniziale
# Autore: moldav69
# Licenza: MIT

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╭────────────────────────────────────────────╮"
echo "│  🔄 Reset AnythingLLM - Setup Iniziale  │"
echo "╰────────────────────────────────────────────╯"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  ATTENZIONE: Questa operazione eliminerà:${NC}"
echo "  - Account utenti"
echo "  - Workspace"
echo "  - Documenti caricati"
echo "  - Chat history"
echo "  - Configurazioni"
echo ""

read -p "Vuoi continuare? (scrivi 'SI' per confermare): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    echo -e "${RED}❌ Operazione annullata${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}📦 Step 1: Backup preventivo...${NC}"
BACKUP_DIR="anythingllm/storage.backup-$(date +%Y%m%d-%H%M%S)"
cp -r anythingllm/storage "$BACKUP_DIR"
echo -e "${GREEN}✅ Backup salvato in: $BACKUP_DIR${NC}"

echo ""
echo -e "${BLUE}🛑 Step 2: Ferma AnythingLLM...${NC}"
docker compose stop anythingllm
echo -e "${GREEN}✅ Container fermato${NC}"

echo ""
echo -e "${BLUE}🗑️  Step 3: Rimuovi database...${NC}"
sudo rm -f anythingllm/storage/anythingllm.db
sudo rm -f anythingllm/storage/anythingllm.db-shm
sudo rm -f anythingllm/storage/anythingllm.db-wal
echo -e "${GREEN}✅ Database rimosso${NC}"

echo ""
echo -e "${BLUE}🔧 Step 4: Fix permessi...${NC}"
sudo chown -R 1000:1000 anythingllm/
sudo chmod -R 755 anythingllm/
echo -e "${GREEN}✅ Permessi corretti${NC}"

echo ""
echo -e "${BLUE}🚀 Step 5: Riavvia AnythingLLM...${NC}"
docker compose start anythingllm
echo -e "${GREEN}✅ Container avviato${NC}"

echo ""
echo -e "${YELLOW}⏳ Attendi 10 secondi per l'avvio...${NC}"
sleep 10

echo ""
echo -e "${BLUE}🔍 Step 6: Verifica stato...${NC}"
if docker compose ps | grep -q "anythingllm.*Up"; then
    echo -e "${GREEN}✅ AnythingLLM è attivo!${NC}"
else
    echo -e "${RED}❌ Errore: AnythingLLM non si è avviato${NC}"
    echo -e "${YELLOW}Controlla i log con: docker compose logs anythingllm${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}"
echo "╭──────────────────────────────────────────╮"
echo "│  ✅ Reset completato con successo!  │"
echo "╰──────────────────────────────────────────╯"
echo -e "${NC}"

echo -e "${BLUE}📝 Prossimi step:${NC}"
echo ""
echo -e "${YELLOW}1. Apri nel browser:${NC}"
echo -e "   https://llm.tuodominio.com"
echo ""
echo -e "${YELLOW}2. Vedrai la pagina di setup iniziale${NC}"
echo ""
echo -e "${YELLOW}3. Crea un nuovo account admin:${NC}"
echo "   - Username: scegli tu (es: admin)"
echo "   - Password: usa una password sicura!"
echo ""
echo -e "${YELLOW}4. Configura il provider LLM:${NC}"
echo "   - OpenAI (se hai API key)"
echo "   - Ollama (se hai server locale)"
echo "   - Altri provider supportati"
echo ""
echo -e "${BLUE}💾 Backup disponibile in:${NC} $BACKUP_DIR"
echo -e "${YELLOW}   (Puoi eliminarlo se non ti serve)${NC}"
echo ""

echo -e "${BLUE}🔍 Comandi utili:${NC}"
echo -e "   ${YELLOW}Verifica log:${NC}     docker compose logs -f anythingllm"
echo -e "   ${YELLOW}Stato container:${NC}  docker compose ps"
echo -e "   ${YELLOW}Riavvia:${NC}          docker compose restart anythingllm"
echo ""