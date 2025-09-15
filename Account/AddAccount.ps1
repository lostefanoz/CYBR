$global:AccettaTutti = $false
function importCSV {

    $CSV_FILE_PATH = "$ScriptLocation\accounts.csv"

    # Controllo se il file CSV esiste
    if (-not (Test-Path $CSV_FILE_PATH)) {
        Write-LogMessage -MSG "Errore: Il file CSV non esiste nel percorso specificato." -Type Error -LogFile $LOG_FILE_ACCOUNT
        exit 1
    }

    Write-LogMessage -MSG "Importazione del file CSV..." -Type Info -LogFile $LOG_FILE_ACCOUNT
    $AccountData = Import-Csv -Path $CSV_FILE_PATH -Delimiter ','

    # Controllo colonne richieste
    $requiredColumns = @("Fornitore", "Alias", "SistemaOperativo","LocaleDominio","NumeroUtenze","ListaTargets")
    $csvColumns = ($AccountData | Get-Member -MemberType NoteProperty).Name

    foreach ($col in $requiredColumns) {
        if ($col -notin $csvColumns) {
            Write-LogMessage -MSG "Errore: Il file CSV manca della colonna $col." -Type Error -LogFile $LOG_FILE_ACCOUNT
            exit 1
        } 
    }
    Write-LogMessage -MSG "File CSV importato correttamente." -Type Success -LogFile $LOG_FILE_ACCOUNT
    return $AccountData
}

function AddAccounts {
    # import csv
    $AccountData = importCSV

    LoadUsersCsv

    # Check Recon Dominio
    Write-LogMessage -MSG "Verifico o creo l'utenza usr-pam-recon di dominio..." -Type Debug -LogFile $LOG_FILE_ACCOUNT
    WinDomRecon

    foreach ($row in $AccountData) {
        # Creare un'istanza della classe FornitoreInfo 
        Write-LogMessage -MSG "Elaborazione degli account per fornitore '$($row.Fornitore)'" -Type Info -LogFile $LOG_FILE_ACCOUNT

        $InfoForn = [FornitoreInfo]::new(
            $row.Fornitore,
            $row.Alias,
            $row.SistemaOperativo,
            $row.LocaleDominio,
            [int]$row.NumeroUtenze,
            $row.ListaTargets
        )

        # Verifica se almeno un campo contiene un valore non valido
        if ($InfoForn.Fornitore -eq $NoName -or 
            $InfoForn.Alias -eq $NoName -or 
            $InfoForn.SO -eq $NoName -or 
            $InfoForn.LocDom -eq $NoName -or 
            $InfoForn.NroUtenze -eq -1 -or 
            $InfoForn.ListaTargets -eq $NoName) {

            # Costruisci un messaggio dettagliato con tutti i valori
            $dettagliInfo = "Errore: Uno o piu' valori non validi trovati per il fornitore '$($row.Fornitore)'." + 
                "`nDettagli:" +
                "`n- Fornitore: $($InfoForn.Fornitore)" +
                "`n- Alias: $($InfoForn.Alias)" +
                "`n- Sistema Operativo: $($InfoForn.SO)" +
                "`n- LocDom: $($InfoForn.LocDom)" +
                "`n- Numero Utenze: $($InfoForn.NroUtenze)" +
                "`n- Lista Targets: $($InfoForn.ListaTargets)"

            Write-Host "`n$dettagliInfo`n" -ForegroundColor Red
            continue
        }   

        $AccountType = $InfoForn.SO + "-" + $InfoForn.LocDom
        
        $dettagliInfo = "Onboarding Fornitore: $($InfoForn.Fornitore)" +
                "`n-----------------------------------"+
                "`n- Nome fornitore: $($InfoForn.Fornitore)" +
                "`n- Alias: $($InfoForn.Alias)" +
                "`n- Sistema Operativo: $($InfoForn.SO)" +
                "`n- Tipologia: $($InfoForn.LocDom)" +
                "`n- Numero Utenze: $($InfoForn.NroUtenze)" +
                "`n- Lista Targets: $(($InfoForn.ListaTargets -split " ") -join ", ")"

        Write-Host "`n$dettagliInfo`n"

        # Richiedere conferma all'utente
        if (-not $global:AccettaTutti) {
            do {
                $risposta = Read-Host "Vuoi inizializzare l'onboarding per questo fornitore? (Y=Yes, N=No, A=Accept All)"
            } while ($risposta -notmatch "^[YNA]$")
        
            if ($risposta -eq "N") {
                Write-LogMessage -MSG "Onboarding saltato per fornitore '$($row.Fornitore)'." -Type Warning -LogFile $LOG_FILE_ACCOUNT
                continue
            }
            
            if ($risposta -eq "A") {
                $global:AccettaTutti = $true
            }
        }

        switch ($AccountType) {
            'WIN-DOM' {
                Write-LogMessage -MSG "Creazione account Windows di dominio per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                WinDom -InfoForn $InfoForn
            }
            'WIN-LOCAL' {
                Write-LogMessage -MSG "Creazione account Windows locale per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                WinLocal -InfoForn $InfoForn
            }
            'NIX-DOM' {
                Write-LogMessage -MSG "Creazione account Unix di dominio per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                UnixDom -InfoForn $InfoForn
            }
            'NIX-LOCAL' {
                Write-LogMessage -MSG "Creazione account Unix locale per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_ACCOUNT
                UnixLocal -InfoForn $InfoForn
            }
            default {
                Write-LogMessage -MSG "Errore: Tipo di account sconosciuto ($AccountType) per fornitore '$($row.Fornitore)'." -Type Error -LogFile $LOG_FILE_ACCOUNT
            }
        }
        Start-Sleep -Seconds 1 # Waits for 1 seconds
    }
    SaveUsersCSV
    $global:AccettaTutti = $false
}
