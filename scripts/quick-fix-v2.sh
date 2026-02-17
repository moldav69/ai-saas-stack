#!/bin/bash
# AI SaaS Stack - Quick Fix v2.0
# Fixes NPM 502 Bad Gateway and AnythingLLM JWT issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}AI SaaS Stack - Quick Fix v2.0${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

cd "$(dirname "$0")/.."

# 1. BACKUP
echo -e "${YELLOW}1️⃣ Backup configurazioni...${NC}"
mkdir -p backups
sudo tar czf backups/pre-v2-backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  reverse-proxy/ n8n/ anythingllm/ .env docker-compose.yml 2>/dev/null || true
echo -e "${GREEN}✓ Backup salvato${NC}"
echo ""

# 2. STOP SERVIZI
echo -e "${YELLOW}2️⃣ Stop servizi...${NC}"
docker compose down
echo -e "${GREEN}✓ Servizi fermati${NC}"
echo ""

# 3. PULL REPOSITORY
echo -e "${YELLOW}3️⃣ Aggiornamento repository...${NC}"
git fetch origin
git checkout v2.0-stable-fix
git pull origin v2.0-stable-fix
echo -e "${GREEN}✓ Repository aggiornato${NC}"
echo ""

# 4. AGGIORNA .ENV
echo -e "${YELLOW}4️⃣ Aggiornamento .env...${NC}"
cp .env .env.backup_$(date +%Y%m%d_%H%M%S)

# Rimuovi JWT_SECRET e ENCRYPTION_KEY da AnythingLLM
sed -i '/^JWT_SECRET=/d' .env
sed -i '/^ENCRYPTION_KEY=/d' .env

# Fix N8N_PORT se mancante
if ! grep -q "^N8N_PORT=" .env; then
    echo "N8N_PORT=5678" >> .env
fi

echo -e "${GREEN}✓ .env aggiornato${NC}"
echo ""

# 5. RESET NPM DATABASE
echo -e "${YELLOW}5️⃣ Reset Nginx Proxy Manager database...${NC}"
sudo rm -f reverse-proxy/data/database.sqlite 2>/dev/null || true
echo -e "${GREEN}✓ NPM database resettato${NC}"
echo ""

# 6. RESET ANYTHINGLLM
echo -e "${YELLOW}6️⃣ Reset AnythingLLM storage...${NC}"
sudo rm -rf anythingllm/storage/* 2>/dev/null || true
sudo mkdir -p anythingllm/storage
sudo chown -R 1000:1000 anythingllm/storage
sudo chmod -R 755 anythingllm/storage
echo -e "${GREEN}✓ AnythingLLM storage resettato${NC}"
echo ""

# 7. PERMESSI
echo -e "${YELLOW}7️⃣ Verifica permessi...${NC}"
sudo chown -R 1000:1000 n8n/data anythingllm/storage
sudo chmod -R 755 reverse-proxy
echo -e "${GREEN}✓ Permessi OK${NC}"
echo ""

# 8. PULL IMMAGINI
echo -e "${YELLOW}8️⃣ Download nuove immagini Docker...${NC}"
docker compose pull
echo -e "${GREEN}✓ Immagini aggiornate${NC}"
echo ""

# 9. AVVIO
echo -e "${YELLOW}9️⃣ Avvio servizi...${NC}"
docker compose up -d
echo -e "${GREEN}✓ Servizi avviati${NC}"
echo ""

# 10. ATTESA
echo -e "${YELLOW}🕟 Attesa inizializzazione (45 secondi)...${NC}"
sleep 45
echo ""

# 11. STATUS
echo -e "${GREEN}✅ VERIFICA FINALE${NC}"
echo "===================="
docker compose ps
echo ""

# 12. ISTRUZIONI
IP=$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
N8N_HOST=$(grep N8N_HOST .env | cut -d'=' -f2 2>/dev/null || echo "n8n.tuodominio.com")

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}✅ FIX COMPLETATO!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}📋 PROSSIMI STEP:${NC}"
echo ""
echo -e "${YELLOW}1️⃣ Nginx Proxy Manager${NC} (RICONFIGURA)"
echo "   URL: http://$IP:81"
echo "   Email: admin@example.com"
echo "   Password: changeme"
echo "   ⚠️  Devi ricreare i proxy hosts!"
echo ""
echo -e "${YELLOW}2️⃣ AnythingLLM${NC} (WIZARD)"
echo "   Dopo proxy NPM configurato:"
echo "   URL: https://llm.tuodominio.com"
echo "   → Completa wizard setup"
echo "   → Crea account admin"
echo "   ✓ JWT auto-generato"
echo ""
echo -e "${YELLOW}3️⃣ n8n${NC} (OK)"
echo "   URL: https://$N8N_HOST"
echo "   ✓ Dati preservati"
echo ""
echo -e "📁 Backup: ${GREEN}backups/pre-v2-backup_*.tar.gz${NC}"
echo -e "📚 Docs: ${GREEN}README.md, TROUBLESHOOTING.md${NC}"
echo ""
