# Onboarding Script per CyberArk 

## Informazioni Generali
  - **Nome:** Onboarding 
  - **Autore:** Cybertech - Team PAM  
  - **Versione:** v1.5

## UPDATE
  **News**
  - Corretto il bug relativo alla visualizzazione dei remote machine per gli account di dominio
  - Corretto il bug: `un account di dominio con una lista target superiore a 255 caratteri porterà ad un errore di stack`
  - Corretto il bug relativo al link delle utenze unix locali

**BUG-Report**
- **Account non creato**
  Se crei un account senza aver creato precedentemente la safe relativa all'account, l'account in questione non verrà creato

**BUG-fixed**
 - La lista dei remote machine degli account di dominio ora viene visulizzata correttamente in CyberArk
 - Un account di dominio può avere in input un "grande" numero di remote machine
 - **OLD**
    - Aggiunto il medoto di creazione safe. Risolve parzialmente il problema `Account non creato`.
    - Corretto bug relativo al comando `accetta tutti`.


## Descrizione
Questo script automatizza il processo di onboarding degli account in **CyberArk Privilege Cloud** per il cliente **Aria S.p.A.**.

Il sistema elabora un file **CSV** contenente i dati dei fornitori e delle relative macchine associate, trasformandoli in un formato standardizzato per l'onboarding.

Lo script utilizza il modulo **PSPAS** [(GitHub)](https://github.com/pspete/pspas) per interagire in modo sicuro ed efficiente con CyberArk.

## Funzionalità
**Automazione completa** – Importazione ed elaborazione automatizzata degli account.  
**Modularità e adattabilità** – Configurabile per diversi clienti.  
**Integrazione con CyberArk** – Gestione automatizzata di Safe, Account e Platform.  
**Logging dettagliato** – Generazione di log per tracciare le operazioni eseguite.  
**Output dei risultati** – Generazione di output delle safe e degli account creati

---

## Prerequisiti
- Windows PowerShell **v5** (o superiore)
- **Tenant CyberArk Privilege Cloud**
- Account di servizio con permessi di amministratore su Privilege Cloud
- **Moduli PowerShell richiesti:**
  - [PSPAS](https://github.com/pspete/pspas)
  - IdentityCommand

### Installazione dei moduli
Aprire PowerShell come amministratore ed eseguire:
```powershell
Install-Module -Name psPAS -Scope CurrentUser
Install-Module -Name IdentityCommand -Scope CurrentUser
```
Se l'installazione fallisce, modificare la policy di esecuzione con:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
```

---

## Configurazione
### **File di configurazione: `config.ini`**
Contiene le impostazioni principali dello script.

#### **Esempio di Config.ini**
```ini
[CONFIG]
Tenant=NomeTenant
Dominio=DominioDiRiferimento
CPM=NomeCPM
ServiceUser=NomeUtenzaServizio

[SAFE]
Ambiente=Prod|Test|Svil
Device=Srv|DB|Rout

[SO]
Windows=WIN
Unix=NIX
Local=LA
Domain=DU
Recon=RECON
Admin=ADM
Root=ROOT
Emergenza=EME

[USER]
UsernameSTD=usr-pam
```

---

### **File `account.csv`**
Contiene i dati degli account da onboardare.

#### **Struttura del file**
| Fornitore | Alias | SistemaOperativo | LocaleDominio | NumeroUtenze |     ListaTargets    |
|-----------|-------|------------------|---------------|--------------|---------------------|
| Virgilio  | virg  | nix              | dom           | 2            | virgo.local 3.3.3.3 |

🔹 **Note:**
- `Alias`: Abbreviazione max 4 caratteri per Safe e account.
- `SistemaOperativo`: `windows` o `nix`.
- `LocaleDominio`: `dom` (dominio) o `loc` (locale).
- `NumeroUtenze`: Esclude utenti di emergenza, root, reconcile e admin (creati automaticamente).
- `ListaTargets`: Elenco FQDN, hostname o IP, separati da spazio.

---

## Esecuzione
1 Aprire PowerShell  
2 Posizionarsi nella cartella root dello script  
3 Eseguire:
```powershell
.\PS_Onboarding.ps1 [-Debug] [-Verbose]
```

Lo script chiederà di selezionare un'opzione:
- **1** – Avvia la creazione automatica delle safe
- **2** – Avvia l'onboarding automatico degli account
- **q** – Termina il programma

Durante l'esecuzione, lo script:
- Controlla il file di input.
- Crea l'account di reconcile di dominio (se assente).
- Estrae i dati necessari.
- Mostra un riepilogo e chiede conferma:
  - **Y** – Conferma l'onboarding per il fornitore corrente.
  - **N** – Salta il fornitore corrente.
  - **A** – Accetta tutti i fornitori successivi senza ulteriori richieste.

---

## Dettagli sull'Onboarding
Lo script gestisce 4 tipologie di onboarding:

### 1 **Windows - Dominio** (`win-dom`)
- Creazione Safe e Platform
- Creazione account:
  - **Emergenza**
  - **Account di dominio** (n° specificato)
- Collegamento a **Reconcile** (se presente)

### 2 **Windows - Locale** (`win-local`)
- Creazione Safe e Platform
- Creazione account per ogni target:
  - **Reconcile**
  - **Emergenza**
  - **Locali** (n° specificato)
- Collegamento a **Reconcile** locale (se presente)

### 3 **Unix/Linux - Dominio** (`nix-dom`)
- Creazione Safe e Platform
- Creazione account:
  - **Emergenza**
  - **Account di dominio** (n° specificato)
  - **Admin**
- Collegamento **Reconcile** per gli account
- Collegamento **Logon** con account `DU` (se presente)

### 4 **Unix/Linux - Locale** (`nix-local`)
- Creazione Safe e Platform
- Creazione account per ogni target:
  - **Reconcile**
  - **Emergenza**
  - **Locali** (n° specificato)
  - **Admin**
- Collegamento **Reconcile** locale (se presente)
- Collegamento **Logon** con account `LA` (se presente)

---

## Risultati
Per ogni account creato, lo script:
- **Genera le Safe** e le Platform **se assenti**.
- **Crea gli account** rispettando la configurazione fornita.
- **Collega gli account** a reconcile o logon se richiesto.

**Esempio di Safe generata:**  
Fornitore **Virgilio**, server **produzione Unix**, account **locale** → `PROD-SRV-NIX-VIRG-LA`

**Esempio di username generato:**  
`usr-pam-nix-virg-0x`

## Output
Nella sottocartella **.\Output** sono generati due file **.csv**:
  - **AdGroup_DOMINIO.csv**: contenente le safe generate durante l'esecuzione dello script, mostrando nome e descrizione 
    - **Esempio**: `PROD-SRV-NIX-VIRG-LA`, `Safe dedicata per gli utenti unix locali per fornitori virgilio`
  - **Utenze_DOMINIO.csv**: contenente gli account generati durante l'esecuzione dello script, dividendoli per fornitore
    - **Esempio**: `Virgilio`, `usr-pam-nix-virg-01`,`usr-pam-nix-virg-02`,`usr-pam-nix-virg-03`

---

## Conclusione
Questo script semplifica e standardizza l'onboarding degli account in **CyberArk Privilege Cloud**, garantendo efficienza e sicurezza.

