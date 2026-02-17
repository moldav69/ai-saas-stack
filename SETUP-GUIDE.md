# 🚀 Guida Completa Step-by-Step al Deploy

Questa guida ti accompagna passo-passo nel deploy completo dello stack AI SaaS, dalla configurazione del VPS fino ai backup automatici.

## 📚 Indice

1. [Preparazione VPS](#1-preparazione-vps)
2. [Installazione Docker](#2-installazione-docker)
3. [Clone Repository](#3-clone-repository)
4. [Configurazione Variabili d'Ambiente](#4-configurazione-variabili-dambiente)
5. [Fix Permessi Directory](#5-fix-permessi-directory)
6. [Avvio Container](#6-avvio-container)
7. [Configurazione Nginx Proxy Manager](#7-configurazione-nginx-proxy-manager)
8. [Setup Backup con rclone](#8-setup-backup-con-rclone)
9. [Verifica Finale](#9-verifica-finale)

---

## 1. Preparazione VPS

### Requisiti Minimi
- **OS:** Ubuntu 22.04 LTS o superiore
- **CPU:** 2 vCPU
- **RAM:** 4 GB
- **Storage:** 40 GB SSD
- **IP Pubblico:** Accessibile

### Configurazione Iniziale

```bash
# Aggiorna il sistema
sudo apt update && sudo apt upgrade -y

# Installa utility di base
sudo apt install -y curl wget git nano ufw

# Configura firewall
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 81/tcp   # Nginx Proxy Manager Admin (temporaneo)
sudo ufw enable

# Verifica firewall
sudo ufw status
```

### Configurazione DNS

Prima di procedere, configura questi record DNS sul tuo provider:

| Tipo | Nome | Valore | TTL |
|------|------|--------|-----|
| A | app.tuodominio.com | IP_VPS | 300 |
| A | llm.tuodominio.com | IP_VPS | 300 |

**⚠️ IMPORTANTE:**
- Se usi Cloudflare, **disattiva il proxy** (nuvola grigia, non arancione) durante l'emissione dei certificati SSL
- Aspetta 5-10 minuti per la propagazione DNS

**Verifica DNS:**
```bash
# Dal tuo computer o dal VPS
dig app.tuodominio.com
nslookup app.tuodominio.com

# Deve rispondere con l'IP del VPS
```

---

## 2. Installazione Docker

### Metodo Automatico (Consigliato)

```bash
# Vai nella directory /opt
cd /opt

# Clona temporaneamente la repo per lo script
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack

# Rendi eseguibile lo script
chmod +x install-docker.sh

# Esegui l'installazione
./install-docker.sh
```

Lo script installerà:
- Docker Engine (ultima versione)
- Docker Compose plugin
- Configurazione per avvio automatico al boot

### Verifica Installazione

```bash
# Verifica Docker
docker --version
# Output atteso: Docker version 24.x.x

# Verifica Docker Compose
docker compose version
# Output atteso: Docker Compose version v2.x.x

# Test Docker
docker run --rm hello-world
# Deve scaricare ed eseguire il container di test
```

---

## 3. Clone Repository

Se hai già clonato per installare Docker, salta al prossimo step. Altrimenti:

```bash
cd /opt
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack
```

---

## 4. Configurazione Variabili d'Ambiente

### Crea il File .env

```bash
cp .env.example .env
```

### Genera Chiavi di Encryption Sicure

```bash
# Genera N8N_ENCRYPTION_KEY
openssl rand -hex 32

# Genera JWT_SECRET
openssl rand -hex 32

# Genera ENCRYPTION_KEY
openssl rand -hex 32
```

**⚠️ Salva questi valori!** Serviranno per configurare il `.env`.

### Modifica il File .env

```bash
nano .env
```

**Configurazione minima richiesta:**

```env
COMPOSE_PROJECT_NAME=ai_saas

# n8n - MODIFICA QUESTI VALORI
N8N_HOST=app.tuodominio.com              # <-- Il tuo dominio
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_ENCRYPTION_KEY=<CHIAVE_GENERATA_1>   # <-- Incolla la prima chiave
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin                # <-- Cambia username
N8N_BASIC_AUTH_PASSWORD=TuaPassword123!  # <-- Cambia password

# AnythingLLM - MODIFICA QUESTI VALORI
JWT_SECRET=<CHIAVE_GENERATA_2>           # <-- Incolla la seconda chiave
ENCRYPTION_KEY=<CHIAVE_GENERATA_3>       # <-- Incolla la terza chiave
OPENAI_API_KEY=                          # <-- Opzionale: chiave OpenAI

# Backup - LASCIA COME SONO PER ORA
RCLONE_REMOTE_NAME=gdrive
RCLONE_REMOTE_PATH=vps-backups
BACKUP_RETENTION_DAYS=7
```

**Salva e chiudi:** `CTRL+O`, poi `CTRL+X`

---

## 5. Fix Permessi Directory

**⚠️ PASSO CRITICO:** I container Docker girano con l'utente UID 1000. Le directory di storage devono avere i permessi corretti **prima** di avviare i container.

```bash
# Imposta owner e permessi per n8n
sudo chown -R 1000:1000 n8n/data
sudo chmod -R 755 n8n/data

# Imposta owner e permessi per AnythingLLM
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

**✅ Se vedi `1000 1000` come owner, i permessi sono corretti!**

---

## 6. Avvio Container

### Avvia lo Stack

```bash
cd /opt/ai-saas-stack
docker compose up -d
```

### Verifica lo Stato

```bash
docker compose ps
```

**Output atteso:**
```
NAME                   STATUS    PORTS
nginx-proxy-manager    Up        0.0.0.0:80->80, 0.0.0.0:443->443, 0.0.0.0:81->81
n8n                    Up
anythingllm            Up
```

**⚠️ Se vedi "Restarting" o "Exited":**

```bash
# Controlla i log
docker compose logs n8n
docker compose logs anythingllm

# Se vedi errori di permessi, torna allo Step 5
# Altrimenti consulta TROUBLESHOOTING.md
```

### Monitora i Log (Opzionale)

```bash
# Log in tempo reale di tutti i servizi
docker compose logs -f

# Premi CTRL+C per uscire
```

---

## 7. Configurazione Nginx Proxy Manager

### Accedi all'Interfaccia Admin

Apri nel browser: **`http://IP_DEL_TUO_VPS:81`**

**Credenziali di default:**
- Email: `admin@example.com`
- Password: `changeme`

**⚠️ Al primo login:**
1. Ti chiederà di cambiare email e password
2. Scegli una password sicura
3. Salva le nuove credenziali

---

### Crea Proxy Host per n8n

1. Vai su **Hosts** → **Proxy Hosts** → **Add Proxy Host**

2. **Tab "Details":**
   - **Domain Names:** `app.tuodominio.com`
   - **Scheme:** `http`
   - **Forward Hostname / IP:** `n8n` (⚠️ NON localhost!)
   - **Forward Port:** `5678`
   - **Cache Assets:** ☑️ Abilita
   - **Block Common Exploits:** ☑️ Abilita
   - **Websockets Support:** ☑️ Abilita (⚠️ Importante per n8n!)

3. **Tab "SSL":**
   - **SSL Certificate:** Seleziona **"Request a new SSL Certificate"**
   - **Force SSL:** ☑️ Abilita
   - **HTTP/2 Support:** ☑️ Abilita
   - **Email Address for Let's Encrypt:** Il tuo indirizzo email
   - **I Agree to the Let's Encrypt Terms of Service:** ☑️

4. Clicca **Save**

**Dopo 10-30 secondi**, il certificato Let's Encrypt verrà emesso automaticamente.

---

### Crea Proxy Host per AnythingLLM

Ripeti gli stessi passaggi con queste differenze:

- **Domain Names:** `llm.tuodominio.com`
- **Forward Hostname / IP:** `anythingllm` (⚠️ NON localhost!)
- **Forward Port:** `3001`
- Tutto il resto uguale a n8n

---

### Verifica i Certificati SSL

Dopo qualche secondo:

1. Apri **`https://app.tuodominio.com`**
   - Deve aprirsi n8n con lucchetto verde 🔒

2. Apri **`https://llm.tuodominio.com`**
   - Deve aprirsi AnythingLLM con lucchetto verde 🔒

**✅ Se vedi entrambi i siti con HTTPS, tutto è configurato correttamente!**

---

### Troubleshooting Certificati

**Se vedi errori tipo "Some challenges have failed":**

1. **Verifica DNS:**
   ```bash
   dig app.tuodominio.com
   # Deve rispondere con l'IP del VPS
   ```

2. **Verifica porta 80:**
   ```bash
   sudo ufw status | grep 80
   # Deve mostrare: 80/tcp ALLOW
   ```

3. **Disattiva proxy Cloudflare** (se applicabile):
   - Vai su Cloudflare Dashboard
   - Clicca sulla nuvola arancione per renderla grigia
   - Aspetta 5 minuti
   - Riprova a richiedere il certificato

4. **Controlla i log:**
   ```bash
   docker compose logs reverse-proxy | grep -i error
   ```

Per problemi più complessi, consulta [TROUBLESHOOTING.md](TROUBLESHOOTING.md#4-certificati-lets-encrypt-non-si-generano).

---

### Chiudi la Porta 81 (Sicurezza)

Dopo aver configurato tutto:

```bash
sudo ufw delete allow 81/tcp
sudo ufw status
```

Per accedere nuovamente in futuro:
```bash
sudo ufw allow 81/tcp  # Riapri temporaneamente
# ... fai le modifiche ...
sudo ufw delete allow 81/tcp  # Richiudi
```

---

## 8. Setup Backup con rclone

### Installa rclone

```bash
cd /opt/ai-saas-stack
chmod +x install-rclone.sh
./install-rclone.sh
```

### Configura rclone per Google Drive

```bash
rclone config
```

**Segui questi passaggi:**

1. **Nuovo remote:** Digita `n` + INVIO
2. **Nome:** Digita `gdrive` + INVIO
3. **Storage type:** Digita `drive` + INVIO (o il numero di Google Drive)
4. **Client ID:** Premi solo INVIO (lascia vuoto)
5. **Client Secret:** Premi solo INVIO (lascia vuoto)
6. **Scope:** Digita `1` + INVIO (Full access)
7. **Root folder ID:** Premi solo INVIO (lascia vuoto)
8. **Service account:** Premi solo INVIO (lascia vuoto)
9. **Advanced config:** Digita `n` + INVIO
10. **Use auto config:** Digita `n` + INVIO (⚠️ Sei su un server remoto)

**Autenticazione:**

Ora vedrai un comando tipo:
```
rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
```

**Sul tuo computer locale** (Windows/Mac/Linux):

1. Installa rclone:
   - **Windows:** Scarica da https://rclone.org/downloads/
   - **Mac:** `brew install rclone`
   - **Linux:** `curl https://rclone.org/install.sh | sudo bash`

2. Esegui il comando mostrato:
   ```bash
   rclone authorize "drive" "eyJzY29wZSI6ImRyaXZlIn0"
   ```

3. Si apre il browser → Accedi con Google → Autorizza rclone

4. Nel terminale locale vedrai un **token JSON** tipo:
   ```json
   {"access_token":"ya29.a0...","token_type":"Bearer","refresh_token":"1//0g...",...}
   ```

5. **Copia TUTTO il JSON** (dalla `{` alla `}` finale)

6. **Incolla nel terminale del VPS** dove dice `config_token>`

7. Premi INVIO

**Completa la configurazione:**

11. **Team Drive:** Digita `n` + INVIO
12. **Confirm:** Digita `y` + INVIO
13. **Exit:** Digita `q` + INVIO

---

### Verifica rclone

```bash
# Verifica remote configurato
rclone listremotes
# Output: gdrive:

# Test connessione
rclone lsd gdrive:
# Deve mostrare le tue cartelle di Google Drive
```

---

### Crea Cartella di Backup

```bash
# Crea la cartella vps-backups su Google Drive
rclone mkdir gdrive:vps-backups

# Verifica che esista
rclone ls gdrive:vps-backups
# Output: (vuoto)
```

---

### Esegui il Primo Backup di Test

```bash
# Vai nella directory backups
cd /opt/ai-saas-stack/backups

# Rendi eseguibili gli script
chmod +x backup.sh restore.sh

# Esegui il backup
./backup.sh
```

**Output atteso:**
```
🚀 Starting backup...
📦 Creating n8n backup...
✅ n8n backup created: n8n-2026-02-17-0230.tar.gz
📦 Creating AnythingLLM backup...
✅ AnythingLLM backup created: anythingllm-2026-02-17-0230.tar.gz
📦 Creating .env backup...
✅ .env backup created: env-2026-02-17-0230.tar.gz
☁️  Uploading to Google Drive...
✅ Backup uploaded successfully
🧹 Cleaning up old local backups...
✅ Backup completed successfully!
```

---

### Verifica Backup su Google Drive

```bash
# Lista file nella cartella backup
rclone ls gdrive:vps-backups
```

**Output atteso:**
```
  1234567  n8n-2026-02-17-0230.tar.gz
   987654  anythingllm-2026-02-17-0230.tar.gz
     1234  env-2026-02-17-0230.tar.gz
```

**OPPURE** apri Google Drive nel browser e cerca la cartella `vps-backups`.

---

### Configura Backup Automatici

```bash
# Apri crontab
crontab -e
```

Aggiungi questa riga alla fine:

```cron
0 3 * * * /opt/ai-saas-stack/backups/backup.sh >> /opt/ai-saas-stack/backups/backup.log 2>&1
```

Salva e chiudi (`CTRL+O`, poi `CTRL+X`).

**Verifica il cron job:**

```bash
crontab -l
# Deve mostrare la riga appena aggiunta
```

Ora i backup verranno eseguiti **automaticamente ogni notte alle 3:00 AM**.

---

## 9. Verifica Finale

### Checklist Completa

```bash
# 1. Stato container
docker compose ps
# Tutti devono essere "Up"

# 2. Accesso ai servizi
curl -I https://app.tuodominio.com
curl -I https://llm.tuodominio.com
# Entrambi devono rispondere 200 OK

# 3. Backup configurato
rclone ls gdrive:vps-backups
# Deve mostrare i 3 file di backup

# 4. Cron job attivo
crontab -l | grep backup.sh
# Deve mostrare il job

# 5. Firewall configurato
sudo ufw status
# Porte 22, 80, 443 aperte
```

---

### Test Funzionale

1. **n8n:**
   - Apri https://app.tuodominio.com
   - Crea il tuo account admin
   - Crea un workflow di test

2. **AnythingLLM:**
   - Apri https://llm.tuodominio.com
   - Crea il tuo account admin
   - Configura un modello AI
   - Carica un documento di test

---

## 🎉 Deploy Completato!

Il tuo stack è ora:
- ✅ Installato e configurato
- ✅ Accessibile via HTTPS
- ✅ Protetto con certificati SSL validi
- ✅ Con backup automatici giornalieri
- ✅ Production-ready

---

## 📚 Documentazione Aggiuntiva

- **[README.md](README.md)** - Panoramica generale e riferimento rapido
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Soluzioni a problemi comuni
- **[Documentazione n8n](https://docs.n8n.io/)**
- **[Documentazione AnythingLLM](https://docs.anythingllm.com/)**

---

## 🔧 Comandi di Manutenzione

```bash
# Riavvia un servizio
docker compose restart n8n

# Aggiorna le immagini
cd /opt/ai-saas-stack
docker compose pull
docker compose up -d

# Backup manuale
cd /opt/ai-saas-stack/backups
./backup.sh

# Monitora log
docker compose logs -f

# Verifica backup
rclone ls gdrive:vps-backups
```

---

**Hai domande o problemi?**
- Consulta [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- Apri una issue su [GitHub](https://github.com/moldav69/ai-saas-stack/issues)

**Buon lavoro! 🚀**