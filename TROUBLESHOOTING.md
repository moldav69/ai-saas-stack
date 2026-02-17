# 🔧 Guida al Troubleshooting

Questa guida copre i problemi più comuni e le loro soluzioni durante il deployment dello stack AI SaaS.

## 🚨 Problemi Comuni e Soluzioni

### 1. Errore 502 Bad Gateway

**Sintomo:** Accedendo a `https://app.tuodominio.com` o `https://llm.tuodominio.com` vedi "502 Bad Gateway".

**Cause possibili:**

#### A) Container n8n o AnythingLLM in crash loop

```bash
# Verifica lo stato dei container
docker compose ps

# Se vedi "Restarting" accanto a n8n o anythingllm
# Controlla i log
docker compose logs n8n
docker compose logs anythingllm
```

**Soluzione:** Vedi le sezioni specifiche sotto per errori di permessi.

#### B) Configurazione errata del Proxy Host in Nginx Proxy Manager

**Verifica configurazione:**
- Accedi a `http://IP_VPS:81`
- Controlla il Proxy Host:
  - **Forward Hostname/IP deve essere il nome del container** (`n8n` o `anythingllm`), NON `localhost`
  - **Forward Port:** `5678` per n8n, `3001` per AnythingLLM
  - **Scheme:** `http` (non https)
  - **Websockets Support:** Abilitato (importante per n8n)

### 2. Errore di Permessi - n8n

**Sintomo:** n8n continua a riavviarsi. Nei log vedi:

```
Error: EACCES: permission denied, open '/home/node/.n8n/config'
```

**Causa:** La directory `n8n/data` non ha i permessi corretti per l'utente del container (UID 1000).

**Soluzione:**

```bash
# Ferma i container
docker compose down

# Correggi i permessi
sudo chown -R 1000:1000 n8n/data
sudo chmod -R 755 n8n/data

# Verifica
ls -la n8n/data
# Output atteso: drwxr-xr-x ... 1000 1000 ...

# Riavvia
docker compose up -d

# Monitora i log
docker compose logs -f n8n
```

**Output corretto dopo il fix:**
```
n8n | Editor is now accessible via:
n8n | http://localhost:5678/
n8n | n8n ready on 0.0.0.0, port 5678
```

### 3. Errore di Permessi - AnythingLLM

**Sintomo:** AnythingLLM continua a riavviarsi. Nei log vedi:

```
Error: Schema engine error:
SQLite database error
unable to open database file: ../storage/anythingllm.db
```

**Causa:** La directory `anythingllm/storage` non ha i permessi corretti per l'utente del container (UID 1000).

**Soluzione:**

```bash
# Ferma i container
docker compose down

# Correggi i permessi
sudo chown -R 1000:1000 anythingllm/storage
sudo chmod -R 755 anythingllm/storage

# Verifica
ls -la anythingllm/storage
# Output atteso: drwxr-xr-x ... 1000 1000 ...

# Riavvia
docker compose up -d

# Monitora i log
docker compose logs -f anythingllm
```

**Output corretto dopo il fix:**
```
anythingllm | [server] Server listening on port 3001
anythingllm | [server] AnythingLLM is ready!
```

### 4. Certificati Let's Encrypt Non si Generano

**Sintomo:** Nginx Proxy Manager mostra errori durante la richiesta del certificato SSL:

```
Some challenges have failed
```

**Soluzioni:**

#### A) Verifica DNS

```bash
# Controlla che il dominio punti all'IP corretto
dig app.tuodominio.com
# Oppure
nslookup app.tuodominio.com

# Deve rispondere con l'IP del tuo VPS
```

**Fix:** Configura correttamente i record DNS (A record) nel tuo provider DNS.

#### B) Verifica Firewall

