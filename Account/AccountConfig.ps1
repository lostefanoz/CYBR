$global:UsernameRecon = $UsernameSTD.ToLower() + $Recon.ToLower()

function LoadUsersCsv {
    if (Test-Path $CSV_UTENZE) {
        $righe = Import-Csv -Path $CSV_UTENZE -Encoding UTF8
        foreach ($riga in $righe) {
            $fornitore = $riga.Fornitore
            $utenza = $riga.Utenza

            if (-not $FornitoriUtenze.ContainsKey($fornitore)) {
                $FornitoriUtenze[$fornitore] = @()
            }

            if ($FornitoriUtenze[$fornitore] -notcontains $utenza) {
                $FornitoriUtenze[$fornitore] += $utenza
            }
        }
        Write-LogMessage -MSG "Dati esistenti caricati da: $CSV_UTENZE" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        Write-Host "Dati esistenti caricati da: $CSV_UTENZE"
    } else {
        Write-LogMessage -MSG "Nessun file CSV trovato in: $CSV_UTENZE. Verrà creato uno nuovo." -Type Debug -LogFile $LOG_FILE_ACCOUNT
    }
}

function AppendUser {
    param (
        [string]$Fornitore,
        [string]$Utenza
    )

    if (-not $FornitoriUtenze.ContainsKey($Fornitore)) {
        $FornitoriUtenze[$Fornitore] = @()
    }

    if ($FornitoriUtenze[$Fornitore] -notcontains $Utenza) {
        $FornitoriUtenze[$Fornitore] += $Utenza
    }
}

function SaveUsersCSV {

    # Array per tenere righe in formato stringa
    $righe = @()

    # Prima riga intestazione
    $righe += "Fornitore,Utenza"

    # Per ogni fornitore, unisci le utenze in una riga separata da virgole
    foreach ($fornitore in $FornitoriUtenze.Keys) {
        $utenze = $FornitoriUtenze[$fornitore] -join ","
        $riga = "$fornitore,$utenze"
        $righe += $riga
    }

    # Salva tutto come testo (non usare Export-Csv qui)
    Set-Content -Path $CSV_UTENZE -Value $righe -Encoding UTF8
    Write-LogMessage -MSG "File CSV aggiornato e salvato in: $CSV_UTENZE" -Type Debug -LogFile $LOG_FILE_ACCOUNT
}


# Funzione per generare un nome utente in base ai parametri forniti
function GetUsername {
    param (
        [string]$SO,
        [string]$Alias,
        [string]$LocDom,
        [string]$Suffix
    )

    Write-LogMessage -MSG "Generazione username con SO: '$SO', Alias: '$Alias', LocDom: '$LocDom', Suffix: '$Suffix'" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    if ($Suffix -match $Recon) {
        $body = $UsernameSTD.ToLower() + $Recon.ToLower()
        return $body
    }

    # if ($Suffix -match $Root) {
    #     return "root"
    # }

    $body = $UsernameSTD.ToLower()
    if (($SO -match $Unix) -and ($Suffix -match $Admin)) {
        $body += $Alias.ToLower() + "-" + $Suffix.ToLower()
        return $body
    }
    
    $body += $SO.ToLower() + "-" + $Alias.ToLower()

    if ($Suffix -match $Emergenza) {
        $body += "-" + $Suffix.ToLower() 
    }
    return $body
}

