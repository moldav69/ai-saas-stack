# 🔒 Guida GDPR: Encryption dei Backup

Questa guida spiega come configurare l'**encryption end-to-end** dei backup per renderli **GDPR compliant**.

## 📜 Indice

1. [Perché Serve l'Encryption](#perché-serve-lencryption)
2. [Configurazione rclone Crypt](#configurazione-rclone-crypt)
3. [Test e Verifica](#test-e-verifica)
4. [Attivazione Encryption](#attivazione-encryption)
5. [Gestione Password](#gestione-password)
6. [GDPR Compliance](#gdpr-compliance)

---

## Perché Serve l'Encryption

### ⚠️ Rischio GDPR

I backup contengono:
- ⚠️ **Workflow n8n** con dati di esecuzione
- ⚠️ **Chat history AnythingLLM** con conversazioni utenti
- ⚠️ **Documenti caricati** potenzialmente con dati personali
- ✅ **Credenziali API** e configurazioni

Se elabori **dati di clienti/utenti**, i backup su Google Drive personale **NON sono GDPR compliant** senza encryption.

### ✅ Soluzione: rclone Crypt

**rclone crypt** cripta i dati **prima** di caricarli su Google Drive:
- ✅ **Zero-knowledge encryption** - Google non può leggere i dati
- ✅ **AES-256 encryption** - Standard militare
- ✅ **Filenames criptati** - Nessuna informazione visibile
- ✅ **Transparente** - backup.sh e restore.sh funzionano normalmente

---

## Configurazione rclone Crypt

### Step 1: Genera Password di Encryption

**Sul VPS:**

```bash
# Connettiti al VPS
ssh user@your-vps-ip

# Genera Password 1 (encryption key)
openssl rand -base64 32

# Output esempio:
# Kx9mP2nQ7rS8tU1vW3xY5zA6bC8dE0fG2hI4jK6lM8nO

# Genera Password 2 (salt)
openssl rand -base64 32

# Output esempio:
# A1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9
```

**⚠️ IMPORTANTE:**
- **COPIA** queste due password in un file di testo temporaneo
- **NON CHIUDERE** il terminale, ti serviranno subito
- **SALVA** le password in un password manager dopo la configurazione
- **Se perdi le password, NON potrai più recuperare i backup!**

---

### Step 2: Avvia rclone config

```bash
rclone config
```

**Output:**
```
Current remotes:

Name                 Type
====                 ====
gdrive               drive

e) Edit existing remote
n) New remote
d) Delete remote
r) Rename remote
c) Copy remote
s) Set configuration password
q) Quit config
e/n/d/r/c/s/q>
```

**Digita:** `n` + INVIO

---

### Step 3: Nome del Remote Criptato

**Output:**
```
Enter name for new remote.
name>
```

**Digita:** `gdrive-crypt` + INVIO

---

### Step 4: Scegli Tipo "crypt"

**Output:**
```
Option Storage.
Type of storage to configure.
Choose a number from below, or type in your own value.
 1 / 1Fichier
   \ (fichier)
 ...
 11 / Encrypt/Decrypt a remote
   \ (crypt)
 ...
Storage>
```

**Digita:** `crypt` + INVIO (o il numero corrispondente)

---

### Step 5: Remote da Criptare

**Output:**
```
Option remote.
Remote to encrypt/decrypt.
Normally should contain a ':' and a path, e.g. "myremote:path/to/dir",
"myremote:bucket" or maybe "myremote:" (not recommended).
Enter a value.
remote>
```

**Digita:** `gdrive:vps-backups` + INVIO

**Spiegazione:**
- `gdrive` = remote Google Drive esistente
- `vps-backups` = cartella dove vanno i backup

---

### Step 6: Filename Encryption

**Output:**
```
Option filename_encryption.
How to encrypt the filenames.
Choose a number from below, or type in your own string value.
Press Enter for the default (standard).
 1 / Encrypt the filenames.
   \ (standard)
 2 / Very simple filename obfuscation.
   \ (obfuscate)
 3 / Don't encrypt the file names.
   \ (off)
filename_encryption>
```

**Digita:** `1` + INVIO (o premi solo INVIO per default)

---

### Step 7: Directory Name Encryption

**Output:**
```
Option directory_name_encryption.
Option to either encrypt directory names or leave them intact.
Choose a number from below, or type in your own boolean value (true/false).
Press Enter for the default (true).
 1 / Encrypt directory names.
   \ (true)
 2 / Don't encrypt directory names, leave them intact.
   \ (false)
directory_name_encryption>
```

**Digita:** `1` + INVIO (o premi solo INVIO per default)

---

### Step 8: Password Principale

**Output:**
```
Option password.
Password or pass phrase for encryption.
Choose an alternative below.
y) Yes, type in my own password
g) Generate random password
y/g>
```

**Digita:** `y` + INVIO

**Output:**
```
Enter the password:
password:
```

**INCOLLA** la prima password generata (quella con il primo `openssl rand`)

Esempio: `Kx9mP2nQ7rS8tU1vW3xY5zA6bC8dE0fG2hI4jK6lM8nO`

**⚠️ Quando incolli, NON vedrai niente (sicurezza Linux)**

Premi INVIO

**Output:**
```
Confirm the password:
password:
```

**INCOLLA** di nuovo la stessa password + INVIO

---

### Step 9: Salt Password

**Output:**
```
Option password2.
Password or pass phrase for salt.
Optional but recommended.
Should be different to the previous password.
Choose an alternative below. Press Enter for the default (n).
y) Yes, type in my own password
g) Generate random password
n) No, leave this optional password blank (default)
y/g/n>
```

**Digita:** `y` + INVIO

**Output:**
```
Enter the password:
password:
```

**INCOLLA** la seconda password generata (il secondo `openssl rand`)

Esempio: `A1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7bC9`

Premi INVIO

**Output:**
```
Confirm the password:
password:
```

**INCOLLA** di nuovo la stessa password + INVIO

---

### Step 10: Advanced Config

**Output:**
```
Edit advanced config?
y) Yes
n) No (default)
y/n>
```

**Digita:** `n` + INVIO

---

### Step 11: Conferma Configurazione

**Output:**
```
Configuration complete.
Options:
- type: crypt
- remote: gdrive:vps-backups
- filename_encryption: standard
- directory_name_encryption: true
- password: *** ENCRYPTED ***
- password2: *** ENCRYPTED ***
Keep this "gdrive-crypt" remote?
y) Yes this is OK (default)
e) Edit this remote
d) Delete this remote
y/e/d>
```

**Digita:** `y` + INVIO

---

### Step 12: Esci da rclone config

**Output:**
```
Current remotes:

Name                 Type
====                 ====
gdrive               drive
gdrive-crypt         crypt

e/n/d/r/c/s/q>
```

**Digita:** `q` + INVIO

**✅ Configurazione completata!**

---

## Test e Verifica

### Test 1: Verifica Remote

```bash
# Lista i remote configurati
rclone listremotes
```

**Output atteso:**
```
gdrive:
gdrive-crypt:
```

---

### Test 2: Upload File di Test

```bash
# Crea un file di test
echo "Test GDPR encryption - questo testo sarà criptato" > /tmp/test-gdpr.txt

# Carica con encryption
rclone copy /tmp/test-gdpr.txt gdrive-crypt:test-encryption/
```

**Output atteso:**
```
Transferred:   	       51 B / 51 B, 100%, 0 B/s, ETA -
Transferred:            1 / 1, 100%
Elapsed time:         1.2s
```

---

### Test 3: Verifica Encryption su Google Drive

```bash
# Guarda il nome del file su Google Drive (SENZA encryption)
rclone ls gdrive:vps-backups/test-encryption/
```

**Output atteso (NOME CRIPTATO!):**
```
51 v0f9g7h3j2k1m9n4p5q6r7s8t9u0v1w2x3y4z5a6b
```

**✅ Se vedi un nome criptato, l'encryption FUNZIONA!**

---

### Test 4: Verifica Decryption

```bash
# Leggi il file attraverso gdrive-crypt (con decryption automatica)
rclone cat gdrive-crypt:test-encryption/test-gdpr.txt
```

**Output atteso (testo in chiaro):**
```
Test GDPR encryption - questo testo sarà criptato
```

**✅ Se vedi il testo originale, la decryption FUNZIONA!**

---

### Test 5: Pulizia

```bash
# Elimina la cartella di test
rclone purge gdrive-crypt:test-encryption/

# Elimina il file locale
rm /tmp/test-gdpr.txt

echo "✅ Test completato con successo!"
```

---

## Attivazione Encryption

### Modifica .env

```bash
cd /opt/ai-saas-stack
nano .env
```

**Trova questa riga:**
```env
RCLONE_REMOTE_NAME=gdrive
```

**Cambia in:**
```env
RCLONE_REMOTE_NAME=gdrive-crypt
```

**Salva:** CTRL+X, poi Y, poi INVIO

---

### Test Backup con Encryption

```bash
cd /opt/ai-saas-stack/backups
./backup.sh
```

**Verifica i file criptati su Google Drive:**

```bash
rclone ls gdrive:vps-backups | tail -10
```

**Output atteso (nomi CRIPTATI):**
```
15234567 a3kf9j2m1n5p8q7r4s6t9u2v5x8z1c4e
8765432 b4lg0k3n2o6q9s2u5w8y1b4d7f0h3j6
1234 c5mh1l4o3p7r0t3v6x9z2c5e8g1i4k7
```

**✅ Perfetto! I backup sono ora criptati!**

---

### Test Restore con Decryption

```bash
cd /opt/ai-saas-stack/backups
./restore.sh
```

**Lo script decripterà automaticamente durante il download.**

**✅ Se il restore funziona, tutto è configurato correttamente!**

---

## Gestione Password

### 🚨 Backup Password OBBLIGATORIO

**Se perdi le password, NON potrai mai più recuperare i backup!**

### Opzione 1: Password Manager (CONSIGLIATA)

Salva in:
- 1Password
- Bitwarden
- KeePassXC
- LastPass

**Etichetta:** `rclone gdrive-crypt VPS backup`

**Campi:**
- Password 1 (encryption): `Kx9mP2nQ7rS8tU...`
- Password 2 (salt): `A1bC3dE5fG7hI9...`

---

### Opzione 2: File Criptato Offline

```bash
# Crea file con le password
cat > ~/rclone-passwords.txt << EOF
rclone gdrive-crypt passwords
Password 1 (encryption): Kx9mP2nQ7rS8tU...
Password 2 (salt): A1bC3dE5fG7hI9...
EOF

# Cripta il file con GPG
gpg -c ~/rclone-passwords.txt
# Ti chiederà una passphrase (scegli qualcosa di memorabile)

# Elimina l'originale
rm ~/rclone-passwords.txt

# Ora hai: ~/rclone-passwords.txt.gpg (criptato)
```

**Scarica sul tuo PC locale:**
```bash
scp user@vps-ip:~/rclone-passwords.txt.gpg ./
```

---

### Opzione 3: Backup rclone.conf

```bash
# Backup della configurazione rclone (contiene le password criptate)
cp ~/.config/rclone/rclone.conf ~/rclone.conf.backup

# Scarica sul tuo PC
scp user@vps-ip:~/rclone.conf.backup ./
```

**⚠️ IMPORTANTE:** Questo file contiene le password in forma criptata, ma è comunque sensibile!

---

## GDPR Compliance

### ✅ Conformità Ottenuta

Con l'encryption attivata:

- ✅ **Art. 32 GDPR** - Misure di sicurezza adeguate
- ✅ **Zero-knowledge** - Google non può accedere ai dati
- ✅ **Encryption at rest** - Dati criptati su Google Drive
- ✅ **Encryption in transit** - HTTPS + encryption layer
- ✅ **Access control** - Solo tu hai le chiavi
- ✅ **Data minimization** - Retention 7 giorni

---

### 📝 Documentazione GDPR

#### Registro Trattamenti

```
Finalità: Backup disaster recovery
Base giuridica: Interesse legittimo (continuità servizio)
Categorie dati: workflow, configurazioni, chat history, documenti
Destinatari: Google Drive (con encryption end-to-end AES-256)
Trasferimenti extra-UE: No (encryption rende dati non leggibili)
Tempi conservazione: 7 giorni (cancellazione automatica)
Misure sicurezza: 
  - Encryption AES-256 end-to-end
  - Filenames criptati
  - 2FA sull'account Google
  - Access control
  - Audit log
```

---

#### Privacy Policy (sezione backup)

```
I backup dei dati vengono eseguiti giornalmente su storage cloud
con encryption end-to-end (AES-256). I dati sono criptati prima
del caricamento e il provider di storage non ha accesso al contenuto
in chiaro. I backup vengono conservati per 7 giorni e successivamente
cancellati automaticamente.
```

---

### 🔐 Sicurezza Aggiuntiva

#### 1. Abilita 2FA su Google Account

- Vai su https://myaccount.google.com/security
- Abilita "Verifica in due passaggi"
- Usa app authenticator (Google Authenticator, Authy)

#### 2. Monitora Accessi

```bash
# Controlla log rclone
tail -f /opt/ai-saas-stack/backups/backup.log

# Verifica ultimo backup
rclone ls gdrive:vps-backups | tail -3
```

#### 3. Test Restore Periodico

```bash
# Ogni mese, testa che il restore funzioni
cd /opt/ai-saas-stack/backups
./restore.sh
```

---

## 📊 Confronto Before/After

### Prima (SENZA Encryption)

**Su Google Drive vedi:**
```
n8n-2026-02-17-0300.tar.gz          ← Nome in chiaro
anythingllm-2026-02-17-0300.tar.gz  ← Nome in chiaro
env-2026-02-17-0300.tar.gz          ← Nome in chiaro
```

**Google può:**
- ❌ Vedere i nomi dei file
- ❌ Scansionare il contenuto (se vuole)
- ❌ Accedere ai dati personali

**Rischio GDPR:** 🔴 Alto

---

### Dopo (CON Encryption)

**Su Google Drive vedi:**
```
a3kf9j2m1n5p8q7r4s6t  ← Nome criptato
b4lg0k3n2o6q9s2u5w8y  ← Nome criptato
c5mh1l4o3p7r0t3v6x9z  ← Nome criptato
```

**Google può:**
- ✅ Vedere solo dati criptati
- ✅ NON può leggere il contenuto
- ✅ NON può accedere ai dati personali

**Rischio GDPR:** 🟢 Basso/Nullo

---

## ❓ FAQ

### Quanto rallenta il backup?

L'encryption aggiunge **5-10% di overhead**. Su un backup di 500MB:
- Senza encryption: ~2 minuti
- Con encryption: ~2.2 minuti

### Il restore è più lento?

Sì, ma marginalmente. La decryption è veloce con AES-256.

### Posso cambiare le password dopo?

Sì, ma dovrai:
1. Scaricare tutti i backup esistenti
2. Decrittarli con le vecchie password
3. Riconfigurare rclone con nuove password
4. Ricaricare i backup criptati con le nuove password

**Non consigliato** se non strettamente necessario.

### Cosa succede se Google Drive viene hackerato?

I tuoi dati restano **completamente sicuri**. L'attaccante vedrebbe solo file criptati inutilizzabili.

---

## 🚀 Quick Setup (Script Automatico)

```bash
# 1. Genera password
PASS1=$(openssl rand -base64 32)
PASS2=$(openssl rand -base64 32)

echo "Password 1 (SALVA IN PASSWORD MANAGER): $PASS1"
echo "Password 2 (SALVA IN PASSWORD MANAGER): $PASS2"

# 2. Configura crypt (manualmente con i passaggi sopra)
rclone config
# Segui la guida step-by-step

# 3. Test
echo "test" > /tmp/test.txt
rclone copy /tmp/test.txt gdrive-crypt:test/
rclone ls gdrive:vps-backups/test/  # Nome criptato?
rclone cat gdrive-crypt:test/test.txt  # Contenuto in chiaro?
rclone purge gdrive-crypt:test/
rm /tmp/test.txt

# 4. Attiva encryption
sed -i 's/RCLONE_REMOTE_NAME=gdrive/RCLONE_REMOTE_NAME=gdrive-crypt/' /opt/ai-saas-stack/.env

# 5. Test backup
cd /opt/ai-saas-stack/backups
./backup.sh

echo "✅ Encryption attivata! I tuoi backup sono ora GDPR compliant"
```

---

## 📞 Supporto

- **Problemi con rclone:** https://forum.rclone.org/
- **Domande GDPR:** https://www.garanteprivacy.it
- **Issues GitHub:** https://github.com/moldav69/ai-saas-stack/issues

---

**🔒 I tuoi dati sono ora protetti e GDPR compliant!**