```bash
# Controlla che le porte 80 e 443 siano aperte
sudo ufw status

# Output atteso:
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere

# Se mancano, aprile:
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

#### C) Disattiva Proxy Cloudflare (Temporaneamente)

Se usi Cloudflare come DNS provider:

1. Vai sul pannello Cloudflare
2. Clicca sulla **nuvola arancione** accanto ai record DNS per `app` e `llm`
3. La nuvola deve diventare **grigia** (DNS-only, no proxy)
4. Aspetta 5-10 minuti per la propagazione DNS
5. Richiedi il certificato SSL in Nginx Proxy Manager
6. Dopo aver ottenuto il certificato, puoi riattivare il proxy Cloudflare

#### D) Controlla i Log di Nginx Proxy Manager

```bash
docker compose logs reverse-proxy | grep -i error
docker compose logs reverse-proxy | grep -i certbot
```

### 5. Porta 81 Non Accessibile

**Sintomo:** Non riesci ad accedere a `http://IP_VPS:81` per configurare Nginx Proxy Manager.

**Causa:** La porta 81 non è aperta nel firewall.

**Soluzione:**

```bash
# Apri la porta 81
sudo ufw allow 81/tcp

# Verifica
sudo ufw status | grep 81
```

**⚠️ Sicurezza:** Dopo aver configurato i Proxy Host e i certificati SSL, chiudi la porta 81:

```bash
sudo ufw delete allow 81/tcp
```

Accedi all'admin UI tramite HTTPS usando un dominio dedicato (es. `admin.tuodominio.com`).

### 6. Container Non si Avviano

**Sintomo:** Uno o più container mostrano stato "Exited" o "Restarting".

**Diagnosi generale:**

```bash
# Verifica stato
docker compose ps

# Vedi i log del container problematico
docker compose logs <nome_servizio>

# Esempio:
docker compose logs n8n
docker compose logs anythingllm
docker compose logs reverse-proxy

# Vedi tutti i log in tempo reale
docker compose logs -f
```

**Problemi comuni:**

#### A) File .env mancante o incompleto

```bash
# Verifica che esista
ls -la .env

# Se non esiste, crealo
cp .env.example .env
nano .env

# Genera le chiavi mancanti
openssl rand -hex 32  # Per N8N_ENCRYPTION_KEY
openssl rand -hex 32  # Per JWT_SECRET
openssl rand -hex 32  # Per ENCRYPTION_KEY
```

#### B) Variabili d'ambiente vuote o invalide

```bash
# Controlla che tutte le chiavi siano impostate
cat .env | grep -E "(N8N_ENCRYPTION_KEY|JWT_SECRET|ENCRYPTION_KEY)"

# Non devono essere vuote o contenere placeholder tipo "YOUR_KEY_HERE"
```

### 7. DNS Non si Propaga

**Sintomo:** Il comando `dig app.tuodominio.com` non restituisce l'IP del tuo VPS.

**Soluzione:**

1. **Verifica configurazione DNS presso il provider:**
   - Record A per `app.tuodominio.com` → IP_VPS
   - Record A per `llm.tuodominio.com` → IP_VPS

2. **Aspetta la propagazione DNS:**
   - Può richiedere da 5 minuti a 48 ore
   - Normalmente: 15-30 minuti

3. **Usa DNS pubblici per testare:**
   ```bash
   # Test con Google DNS
   dig @8.8.8.8 app.tuodominio.com
   
   # Test con Cloudflare DNS
   dig @1.1.1.1 app.tuodominio.com
   ```

4. **Flush della cache DNS locale:**
   ```bash
   # Su Linux
   sudo systemd-resolve --flush-caches
   
   # Su macOS
   sudo dscacheutil -flushcache
   ```

### 8. Backup Script Non Funziona

**Sintomo:** Lo script di backup fallisce o non carica su Google Drive.

**Diagnosi:**

```bash
# Testa la connessione rclone
rclone ls gdrive:vps-backups

# Se fallisce, riconfigura
rclone config
```

**Problemi comuni:**

#### A) rclone non configurato

```bash
# Installa rclone
curl https://rclone.org/install.sh | sudo bash

# Configura il remote
rclone config
# Segui il wizard per Google Drive
```

#### B) Nome del remote non corrisponde