# Funzione per per normalizzare e determinare se l'ambiente è "Dominio" o "Locale"
function SetLocDom {
    param ( [string]$LocDom)

    Write-LogMessage -MSG "Verifico se il valore di LocaleDominio e' una stringa accettata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "Il valore di LocaleDominio deve essere una stringa contenente uno dei seguenti caratteri: 'dom|dominio|d|domain|du|local|locale|loc|l|la'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    $LocDom = $LocDom.Trim().ToLower()

    if ($LocDom -match 'dom|dominio|d|domain|du') { 
        Write-LogMessage -MSG "Il valore di LocDom risulta essere 'Dominio'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        return 'DOM'
    } 
    elseif ($LocDom -match 'local|locale|loc|l|la') {
        Write-LogMessage -MSG "Il valore di LocDom risulta essere 'Locale'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        return 'LOCAL'
    } 
    else {
        Write-LogMessage -MSG "Il valore di LocDom non valido." -Type Error -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Il valore di LocDom viene impostato a $NoName per informazioni non corrette" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
        return $NoName
    }
}
# Funzione per normalizzare e determinare il sistema operativo
function SetSistemaOperativo {
    param ( [string]$SistemaOperativo)
    Write-LogMessage -MSG "Verifico se il valore del Sistema Operativo e' una stringa accettata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "Il valore di LocaleDominio deve essere una stringa contenente uno dei seguenti caratteri: 'windows|win|w|n|nix|unix|linux|redhat|debian|centos'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    $SO = $SistemaOperativo.ToLower()

    # Verifica e restituisce il valore corretto
    if ($SO -match 'windows|win|w') { 
        Write-LogMessage -MSG "Il valore del Sistema Operativo risulta essere '$Windows'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        return $Windows
    } 
    
    elseif ($SO -match 'n|nix|unix|linux|redhat|debian|centos') {
        Write-LogMessage -MSG "Il valore del Sistema Operativo risulta essere '$Unix'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
        return $Unix
    } 

    else {
        Write-LogMessage -MSG "Il valore del Sistema Operativo non valido." -Type Error -LogFile $LOG_FILE_ACCOUNT
        Write-LogMessage -MSG "Il valore del Sistema Operativo viene impostato a $NoName per informazioni non corrette" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
        return $NoName
    }
}

# Funzione per validare l'alias
function CheckAlias {
    param (
        [string]$Alias,
        [string]$Fornitore,
        [string]$SO,
        [string]$LocDom
    )
    Write-LogMessage -MSG "Verifico Alias '$Alias' per il fornitore '$Fornitore'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "l'alias deve essere una stringa non vuota di massimo 4 caratteri" -Type Verbose -LogFile $LOG_FILE_ACCOUNT

    # Verifica se la stringa è vuota
    if ($Alias -eq "") {
        Write-LogMessage -MSG "Alias vuoto, richiesta inserimento utente." -Type Debug -LogFile $LOG_FILE_ACCOUNT

        $Alias = Read-Host "Inserisci un alias per il fornitore '$Fornitore' (max 4 caratteri)"
        while ($Alias -eq "") {
            $Alias = Read-Host "Alias inserito non valido. Riprova"
        }        
        
    }
    $AccountType = $SO + "-" + $LocDom

    # Loop fino a quando l'alias è valido
    while ($true) {
        if ($Alias.Length -gt 4 -and -not($AccountType -match 'NIX-LOCAL')) {
            # Se la lunghezza supera 4, tronca e mostra la parola
            $AliasTruncated = $Alias.Substring(0, 4)

            Write-LogMessage -MSG "L'alias '$Alias' supera i 4 caratteri. Esso verra' troncato in '$AliasTruncated'" -Type Warning -LogFile $LOG_FILE_ACCOUNT
            
            $response = Read-Host "Accettare l'alias troncato? (Y/N)"
            
            if ($response -eq "Y") {
                # Se l'utente accetta, esci dal loop
                Write-LogMessage -MSG "Alias accettato '$AliasTruncated'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
                return $AliasTruncated
            } else {
                # Se l'utente rifiuta, chiedi un nuovo alias
                Write-LogMessage -MSG "Inserisci un alias per il fornitore '$Fornitore' (max 4 caratteri):" -Type Warning -LogFile $LOG_FILE_ACCOUNT
                $Alias = Read-Host
                while ($Alias.Length -gt 4 -or $Alias -eq "") {
                    $Alias = Read-Host "L'alias deve essere di massimo 4 caratteri. Riprova"
                }
            }
        } else {
            # Se la lunghezza è <= 4, accetta l'alias e esci dal loop
            Write-LogMessage -MSG "Alias accettato '$Alias'" -Type Debug -LogFile $LOG_FILE_ACCOUNT
            return $Alias
        }
    }
}

# Funzione per verificare il numero di utenze
function CheckNroUtente {
    param ( [int]$NroUtenze )
    
    Write-LogMessage -MSG "Verifico se numero utenze e' una numero accettato:" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "Il valore di numero utenze deve essere un intero maggiore di 0" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    if ($NroUtenze -le 0) {
        
        Write-LogMessage -MSG "Numero utenze non valido." -Type Error -LogFile $LOG_FILE_ACCOUNT
        $NroUtenze = -1
        Write-LogMessage -MSG "Il numero utenze viene impostato a '$NroUtenze' per informazioni non valide" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
        
    }

    Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    return $NroUtenze
}

