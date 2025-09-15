[CmdletBinding()]
param()

# Verbose e Debug 
$global:InDebug = $PSBoundParameters.Debug.IsPresent
$global:InVerbose = $PSBoundParameters.Verbose.IsPresent

# Get Script Location 
$global:ScriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path

# Funzioni
. "$ScriptLocation\PS-Module\Utils.ps1"

# Funzione per mostrare il menu delle opzioni disponibili
Function Show-Menu{
    Clear-Host
    Write-Host "================ Guide ================"
    Write-Host "1: Premi '1' per creare le Safes" -ForegroundColor Green
    Write-Host "2: Premi '2' per onboardare gli Account" -ForegroundColor Green
    Write-Host "Q: Premi 'Q' per uscire."
}

function PS_Onboarding {
    # Inizializza la connessione con CyberArk
    try {
        $UserPassword = Read-Host "Inserisci la password dell'utente '$User'" -AsSecureStrin
        $cred = New-Object System.Management.Automation.PSCredential ($User, $UserPassword)
        Write-LogMessage -MSG "Tentativo di connessione al Tenant Cyberark..." -Type Info -LogFile $LOG_FILE_MAIN
        
        New-PASSession -TenantSubdomain $Tenant -Credential $Cred -IdentityUser
        Write-LogMessage -MSG "Connessione a CyberArk riuscita." -Type Success -LogFile $LOG_FILE_MAIN
    } catch {
        Write-LogMessage -MSG "Errore: Connessione a CyberArk fallita. $_" -Type Error -LogFile $LOG_FILE_MAIN
        exit 1
    }

    # Start the loop
    do {
        Show-Menu
        $selection = Read-Host "Scegli un'opzione"
        Write-LogMessage -MSG "Opzione selezionata: $selection" -Type Debug -LogFile $LOG_FILE_MAIN

        switch ($selection) {
            '1' {
                Write-LogMessage -MSG "Avvio creazione safes..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                AddSafes
                Write-LogMessage -MSG "Creazione safes terminato" -Type Info -LogFile $LOG_FILE_ACCOUNT
            } 
            '2' {
                Write-LogMessage -MSG "Avvio onboarding account..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                AddAccounts
                Write-LogMessage -MSG "Onboarding terminato" -Type Info -LogFile $LOG_FILE_ACCOUNT
            } 
            default {
                if (-not(($selection -eq 'q'))) {
                    Write-LogMessage -MSG "Opzione non valida selezionata: $selection" -Type Warning -LogFile $LOG_FILE_MAIN
                }
            }
        }
        pause
    }
    until ($selection -eq 'q')

    if (Get-PASSession) {
        Write-LogMessage -MSG "Chiusura della sessione CyberArk..." -Type Info -LogFile $LOG_FILE_MAIN
        Close-PASSession
        Write-LogMessage -MSG "Sessione CyberArk chiusa." -Type Success -LogFile $LOG_FILE_MAIN
    } else {
        Write-LogMessage -MSG "Nessuna sessione CyberArk attiva da chiudere." -Type Warning -LogFile $LOG_FILE_MAIN
    }

    exit
}

PS_Onboarding