```bash
# Verifica il nome del remote in .env
cat .env | grep RCLONE_REMOTE_NAME

# Verifica i remote configurati
rclone listremotes

# Devono corrispondere!
```

#### C) Script non eseguibile

```bash
chmod +x backups/backup.sh
chmod +x backups/restore.sh
```

### 9. Container Non Comunicano tra Loro

**Sintomo:** Nginx Proxy Manager non riesce a raggiungere n8n o AnythingLLM (timeout, connection refused).

**Diagnosi:**

```bash
# Verifica che tutti i container siano sulla stessa rete
docker network inspect ai_saas_ai_saas_net

# Dovresti vedere tutti e 3 i container
```

**Soluzione:**

```bash
# Ricrea i container
docker compose down
docker compose up -d

# Test di connettività interno
docker exec -it nginx-proxy-manager sh
ping n8n
ping anythingllm
exit
```

## 🛠️ Comandi Utili per la Diagnosi

### Stato Generale

```bash
# Stato di tutti i container
docker compose ps

# Utilizzo risorse
docker stats

# Spazio disco
df -h

# Spazio usato da Docker
docker system df
```

### Log e Debug

```bash
# Log in tempo reale di tutti i servizi
docker compose logs -f

# Log di un servizio specifico
docker compose logs -f n8n

# Ultimi 100 log
docker compose logs --tail=100 n8n

# Log con timestamp
docker compose logs -t n8n
```

### Riavvio Servizi

```bash
# Riavvia un singolo servizio
docker compose restart n8n

# Riavvia tutti i servizi
docker compose restart

# Ferma e ricrea tutto
docker compose down
docker compose up -d
```

### Pulizia Sistema

```bash
# Rimuovi container, volumi e immagini inutilizzati
docker system prune -a

# Rimuovi solo container fermati
docker container prune

# Rimuovi immagini non usate
docker image prune -a
```

### Verifica Rete

```bash
# Lista reti Docker
docker network ls

# Ispeziona la rete dello stack
docker network inspect ai_saas_ai_saas_net

# Test connettività da un container
docker exec -it n8n sh
curl http://anythingllm:3001
exit
```

## 🐞 Debug Avanzato

### Accedere ai Container

```bash
# Shell interattiva in n8n
docker exec -it n8n sh

# Shell interattiva in AnythingLLM
docker exec -it anythingllm sh

# Shell interattiva in Nginx Proxy Manager
docker exec -it nginx-proxy-manager sh
```

### Controllare File di Configurazione

```bash
# Configurazione Nginx dentro il container
docker exec nginx-proxy-manager cat /data/nginx/proxy_host/1.conf

# Variabili d'ambiente di n8n
docker exec n8n env | grep N8N

# Variabili d'ambiente di AnythingLLM
docker exec anythingllm env | grep -E "(JWT|ENCRYPTION)"
```

### Verificare Permessi Interni

```bash
# Permessi dentro il container n8n
docker exec n8n ls -la /home/node/.n8n

# Permessi dentro il container AnythingLLM
docker exec anythingllm ls -la /app/server/storage
```

## 📞 Supporto

Se dopo aver seguito questa guida il problema persiste:

1. **Raccogli informazioni:**
   ```bash
   docker compose ps > debug-info.txt
   docker compose logs >> debug-info.txt
   cat .env | grep -v "PASSWORD\|KEY\|SECRET" >> debug-info.txt
   ```

2. **Apri una issue su GitHub:**
   - [https://github.com/moldav69/ai-saas-stack/issues](https://github.com/moldav69/ai-saas-stack/issues)
   - Allega `debug-info.txt` (rimuovi dati sensibili!)

3. **Consulta la documentazione ufficiale:**
   - n8n: [https://docs.n8n.io/](https://docs.n8n.io/)
   - AnythingLLM: [https://docs.anythingllm.com/](https://docs.anythingllm.com/)
   - Nginx Proxy Manager: [https://nginxproxymanager.com/](https://nginxproxymanager.com/)

---

**Creato con ❤️ per aiutarti a risolvere i problemi rapidamente**