# Funzione per verificare il nome del fornitore
function CheckFornitore {
    param ( [string]$Fornitore )
    Write-LogMessage -MSG "Verifico se il nome del fornitore e' una stringa accettata:" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "Il nome del fornitore deve essere una stringa non vuota" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    if ($Fornitore -eq "") {
        Write-LogMessage -MSG "Nome fornitore assente." -Type Error -LogFile $LOG_FILE_ACCOUNT
        $Fornitore = $NoName
        Write-LogMessage -MSG "Il nome fornitore viene impostato a '$Fornitore' per mancanza di informazioni" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    }

    Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    return $Fornitore
}

# Funzione per verificare la lista dei target
function CheckTargets {
    param ( [string]$ListaTargets )

    Write-LogMessage -MSG "Verifico se la lista dei targets del fornitore e' una stringa accettata:" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    Write-LogMessage -MSG "La lista dei targets fornitore deve essere una stringa non vuota" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    if ($ListaTargets -eq "") {
        Write-LogMessage -MSG "La lista dei targets e' assente."  -Type Error -LogFile $LOG_FILE_ACCOUNT
        $ListaTargets = $NoName
        Write-LogMessage -MSG "La lista dei targets viene impostato a '$ListaTargets' per mancanza di informazioni" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    }

    Write-LogMessage -MSG "Verifica completata" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    return $ListaTargets
    
}

# Classe per la gestione delle informazioni del fornitore
class FornitoreInfo {
    [string]$Fornitore
    [string]$Alias
    [string]$SO
    [string]$LocDom
    [int]$NroUtenze
    [string]$ListaTargets
    [string[]]$TargetsArray
    [string]$RemoteMachine

    # Costruttore
    FornitoreInfo([string]$Fornitore, [string]$Alias, [string]$SO, 
                  [string]$LocDom, [int]$NroUtenze, [string]$ListaTargets) 
    {
        $this.Fornitore = CheckFornitore -Fornitore $Fornitore
        $this.SO = SetSistemaOperativo -SistemaOperativo $SO
        $this.LocDom = SetLocDom -LocDom $LocDom
        $this.Alias = CheckAlias -Alias $Alias -Fornitore $this.Fornitore -SO $this.SO -LocDom $this.LocDom
        $this.NroUtenze = CheckNroUtente -NroUtenze $NroUtenze
        $this.ListaTargets = CheckTargets -ListaTargets $ListaTargets
        $this.TargetsArray = ($this.ListaTargets -split " ")
        $this.RemoteMachine = (($this.ListaTargets -split " ") -join ";")
    }
}

function InfoStandardAccount {
    param (
        $Infoforn,
        [string]$Suffix,
        [string]$StandardSafe
    )

    $Platform = checkPlatform -SO $InfoForn.SO -LocDom $InfoForn.LocDom -Suffix $Suffix
    Write-LogMessage -MSG "Platform '$Platform' rilevata " -Type Debug -LogFile $LOG_FILE_ACCOUNT

    $Safe = CheckStandardSafe -SafeName $StandardSafe
    Write-LogMessage -MSG "Safe '$Safe' rilevata" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    $Username = GetUsername -SO $InfoForn.SO -Alias $InfoForn.Alias -LocDom $InfoForn.LocDom -Suffix $Suffix

    $accountInfo = [AccountInfo]::new($Platform, $Safe, $Username)

    return $accountInfo
}

function InfoAccount {
    param (
        $Infoforn,
        [string]$Suffix
    )

    $Platform = checkPlatform -SO $InfoForn.SO -LocDom $InfoForn.LocDom -Suffix $Suffix
    Write-LogMessage -MSG "Platform '$Platform' rilevata " -Type Debug -LogFile $LOG_FILE_ACCOUNT

    $Safe = CheckSafe -fornitore $InfoForn.Fornitore -alias $InfoForn.alias -SO $InfoForn.SO -suffix $Suffix 
    Write-LogMessage -MSG "Safe '$Safe' rilevata" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    $Username = GetUsername -SO $InfoForn.SO -Alias $InfoForn.Alias -LocDom $InfoForn.LocDom -Suffix $Suffix

    $accountInfo = [AccountInfo]::new($Platform, $Safe, $Username)

    return $accountInfo
}

class AccountInfo {
    [string]$Platform
    [string]$Safe
    [string]$Username

    # Costruttore
    AccountInfo( [string]$platform, [string]$safe, [string]$username) {
        $this.Platform = $platform
        $this.Safe = $safe
        $this.Username = $username
    }
}
