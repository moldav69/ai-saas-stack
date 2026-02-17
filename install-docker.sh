#!/bin/bash

#############################################
# Script di installazione automatica Docker
# per Ubuntu 24.04 LTS e versioni recenti
#
# Installa:
# - Docker Engine (ultima versione)
# - Docker Compose plugin
# - Configurazione automatica
#############################################

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Installazione Docker Engine         ║${NC}"
echo -e "${BLUE}║   Ubuntu 24.04 LTS                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# Verifica se Docker è già installato
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠ Docker è già installato:${NC}"
    docker --version
    docker compose version 2>/dev/null || echo "Docker Compose plugin non trovato"
    echo ""
    read -p "Vuoi reinstallare? (s/N): " REINSTALL
    if [[ ! "$REINSTALL" =~ ^[sS]$ ]]; then
        echo -e "${GREEN}✓ Installazione annullata${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}1/8 Rimozione versioni vecchie di Docker...${NC}"
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}2/8 Aggiornamento repository...${NC}"
sudo apt-get update -qq
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}3/8 Installazione prerequisiti...${NC}"
sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}4/8 Aggiunta GPG key ufficiale Docker...${NC}"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}5/8 Aggiunta repository Docker...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}6/8 Aggiornamento indice pacchetti...${NC}"
sudo apt-get update -qq
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}7/8 Installazione Docker Engine + Docker Compose...${NC}"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${YELLOW}8/8 Configurazione avvio automatico...${NC}"
sudo systemctl enable docker
sudo systemctl start docker
echo -e "${GREEN}✓ Completato${NC}\n"

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Installazione completata!        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Versioni installate:${NC}"
docker --version
docker compose version

echo -e "\n${YELLOW}Test Docker...${NC}"
if docker run --rm hello-world > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker funziona correttamente!${NC}\n"
else
    echo -e "${RED}✗ Errore nel test di Docker${NC}\n"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Prossimi passi:                                      ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║  1. Vai nella directory del progetto:                 ║${NC}"
echo -e "${BLUE}║     ${YELLOW}cd /opt/ai-saas-stack${BLUE}                            ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║  2. Configura le variabili d'ambiente:                ║${NC}"
echo -e "${BLUE}║     ${YELLOW}cp .env.example .env${BLUE}                             ║${NC}"
echo -e "${BLUE}║     ${YELLOW}nano .env${BLUE}                                        ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}║  3. Avvia lo stack:                                   ║${NC}"
echo -e "${BLUE}║     ${YELLOW}docker compose up -d${BLUE}                             ║${NC}"
echo -e "${BLUE}║                                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}\n"
