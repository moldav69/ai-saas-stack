# 🔒 Guida Sicurezza - AI SaaS Stack

Questo documento descrive le best practices di sicurezza implementate nello stack e come configurare correttamente i servizi per evitare vulnerabilità.

---

## 🚨 VULNERABILITÀ CRITICHE DA EVITARE

### 1. AnythingLLM: Setup Wizard Bypass

**❌ PROBLEMA CRITICO:**

Se inserisci `JWT_SECRET` e `ENCRYPTION_KEY` nel file `.env` **PRIMA** del primo avvio, AnythingLLM:
- Salta il wizard di setup iniziale
- NON chiede di creare un account admin
- Permette l'accesso senza autenticazione
- **CHIUNQUE** può accedere al tuo sistema come amministratore!

**✅ SOLUZIONE:**

```env
# Nel file .env - LASCIA VUOTI questi campi:
JWT_SECRET=
ENCRYPTION_KEY=
```

**Cosa succede quando sono vuoti:**
1. AnythingLLM parte senza configurazione
2. Al primo accesso web, mostra il **wizard di setup**
3. Ti chiede di creare un account admin con username/password
4. Genera automaticamente le chiavi JWT/ENCRYPTION in modo sicuro
5. Salva tutto nel database interno

**🔒 Questo è l'UNICO modo sicuro per configurare AnythingLLM!**

---

## 🛡️ Best Practices Implementate

### Architettura di Rete

✅ **Nessuna porta esposta direttamente su Internet**
- n8n: porta 5678 accessibile SOLO tramite reverse proxy
- AnythingLLM: porta 3001 accessibile SOLO tramite reverse proxy
- Nginx Proxy Manager: porta 81 (admin) esposta solo per configurazione iniziale

✅ **HTTPS obbligatorio**
- Certificati SSL/TLS automatici tramite Let's Encrypt
- Redirect automatico da HTTP a HTTPS
- HSTS header abilitato

✅ **Network isolation**
- Tutti i container comunicano su rete Docker privata `ai_saas_net`
- Nessuna comunicazione diretta con l'host

### Autenticazione e Autorizzazione

✅ **n8n: Basic Authentication**
```env
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=<password-forte>
```

✅ **AnythingLLM: Setup Wizard Forzato**
```env
JWT_SECRET=    # Lascia VUOTO!
ENCRYPTION_KEY=   # Lascia VUOTO!
```

