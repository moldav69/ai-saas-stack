# 🚀 Stack AI SaaS - Deploy Automatizzato

Stack Docker completo per VPS Ubuntu con **n8n**, **AnythingLLM**, **Nginx Proxy Manager** (reverse proxy con HTTPS automatico) e **backup automatici su Google Drive**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-24%2B-blue)](https://www.docker.com/)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red)](https://github.com/moldav69/ai-saas-stack)

## 📚 Documentazione

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - 🚀 Guida completa step-by-step per il primo deploy (INIZIA DA QUI!)
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 🔧 Soluzioni a problemi comuni
- **README.md** (questo file) - Riferimento rapido e comandi utili

---

## ✨ Caratteristiche

- 🔄 **n8n**: Piattaforma di automazione workflow self-hosted
- 🤖 **AnythingLLM**: Sistema di gestione documenti e chat con AI self-hosted
- 🔒 **Nginx Proxy Manager**: Reverse proxy con certificati SSL/TLS automatici (Let's Encrypt)
- 💾 **Backup automatici**: Script pronti per backup giornalieri su Google Drive via rclone
- 🔄 **Disaster Recovery**: Script di restore completo per ripristino rapido su nuovo server
- 📦 **One-command deploy**: Basta un `docker compose up -d` dopo la configurazione
- 🐳 **Script di installazione**: Installazione automatica di Docker e rclone per Ubuntu

## 📋 Prerequisiti

### Hardware VPS Consigliato
- **CPU**: Minimo 2 vCPU
- **RAM**: Minimo 4 GB
- **Storage**: Minimo 40 GB SSD
- **Sistema Operativo**: Ubuntu 22.04 LTS o superiore

### Software Richiesto
- **Docker Engine** ≥ 24.x
- **Docker Compose** plugin (comando `docker compose`, non `docker-compose`)
- **rclone** per i backup su Google Drive

### Dominio e DNS
Devi avere un dominio con questi record DNS configurati:

| Tipo | Nome | Valore |
|------|------|--------|
| A | app.miodominio.com | IP_DEL_TUO_VPS |
| A | llm.miodominio.com | IP_DEL_TUO_VPS |

**⚠️ IMPORTANTE per Let's Encrypt:**
- Le porte 80 e 443 devono essere aperte sul firewall del VPS
- Durante l'emissione del certificato, NON usare il proxy Cloudflare (nuvola arancione) sui record DNS
- Dopo aver ottenuto i certificati, puoi eventualmente riattivare il proxy Cloudflare

### Configurazione Firewall (UFW)
```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP (Let's Encrypt)
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

### Raccomandazioni Sicurezza
- **SSH**: Usa autenticazione con chiavi, disabilita login con password
- **Firewall**: Apri SOLO le porte 22, 80, 443
- **Aggiornamenti**: Mantieni il sistema aggiornato (`apt update && apt upgrade`)
- **Password**: Usa password complesse e uniche per ogni servizio

---

## 🚀 Quick Start

Per una guida completa passo-passo, consulta **[SETUP-GUIDE.md](SETUP-GUIDE.md)**.

### 1. Installa Docker

```bash
cd /opt
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack
chmod +x install-docker.sh
./install-docker.sh
```

### 2. Configura Variabili d'Ambiente

```bash
cp .env.example .env
nano .env
```

Genera chiavi sicure:
```bash
openssl rand -hex 32  # N8N_ENCRYPTION_KEY
openssl rand -hex 32  # JWT_SECRET
openssl rand -hex 32  # ENCRYPTION_KEY
```

### 3. Fix Permessi Directory (⚠️ IMPORTANTE!)

```bash
sudo chown -R 1000:1000 n8n/data anythingllm/storage
sudo chmod -R 755 n8n/data anythingllm/storage
```

### 4. Avvia lo Stack

```bash
docker compose up -d
```

### 5. Configura Nginx Proxy Manager

Apri `http://IP_VPS:81` e crea i Proxy Host per:
- `app.tuodominio.com` → `n8n:5678`
- `llm.tuodominio.com` → `anythingllm:3001`

### 6. Setup Backup

```bash
# Installa rclone
chmod +x install-rclone.sh
./install-rclone.sh

# Configura Google Drive
rclone config

# Test backup
cd backups
chmod +x backup.sh restore.sh
./backup.sh

# Backup automatici
crontab -e
# Aggiungi: 0 3 * * * /opt/ai-saas-stack/backups/backup.sh >> /opt/ai-saas-stack/backups/backup.log 2>&1
```

---

## 🔧 Comandi Utili

### Monitoraggio

```bash
# Stato container
docker compose ps

# Log in tempo reale
docker compose logs -f

# Log di un servizio specifico
docker compose logs -f n8n
```

### Manutenzione

```bash
# Riavvia un servizio
docker compose restart n8n

# Backup manuale
cd /opt/ai-saas-stack/backups && ./backup.sh

# Verifica backup su Google Drive
rclone ls gdrive:vps-backups
```

### Aggiornamenti

```bash
# Backup prima di aggiornare
cd /opt/ai-saas-stack/backups && ./backup.sh

# Aggiorna le immagini
cd /opt/ai-saas-stack
docker compose pull
docker compose up -d
```

---

## 🔍 Troubleshooting Rapido

### Errore 502 Bad Gateway
```bash
# Verifica container
docker compose ps

# Controlla log
docker compose logs n8n
docker compose logs anythingllm

# Probabilmente permessi errati, riapplica:
sudo chown -R 1000:1000 n8n/data anythingllm/storage
sudo chmod -R 755 n8n/data anythingllm/storage
docker compose restart
```

### Container in Restart Loop
```bash
# Ferma tutto
docker compose down

# Correggi permessi
sudo chown -R 1000:1000 n8n/data anythingllm/storage
sudo chmod -R 755 n8n/data anythingllm/storage

# Riavvia
docker compose up -d
```

### Certificati SSL Non si Generano
```bash
# Verifica DNS
dig app.tuodominio.com

# Verifica porta 80
sudo ufw status | grep 80

# Controlla log Nginx
docker compose logs reverse-proxy | grep -i error
```

**Per una guida completa:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 💾 Backup e Restore

### Backup Manuale

```bash
cd /opt/ai-saas-stack/backups
./backup.sh
```

Vengono creati e caricati su Google Drive:
- `n8n-*.tar.gz` - Workflow, credenziali, configurazioni
- `anythingllm-*.tar.gz` - Workspace, documenti, vector DB
- `env-*.tar.gz` - Variabili d'ambiente

### Backup Automatici

```bash
crontab -e
```

Aggiungi:
```cron
0 3 * * * /opt/ai-saas-stack/backups/backup.sh >> /opt/ai-saas-stack/backups/backup.log 2>&1
```

### Restore

```bash
cd /opt/ai-saas-stack/backups
./restore.sh  # Ultimo backup
./restore.sh 2026-02-17-0300  # Backup specifico
```

---

## 🔒 Sicurezza

### Best Practices Implementate

✅ Nessuna porta dei servizi esposta direttamente su Internet  
✅ HTTPS obbligatorio con certificati Let's Encrypt  
✅ Autenticazione Basic per n8n  
✅ Chiavi di encryption uniche per ogni installazione  
✅ Log rotation automatica (max 10MB × 3 file)  
✅ Backup criptati su Google Drive  
✅ Container eseguiti con utente non-root (UID 1000)  

### Raccomandazioni Aggiuntive

```bash
# Disabilita login SSH con password
sudo nano /etc/ssh/sshd_config
# Imposta: PasswordAuthentication no
sudo systemctl restart sshd

# Installa Fail2Ban
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Aggiornamenti automatici
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

---

## 🏗️ Architettura

```
┌─────────────────────────────────────────────────────────────┐
│                      Internet                               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Port 80/443
                 ▼
┌─────────────────────────────────────────────────────────────┐
│            Nginx Proxy Manager                              │
│         (Reverse Proxy + Let's Encrypt)                     │
│                Port 81 (Admin UI)                           │
└────────────┬───────────────────────────┬────────────────────┘
             │                           │
             │ app.domain.com            │ llm.domain.com
             │ → n8n:5678               │ → anythingllm:3001
             ▼                           ▼
┌─────────────────────┐      ┌──────────────────────────────┐
│       n8n           │      │      AnythingLLM             │
│  (Workflow Engine)  │      │  (Document AI Chat)          │
│                     │      │                              │
│  Volume:            │      │  Volume:                     │
│  ./n8n/data         │      │  ./anythingllm/storage       │
│  Owner: 1000:1000   │      │  Owner: 1000:1000            │
└─────────────────────┘      └──────────────────────────────┘
             │                           │
             └───────────┬───────────────┘
                         │
                         ▼
                ┌────────────────┐
                │  Docker Network│
                │  ai_saas_net   │
                └────────────────┘
```

---

## 📞 Supporto

### Documentazione
- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Guida completa step-by-step
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Soluzioni a problemi comuni

### Community
- n8n: https://community.n8n.io/
- AnythingLLM: https://github.com/Mintplex-Labs/anything-llm/issues
- Nginx Proxy Manager: https://github.com/NginxProxyManager/nginx-proxy-manager/issues

### Questo Stack
- [GitHub Issues](https://github.com/moldav69/ai-saas-stack/issues)
- [GitHub Discussions](https://github.com/moldav69/ai-saas-stack/discussions)

---

## 🤝 Contribuire

Contributi, segnalazioni di bug e richieste di funzionalità sono benvenuti!

1. Fork il progetto
2. Crea un branch per la tua feature (`git checkout -b feature/AmazingFeature`)
3. Commit le modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

---

## 📝 Licenza

Questo stack utilizza software open source. Verifica le licenze individuali:
- n8n: Apache 2.0 (Self-hosted) / Proprietaria (Cloud)
- AnythingLLM: MIT License
- Nginx Proxy Manager: MIT License

---

## ⭐ Se questo progetto ti è utile...

Lascia una ⭐ su GitHub! Aiuta altri a scoprire questo stack.

**Creato con ❤️ per deployment rapidi e affidabili**