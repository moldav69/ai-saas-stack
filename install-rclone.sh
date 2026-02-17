#!/bin/bash
# Script di installazione rclone per Ubuntu/Debian

set -e

echo "📦 Installazione rclone..."
echo ""

# Verifica se rclone è già installato
if command -v rclone &> /dev/null; then
    CURRENT_VERSION=$(rclone version | head -n 1)
    echo "ℹ️  rclone è già installato: $CURRENT_VERSION"
    echo ""
    read -p "Vuoi aggiornare all'ultima versione? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Installazione annullata."
        exit 0
    fi
fi

# Installa rclone con lo script ufficiale
echo "🚀 Scaricamento e installazione dell'ultima versione..."
curl https://rclone.org/install.sh | sudo bash

echo ""
echo "✅ rclone installato con successo!"
echo ""

# Mostra la versione installata
rclone version | head -n 1

echo ""
echo "📖 Prossimi passi:"
echo "1. Configura rclone: rclone config"
echo "2. Crea il remote per Google Drive"
echo "3. Testa la connessione: rclone lsd gdrive:"
echo ""
echo "📚 Documentazione completa: https://rclone.org/docs/"
echo ""