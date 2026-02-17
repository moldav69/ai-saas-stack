# 🚀 Stack AI SaaS - Deploy Automatizzato

Stack Docker completo per VPS Ubuntu con **n8n**, **AnythingLLM**, **Nginx Proxy Manager** (reverse proxy con HTTPS automatico) e **backup automatici su Google Drive**.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-24%2B-blue)](https://www.docker.com/)
[![Made with ❤️](https://img.shields.io/badge/Made%20with-%E2%9D%A4%EF%B8%8F-red)](https://github.com/moldav69/ai-saas-stack)

## ✨ Caratteristiche

- 🔄 **n8n**: Piattaforma di automazione workflow self-hosted
- 🤖 **AnythingLLM**: Sistema di gestione documenti e chat con AI self-hosted
- 🔒 **Nginx Proxy Manager**: Reverse proxy con certificati SSL/TLS automatici (Let's Encrypt)
- 💾 **Backup automatici**: Script pronti per backup giornalieri su Google Drive via rclone
- 🔄 **Disaster Recovery**: Script di restore completo per ripristino rapido su nuovo server
- 📦 **One-command deploy**: Basta un `docker compose up -d` dopo la configurazione
- 🐳 **Script di installazione Docker**: Installazione automatica di Docker Engine per Ubuntu

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

### Configurazione rclone per Google Drive

Installa rclone:
```bash
curl https://rclone.org/install.sh | sudo bash
```

Configura il remote Google Drive:
```bash
rclone config
```

Segui questi passaggi:
1. Scegli `n` per nuovo remote
2. Nome: `gdrive` (o quello che preferisci, ma deve corrispondere a `RCLONE_REMOTE_NAME` nel .env)
3. Storage: Scegli `drive` per Google Drive
4. Segui il wizard per autenticare con il tuo account Google

Testa la configurazione:
```bash
# Crea la cartella di backup
rclone mkdir gdrive:vps-backups

# Verifica che funzioni
rclone ls gdrive:vps-backups
```

### Raccomandazioni Sicurezza
- **SSH**: Usa autenticazione con chiavi, disabilita login con password
- **Firewall**: Apri SOLO le porte 22, 80, 443
- **Aggiornamenti**: Mantieni il sistema aggiornato (`apt update && apt upgrade`)
- **Password**: Usa password complesse e uniche per ogni servizio

## 🚀 Installazione

### 0. Installazione Docker (se non presente)

Se Docker non è installato sul tuo VPS, usa lo script automatico incluso:

```bash
cd /opt
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack

# Rendi eseguibile lo script
chmod +x install-docker.sh

# Esegui l'installazione
./install-docker.sh
```

Lo script installerà automaticamente:
- Docker Engine (ultima versione)
- Docker Compose plugin
- Configurazione per avvio automatico

**Installazione manuale Docker:**

Se preferisci installare manualmente:

```bash
# Aggiungi repository Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installa Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Avvia Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verifica
docker --version
docker compose version
```

### 1. Clona la Repository

```bash
cd /opt  # o la directory che preferisci
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack
```

### 2. Configura le Variabili d'Ambiente

```bash
cp .env.example .env
nano .env
```

**Genera chiavi sicure per:**

```bash
# Per N8N_ENCRYPTION_KEY
openssl rand -hex 32

# Per JWT_SECRET (AnythingLLM)
openssl rand -hex 32

# Per ENCRYPTION_KEY (AnythingLLM)
openssl rand -hex 32
```

Esempio di `.env` configurato:

```env
COMPOSE_PROJECT_NAME=ai_saas

# n8n
N8N_HOST=app.tuodominio.com
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_ENCRYPTION_KEY=a1b2c3d4e5f67890abcdef1234567890abcdef1234567890abcdef12345678
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=TuaPasswordSicura123!

# AnythingLLM
JWT_SECRET=f9e8d7c6b5a4321098765432109876543210987654321098765432109876
ENCRYPTION_KEY=1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab
OPENAI_API_KEY=sk-proj-TuaChiaveOpenAI

# Backup
RCLONE_REMOTE_NAME=gdrive
RCLONE_REMOTE_PATH=vps-backups
BACKUP_RETENTION_DAYS=7
```

### 3. Configura i Permessi delle Directory

**⚠️ IMPORTANTE:** I container girano con l'utente UID 1000, quindi le directory di storage devono avere i permessi corretti:

```bash
# Imposta i permessi corretti per n8n
sudo chown -R 1000:1000 n8n/data
sudo chmod -R 755 n8n/data

# Imposta i permessi corretti per AnythingLLM
sudo chown -R 1000:1000 anythingllm/storage
sudo chmod -R 755 anythingllm/storage

# Verifica i permessi
ls -la n8n/data
ls -la anythingllm/storage
```

**Output atteso:**
```
drwxr-xr-x ... 1000 1000 ... n8n/data
drwxr-xr-x ... 1000 1000 ... anythingllm/storage
```

### 4. Avvia i Container

```bash
docker compose up -d
```

Verifica che tutti i container siano attivi:

```bash
docker compose ps
```

Output atteso:
```
NAME                   STATUS    PORTS
nginx-proxy-manager    Up        0.0.0.0:80->80, 0.0.0.0:443->443, 0.0.0.0:81->81
n8n                    Up
anythingllm            Up
```

Monitora i log (CTRL+C per uscire):

```bash
docker compose logs -f
```

**Se vedi container in stato "Restarting"**, consulta la [Guida al Troubleshooting](TROUBLESHOOTING.md).

## 🔐 Configurazione Nginx Proxy Manager

### 1. Accedi all'Interfaccia Admin

**⚠️ NOTA:** Se la porta 81 non è accessibile, aprila temporaneamente:

```bash
sudo ufw allow 81/tcp
```

Apri nel browser: `http://IP_DEL_TUO_VPS:81`

**Credenziali di default:**
- Email: `admin@example.com`
- Password: `changeme`

**⚠️ IMPORTANTE:** Cambia subito email e password dopo il primo accesso!

### 2. Crea Proxy Host per n8n

1. Vai su **Hosts** → **Proxy Hosts** → **Add Proxy Host**
2. Tab **Details**:
   - Domain Names: `app.tuodominio.com`
   - Scheme: `http`
   - Forward Hostname / IP: `n8n`
   - Forward Port: `5678`
   - Abilita: `Cache Assets`, `Block Common Exploits`, `Websockets Support`
3. Tab **SSL**:
   - SSL Certificate: **Request a new SSL Certificate**
   - Abilita: `Force SSL`, `HTTP/2 Support`
   - Email: il tuo indirizzo email
   - Accetta i Terms of Service
4. Clicca **Save**

### 3. Crea Proxy Host per AnythingLLM

Ripeti i passaggi sopra con queste differenze:
- Domain Names: `llm.tuodominio.com`
- Forward Hostname / IP: `anythingllm`
- Forward Port: `3001`

### 4. Verifica i Certificati

Dopo qualche secondo, i certificati Let's Encrypt verranno emessi automaticamente. Verifica:

- Vai su `https://app.tuodominio.com` → dovrebbe aprirsi n8n con HTTPS
- Vai su `https://llm.tuodominio.com` → dovrebbe aprirsi AnythingLLM con HTTPS

### 5. Chiudi la Porta 81 (Sicurezza)

Dopo aver configurato tutto:

```bash
sudo ufw delete allow 81/tcp
```

**Troubleshooting Let's Encrypt:**

Se vedi errori tipo "Some challenges have failed", consulta la [Guida al Troubleshooting](TROUBLESHOOTING.md#4-certificati-lets-encrypt-non-si-generano).

## 💾 Backup Automatico

### Setup Backup Manuale

Rendi eseguibile lo script:

```bash
chmod +x backups/backup.sh
```

Esegui un backup di test:

```bash
cd backups
./backup.sh
```

Lo script crea questi archivi:
- `n8n-YYYY-MM-DD-HHMM.tar.gz` → Tutti i workflow, credenziali, configurazioni n8n
- `anythingllm-YYYY-MM-DD-HHMM.tar.gz` → Workspace, knowledge base, documenti
- `env-YYYY-MM-DD-HHMM.tar.gz` → File .env con chiavi e configurazioni

Gli archivi vengono caricati su Google Drive e i file locali più vecchi di `BACKUP_RETENTION_DAYS` giorni vengono eliminati.

**⚠️ ATTENZIONE:** I backup contengono dati sensibili (chiavi API, password, dati utenti). Proteggi adeguatamente l'accesso al tuo Google Drive.

### Backup Automatico con Cron

Aggiungi alla crontab per backup giornaliero alle 3:00 AM:

```bash
crontab -e
```

Aggiungi questa riga (sostituisci il path):

```cron
0 3 * * * /opt/ai-saas-stack/backups/backup.sh >> /opt/ai-saas-stack/backups/backup.log 2>&1
```

Verifica i backup programmati:

```bash
crontab -l
```

Controlla il log:

```bash
tail -f /opt/ai-saas-stack/backups/backup.log
```

## 🔄 Restore / Disaster Recovery

### Scenario: Ripristino su Nuovo VPS

Se devi migrare o ripristinare lo stack su un nuovo server:

**1. Prepara il nuovo VPS:**

```bash
# Clona la repository
cd /opt
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack

# Installa Docker (se non presente)
chmod +x install-docker.sh
./install-docker.sh

# Installa rclone
curl https://rclone.org/install.sh | sudo bash

# Configura rclone con lo stesso remote
rclone config
```

**2. Esegui il restore:**

```bash
cd backups
chmod +x restore.sh

# Restore dell'ultimo backup disponibile
./restore.sh

# Oppure restore di un backup specifico
./restore.sh 2026-02-17-0300
```

Lo script:
- Scarica i backup da Google Drive
- Chiede se vuoi ripristinare anche il file .env
- Chiede conferma prima di sovrascrivere i dati
- Estrae i backup nelle directory corrette
- Pulisce i file temporanei

**3. Imposta i permessi corretti:**

```bash
cd /opt/ai-saas-stack
sudo chown -R 1000:1000 n8n/data
sudo chown -R 1000:1000 anythingllm/storage
sudo chmod -R 755 n8n/data
sudo chmod -R 755 anythingllm/storage
```

**4. Avvia i container:**

```bash
docker compose up -d
```

**5. Riconfigura Nginx Proxy Manager:**

Accedi a `http://IP_NUOVO_VPS:81` e ricrea i Proxy Host per i tuoi domini (i certificati Let's Encrypt vanno riemessi perché sono legati al server).

### ⚠️ Nota Importante sulle Immagini Docker

L'uso di tag `:latest` nelle immagini significa che le versioni possono cambiare nel tempo.

**Per un restore più fedele possibile:**
- **NON** eseguire `docker compose pull` prima di `docker compose up -d`
- Docker userà le immagini già presenti o scaricherà quelle disponibili al momento

**Per aggiornare alle ultime versioni:**
```bash
docker compose pull
docker compose up -d
```

**⚠️ Raccomandazione:** In produzione, dopo aver testato una versione stabile, fissa i tag specifici nel `docker-compose.yml`:

```yaml
# Invece di:
image: n8nio/n8n:latest

# Usa:
image: n8nio/n8n:1.23.0
```

## 🔄 Aggiornamenti

### Aggiornare i Servizi

Prima di aggiornare, **esegui sempre un backup**:

```bash
cd /opt/ai-saas-stack/backups
./backup.sh
```

Poi aggiorna le immagini:

```bash
cd /opt/ai-saas-stack
docker compose pull
docker compose up -d
```

Docker ricreerà solo i container con immagini aggiornate.

### Monitorare gli Aggiornamenti

Verifica le nuove versioni:
- n8n: https://github.com/n8n-io/n8n/releases
- AnythingLLM: https://github.com/Mintplex-Labs/anything-llm/releases
- Nginx Proxy Manager: https://github.com/NginxProxyManager/nginx-proxy-manager/releases

## 🔍 Diagnostica e Troubleshooting

### Quick Debug

```bash
# Verifica stato container
docker compose ps

# Vedi i log in tempo reale
docker compose logs -f

# Riavvia un servizio problematico
docker compose restart n8n
```

### Problemi Comuni

**Errore 502 Bad Gateway:**
- Verifica che i container siano UP: `docker compose ps`
- Controlla i log: `docker compose logs n8n` o `docker compose logs anythingllm`
- Probabilmente è un problema di permessi (vedi sotto)

**Container in restart loop (n8n o AnythingLLM):**

```bash
# Ferma i container
docker compose down

# Correggi i permessi
sudo chown -R 1000:1000 n8n/data
sudo chown -R 1000:1000 anythingllm/storage
sudo chmod -R 755 n8n/data
sudo chmod -R 755 anythingllm/storage

# Riavvia
docker compose up -d
```

**Certificati SSL non si generano:**
- Verifica DNS: `dig app.tuodominio.com`
- Verifica porta 80 aperta: `sudo ufw status`
- Disattiva proxy Cloudflare (temporaneamente)
- Controlla log: `docker compose logs reverse-proxy`

### 📚 Guida Completa al Troubleshooting

Per una guida dettagliata con soluzioni a tutti i problemi comuni, consulta:

➡️ **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

La guida copre:
- Errori di permessi (n8n e AnythingLLM)
- Problemi con certificati SSL
- Configurazione DNS
- Problemi di rete Docker
- Script di backup
- Comandi di debug avanzati

## 🔒 Sicurezza

### Best Practices Implementate

✅ Nessuna porta dei servizi esposta direttamente su Internet (solo tramite reverse proxy)  
✅ HTTPS obbligatorio con certificati Let's Encrypt  
✅ Autenticazione Basic per n8n  
✅ Chiavi di encryption uniche per ogni installazione  
✅ Log rotation automatica (max 10MB × 3 file)  
✅ Backup criptati su Google Drive  
✅ Container eseguiti con utente non-root (UID 1000)  

### Raccomandazioni Aggiuntive

- **SSH**: Disabilita login con password, usa solo chiavi
  ```bash
  sudo nano /etc/ssh/sshd_config
  # Imposta: PasswordAuthentication no
  sudo systemctl restart sshd
  ```

- **Fail2Ban**: Proteggi SSH da attacchi brute-force
  ```bash
  sudo apt install fail2ban
  sudo systemctl enable fail2ban
  ```

- **Aggiornamenti automatici**: Configura unattended-upgrades
  ```bash
  sudo apt install unattended-upgrades
  sudo dpkg-reconfigure unattended-upgrades
  ```

- **Monitoraggio**: Considera l'installazione di strumenti come Netdata o Prometheus

## 📁 Cosa Contiene Ogni Backup

| File | Contenuto |
|------|-----------|
| `n8n-*.tar.gz` | Workflow, credenziali, configurazioni, esecuzioni storiche |
| `anythingllm-*.tar.gz` | Workspace, documenti caricati, vector database, chat history |
| `env-*.tar.gz` | Tutte le variabili d'ambiente incluse chiavi API e password |

**⚠️ I backup contengono dati sensibili:** Proteggi l'accesso al tuo Google Drive e considera l'uso di encryption aggiuntiva per dati critici.

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

## 📞 Supporto

Per problemi specifici ai servizi:
- n8n: https://community.n8n.io/
- AnythingLLM: https://github.com/Mintplex-Labs/anything-llm/issues
- Nginx Proxy Manager: https://github.com/NginxProxyManager/nginx-proxy-manager/issues

Per problemi con questo stack:
- [Guida Troubleshooting](TROUBLESHOOTING.md)
- [GitHub Issues](https://github.com/moldav69/ai-saas-stack/issues)

## 🤝 Contribuire

Contributi, segnalazioni di bug e richieste di funzionalità sono benvenuti! Sentiti libero di aprire una issue o una pull request.

## 📝 Licenza

Questo stack utilizza software open source. Verifica le licenze individuali:
- n8n: Apache 2.0 (Self-hosted) / Proprietaria (Cloud)
- AnythingLLM: MIT License
- Nginx Proxy Manager: MIT License

---

**Creato con ❤️ per deployment rapidi e affidabili**

Se questo progetto ti è stato utile, lascia una ⭐ su GitHub!