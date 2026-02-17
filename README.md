# 🚀 Stack AI SaaS - Deploy Automatizzato

Stack Docker completo per VPS Ubuntu con **n8n**, **AnythingLLM**, **Nginx Proxy Manager** (reverse proxy con HTTPS automatico) e **backup automatici su Google Drive**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-24%2B-blue)](https://www.docker.com/)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red)](https://github.com/moldav69/ai-saas-stack)

## 📚 Documentazione

- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - 🚀 Guida completa step-by-step per il primo deploy (INIZIA DA QUI!)
- **[SECURITY.md](SECURITY.md)** - 🔒 Guida sicurezza e privacy (telemetria, hardening)
- **[GDPR-ENCRYPTION.md](GDPR-ENCRYPTION.md)** - 🔒 Guida encryption backup per conformità GDPR
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - 🔧 Soluzioni a problemi comuni
- **README.md** (questo file) - Riferimento rapido e comandi utili

---

## ✨ Caratteristiche

- 🔄 **n8n**: Piattaforma di automazione workflow self-hosted
- 🤖 **AnythingLLM**: Sistema di gestione documenti e chat con AI self-hosted
- 🔒 **Nginx Proxy Manager**: Reverse proxy con certificati SSL/TLS automatici (Let's Encrypt)
- 💾 **Backup automatici**: Script pronti per backup giornalieri su Google Drive via rclone
- 🔒 **GDPR Compliant**: Encryption end-to-end per backup con AES-256
- 🔒 **Privacy-first**: Telemetria disabilitata di default
- 🔄 **Disaster Recovery**: Script di restore completo per ripristino rapido su nuovo server
- 📦 **One-command deploy**: Basta un `docker compose up -d` dopo la configurazione
- 🐳 **Script di installazione**: Installazione automatica di Docker e rclone per Ubuntu
- 📦 **Versioni auto-update**: n8n 2.7.5, AnythingLLM latest, Nginx PM 2.12.6

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
- **Backup GDPR**: Se elabori dati di utenti, configura [encryption backup](GDPR-ENCRYPTION.md)
- **Privacy**: Telemetria disabilitata di default per AnythingLLM

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

**⚠️ SICUREZZA CRITICA:**

Genera chiave per n8n:
```bash
openssl rand -hex 32  # N8N_ENCRYPTION_KEY
```

**Per AnythingLLM:**
```bash
# LASCIA JWT_SECRET e ENCRYPTION_KEY VUOTI nel .env!
# Se inserisci valori, salti il wizard e CHIUNQUE può accedere come admin!
# AnythingLLM ti chiederà di fare il setup via web UI al primo accesso.
```

**Nel .env:**
```env
# n8n - Genera e inserisci
N8N_ENCRYPTION_KEY=<tua_chiave_generata>

# AnythingLLM - LASCIA VUOTI! (sicurezza)
JWT_SECRET=
ENCRYPTION_KEY=

# Privacy - Telemetria disabilitata di default
DISABLE_TELEMETRY=true
```

### 3. Fix Permessi Directory (⚠️ IMPORTANTE!)

```bash
sudo chown -R 1000:1000 n8n/ anythingllm/
sudo chmod -R 755 n8n/ anythingllm/
```

### 4. Avvia lo Stack

```bash
docker compose up -d
```

### 5. Configura Nginx Proxy Manager

Apri `http://IP_VPS:81` e crea i Proxy Host per:
- `app.tuodominio.com` → `n8n:5678`
- `llm.tuodominio.com` → `anythingllm:3001`

### 6. Setup AnythingLLM (PRIMA VOLTA)

**Apri:** `https://llm.tuodominio.com`

Vedrai il **wizard di setup iniziale**:
1. Crea account admin (username e password)
2. Configura LLM provider (OpenAI, Ollama, ecc.)
3. Configura embedding provider
4. Crea primo workspace

🔒 **Questo è l'unico modo sicuro per configurare AnythingLLM!**

### 7. Setup Backup

```bash
# Installa rclone
chmod +x install-rclone.sh
./install-rclone.sh

# Configura Google Drive
rclone config

# (Opzionale) Configura encryption GDPR - vedi GDPR-ENCRYPTION.md

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

# Reset AnythingLLM (se password dimenticata)
./reset-anythingllm.sh
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
sudo chown -R 1000:1000 n8n/ anythingllm/
sudo chmod -R 755 n8n/ anythingllm/
docker compose restart
```

### Container in Restart Loop
```bash
# Ferma tutto
docker compose down

# Correggi permessi
sudo chown -R 1000:1000 n8n/ anythingllm/
sudo chmod -R 755 n8n/ anythingllm/

# Riavvia
docker compose up -d
```

### AnythingLLM: Password Dimenticata
```bash
# Usa lo script di reset
cd /opt/ai-saas-stack
./reset-anythingllm.sh

# Riapri browser e rifai il setup
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

### Encryption GDPR-Compliant

**Se elabori dati di clienti/utenti**, configura l'encryption end-to-end:

🔒 **[Guida completa: GDPR-ENCRYPTION.md](GDPR-ENCRYPTION.md)**

- Zero-knowledge encryption (AES-256)
- Google non può leggere i dati
- Filenames criptati
- GDPR compliant

### Restore

```bash
cd /opt/ai-saas-stack/backups
./restore.sh  # Ultimo backup
./restore.sh 2026-02-17-0300  # Backup specifico
```

**⚠️ IMPORTANTE dopo restore:**

Se ripristini un backup di AnythingLLM e non ricordi le credenziali:
```bash
cd /opt/ai-saas-stack
./reset-anythingllm.sh
```

---

## 🔒 Sicurezza e Privacy

### Best Practices Implementate

✅ Nessuna porta dei servizi esposta direttamente su Internet  
✅ HTTPS obbligatorio con certificati Let's Encrypt  
✅ Autenticazione Basic per n8n  
✅ Setup wizard obbligatorio per AnythingLLM (sicurezza)  
✅ **Telemetria disabilitata di default** (privacy)  
✅ Chiavi di encryption uniche per ogni installazione  
✅ Log rotation automatica (max 10MB × 3 file)  
✅ Backup criptati su Google Drive (opzionale)  
✅ Container eseguiti con utente non-root (UID 1000)  
✅ Versioni stabili con auto-update  

### 🔒 Privacy: Telemetria Disabilitata

**AnythingLLM telemetria è DISABILITATA di default** tramite:

```env
DISABLE_TELEMETRY=true
```

Questo previene l'invio di dati di utilizzo anonimi ai server di AnythingLLM.

Per maggiori dettagli: **[SECURITY.md](SECURITY.md)**

### 🚨 Avviso Sicurezza Critico

**AnythingLLM:**

❌ **MAI** inserire `JWT_SECRET` o `ENCRYPTION_KEY` nel `.env` prima del primo avvio!  
✅ **SEMPRE** lasciare questi campi vuoti per forzare il wizard di setup  
✅ Il wizard crea account admin con password sicura  
❌ Se skippi il wizard, CHIUNQUE può accedere come admin!  

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

## 📦 Versioni

Questo stack usa versioni stabili:

| Applicazione | Versione | Note |
|--------------|----------|------|
| **n8n** | 2.7.5 | Stable 2.7.x |
| **AnythingLLM** | latest | Auto-update agli ultimi fix |
| **Nginx Proxy Manager** | 2.12.6 | Stable |
| **Docker Engine** | 29.x | (installato con install-docker.sh) |

Per aggiornare:
```bash
cd /opt/ai-saas-stack
./backups/backup.sh  # Backup preventivo
docker compose pull
docker compose up -d
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
│                     │      │  + Telemetria OFF 🔒        │
│  Volume:            │      │                              │
│  ./n8n/data         │      │  Volume:                     │
│  Owner: 1000:1000   │      │  ./anythingllm/storage       │
│                     │      │  Owner: 1000:1000            │
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
- **[SECURITY.md](SECURITY.md)** - Sicurezza e privacy (telemetria, hardening)
- **[GDPR-ENCRYPTION.md](GDPR-ENCRYPTION.md)** - Encryption backup GDPR compliant
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

**Creato con ❤️ per deployment rapidi, sicuri e privacy-first**