✅ **Nginx Proxy Manager**
- Credenziali default cambiate al primo accesso
- MFA consigliata (configurabile nell'UI)

### Encryption e Chiavi

✅ **Chiavi generate con openssl**
```bash
openssl rand -hex 32
```

✅ **Chiavi uniche per ogni installazione**
- NON usare chiavi di esempio
- NON condividere chiavi tra ambienti

✅ **Backup criptati (opzionale GDPR)**
- AES-256 encryption
- Filename obfuscation
- Zero-knowledge architecture

### Container Security

✅ **Utente non-root**
```yaml
user: "1000:1000"
```

✅ **Log rotation**
```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"
```

✅ **Versioni pinnate/latest controllato**
- n8n: 2.7.5 (stable)
- AnythingLLM: latest (auto-fix sicurezza)
- Nginx PM: 2.12.6 (stable)

---

## 🔧 Configurazione Sicura Step-by-Step

### 1. Clona Repository

```bash
cd /opt
git clone https://github.com/moldav69/ai-saas-stack.git
cd ai-saas-stack
```

### 2. Crea .env da Template

```bash
cp .env.example .env
```

### 3. Configura n8n (Genera Chiavi)

```bash
# Genera chiave encryption per n8n
N8N_KEY=$(openssl rand -hex 32)

# Inserisci nel .env
sed -i "s/^N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$N8N_KEY/" .env

# Cambia password basic auth
nano .env
# Modifica: N8N_BASIC_AUTH_PASSWORD=<tua-password-forte>
```

### 4. Configura AnythingLLM (LASCIA VUOTO!)

```bash
# Verifica che siano vuoti
grep -E "^(JWT_SECRET|ENCRYPTION_KEY)=" .env

# Output atteso:
# JWT_SECRET=
# ENCRYPTION_KEY=
```

**⚠️ Se vedi valori, CANCELLALI:**

```bash
sed -i 's/^JWT_SECRET=.*/JWT_SECRET=/' .env
sed -i 's/^ENCRYPTION_KEY=.*/ENCRYPTION_KEY=/' .env
```

### 5. Permessi Directory

```bash
# Crea directory con permessi corretti
sudo chown -R 1000:1000 n8n/ anythingllm/
sudo chmod -R 755 n8n/ anythingllm/
```

### 6. Avvia Stack

```bash
docker compose up -d
```

### 7. Setup Iniziale AnythingLLM

1. Apri `https://llm.tuodominio.com` nel browser
2. Vedrai il **wizard di setup**
3. Crea account admin:
   - Username: scegli (es: `admin`)
   - Password: **forte e unica** (salvala in password manager!)
4. Configura LLM provider
5. Configura embedding provider
6. Crea primo workspace

✅ **Setup completato in modo sicuro!**

---

## 🔍 Verifica Sicurezza Post-Deploy

### Checklist di Sicurezza

```bash
# 1. Verifica porte esposte
sudo netstat -tlnp | grep -E "(5678|3001)"
# NON devono essere in ascolto su 0.0.0.0!

# 2. Verifica firewall
sudo ufw status
# Devono essere aperti SOLO: 22, 80, 443

# 3. Verifica .env non ha chiavi placeholder
grep -E "CAMBIA_QUESTO|INSERISCI_LA_TUA" .env
# NON deve trovare nulla!

# 4. Verifica AnythingLLM ha richiesto setup
docker compose logs anythingllm | grep -i "setup"

# 5. Test autenticazione n8n
curl -I https://app.tuodominio.com
# Deve rispondere: 401 Unauthorized (se non autenticato)

# 6. Test autenticazione AnythingLLM
curl -I https://llm.tuodominio.com/api/v1/workspaces
# Deve rispondere: 401 Unauthorized (se non autenticato)
```

---

## 🐛 Cosa Fare in Caso di Breach

### Compromissione Credenziali n8n

```bash
# 1. Cambia password nel .env
nano .env
# Modifica: N8N_BASIC_AUTH_PASSWORD=<nuova-password-forte>

# 2. Riavvia n8n
docker compose restart n8n
```

### Compromissione Account AnythingLLM

```bash
# 1. Reset completo (perde dati!)
cd /opt/ai-saas-stack
./reset-anythingllm.sh

# 2. Rifai setup con nuove credenziali
```

### Compromissione VPS

```bash
# 1. Backup immediato
cd /opt/ai-saas-stack/backups
./backup.sh

# 2. Deploy su nuovo VPS
# Segui SETUP-GUIDE.md su nuovo server

# 3. Restore backup
./restore.sh

# 4. Cambia TUTTE le password
```

---

## 🛡️ Hardening Aggiuntivo

### SSH Security

```bash
# 1. Disabilita login root
sudo nano /etc/ssh/sshd_config
# Imposta:
# PermitRootLogin no
# PasswordAuthentication no
# PubkeyAuthentication yes

# 2. Riavvia SSH
sudo systemctl restart sshd
```

### Fail2Ban

```bash
# Installa fail2ban
sudo apt update
sudo apt install fail2ban -y

# Configura per SSH
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Imposta:
# [sshd]
# enabled = true
# maxretry = 3
# bantime = 3600

# Avvia
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Aggiornamenti Automatici

```bash
# Installa unattended-upgrades
sudo apt install unattended-upgrades -y

# Configura
sudo dpkg-reconfigure -plow unattended-upgrades

# Verifica
sudo systemctl status unattended-upgrades
```

### Monitoring

```bash
# Installa monitoring semplice
sudo apt install htop iotop nethogs -y

# Cron per monitoraggio disk space
crontab -e

# Aggiungi:
0 * * * * df -h | grep -E "(/$|/opt)" | awk '$5+0 > 80 {print "ALERT: Disk usage " $5 " on " $6}' | mail -s "Disk Alert" tua@email.com
```

---

## 📝 Log Audit

### Log Importanti da Monitorare

```bash
# Log accessi AnythingLLM
docker compose logs anythingllm | grep -i "login\|auth"

# Log accessi n8n
docker compose logs n8n | grep -i "auth"

# Log Nginx (accessi web)
docker compose logs reverse-proxy | grep -E "(POST|GET)"

# Log sistema (SSH tentativi)
sudo tail -f /var/log/auth.log
```

### Centralizzazione Log (Opzionale)

```bash
# Configura syslog remoto o servizio tipo Loki/Grafana
# Per installazioni production-grade
```

---

## 📞 Reporting Vulnerabilità

Se trovi una vulnerabilità di sicurezza:

1. **NON** aprire issue pubblico su GitHub
2. Invia email a: [sapunarumichelangelo@gmail.com]
3. Includi:
   - Descrizione della vulnerabilità
   - Step per riprodurla
   - Impatto stimato
   - Eventuale fix proposto

**Tempo di risposta:** < 48 ore

---

## 📚 Risorse Aggiuntive

- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)

---

## ✅ Conclusione

Seguendo questa guida:

✅ AnythingLLM richiede sempre setup iniziale sicuro  
✅ Nessun accesso non autorizzato possibile  
✅ Tutte le comunicazioni sono criptate (HTTPS)  
✅ Backup possono essere criptati (GDPR compliant)  
✅ Log e monitoring attivi  
✅ Sistema hardened contro attacchi comuni  

**Il tuo stack è sicuro! 🔒**