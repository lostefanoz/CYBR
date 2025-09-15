
function SafeWinDom {
    param ($InfoSafe)

    Write-LogMessage -MSG "Inizio verifica Safes..." -Type Info -LogFile $LOG_FILE_SAFE

    $SafeEME = CheckStandardSafe -SafeName $SafeWinEme
    Write-LogMessage -MSG "Safe '$SafeEME' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeDU = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Domain 
    Write-LogMessage -MSG "Safe '$SafeDU' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_SAFE
}

function SafeWinLocal {
    param ($InfoSafe)

    Write-LogMessage -MSG "Inizio verifica Safes..." -Type Info -LogFile $LOG_FILE_SAFE

    $SafeRecon = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Recon 
    Write-LogMessage -MSG "Safe '$SafeRecon' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeEME = CheckStandardSafe -SafeName $SafeWinEme
    Write-LogMessage -MSG "Safe '$SafeEME' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeLA = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Local 
    Write-LogMessage -MSG "Safe '$SafeLA' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_SAFE

}

function SafeUnixDom {
    param ($InfoSafe)

    Write-LogMessage -MSG "Inizio verifica Safes..." -Type Info -LogFile $LOG_FILE_SAFE

    $SafeEME = CheckStandardSafe -SafeName $SafeNixEmeDom
    Write-LogMessage -MSG "Safe '$SafeEME' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeDU = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Domain 
    Write-LogMessage -MSG "Safe '$SafeDU' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeADM = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Admin
    Write-LogMessage -MSG "Safe '$SafeADM' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_SAFE
}

function SafeUnixLocal {
    param ($InfoSafe)

    Write-LogMessage -MSG "Inizio verifica Safes..." -Type Info -LogFile $LOG_FILE_SAFE

    $SafeRecon = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Recon 
    Write-LogMessage -MSG "Safe '$SafeRecon' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeEME = CheckStandardSafe -SafeName $SafeNixEmeLoc
    Write-LogMessage -MSG "Safe '$SafeEME' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeLA = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Local 
    Write-LogMessage -MSG "Safe '$SafeLA' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    $SafeADM = CheckSafe -fornitore $InfoSafe.Fornitore -alias $InfoSafe.alias -SO $InfoSafe.SO -suffix $Admin 
    Write-LogMessage -MSG "Safe '$SafeADM' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_SAFE

}


function AddSafes {
    $SafeData = importCSV

    CheckStandardSafe -SafeName $SafeReconDom
    Write-LogMessage -MSG "Safe '$SafeReconDom' rilevata" -Type Debug -LogFile $LOG_FILE_SAFE
    $AccettaTuttiSafe = $false

    foreach ($row in $SafeData) {
        # Creare un'istanza della classe FornitoreInfo 
        Write-LogMessage -MSG "Elaborazione dei dati per fornitore '$($row.Fornitore)'" -Type Info -LogFile $LOG_FILE_SAFE

        $InfoSafe = [FornitoreInfo]::new(
            $row.Fornitore,
            $row.Alias,
            $row.SistemaOperativo,
            $row.LocaleDominio,
            [int]$row.NumeroUtenze,
            $row.ListaTargets
        )

        # Verifica se almeno un campo contiene un valore non valido
        if ($InfoSafe.Fornitore -eq $NoName -or 
            $InfoSafe.Alias -eq $NoName -or 
            $InfoSafe.SO -eq $NoName -or 
            $InfoSafe.LocDom -eq $NoName -or 
            $InfoSafe.NroUtenze -eq -1 -or 
            $InfoSafe.ListaTargets -eq $NoName) {

            # Costruisci un messaggio dettagliato con tutti i valori
            $dettagliInfo = "Errore: Uno o piu' valori non validi trovati per il fornitore '$($row.Fornitore)'." + 
                "`nDettagli:" +
                "`n- Fornitore: $($InfoSafe.Fornitore)" +
                "`n- Alias: $($InfoSafe.Alias)" +
                "`n- Sistema Operativo: $($InfoSafe.SO)" +
                "`n- LocDom: $($InfoSafe.LocDom)" +
                "`n- Numero Utenze: $($InfoSafe.NroUtenze)" +
                "`n- Lista Targets: $($InfoSafe.ListaTargets)"

            Write-Host "`n$dettagliInfo`n" -ForegroundColor Red
            continue
        }   

        $AccountType = $InfoSafe.SO + "-" + $InfoSafe.LocDom
        
        $dettagliInfo = "Dati Fornitore: $($InfoSafe.Fornitore)" +
                "`n-----------------------------------"+
                "`n- Nome fornitore: $($InfoSafe.Fornitore)" +
                "`n- Alias: $($InfoSafe.Alias)" +
                "`n- Sistema Operativo: $($InfoSafe.SO)" +
                "`n- Tipologia: $($InfoSafe.LocDom)" +
                "`n- Numero Utenze: $($InfoSafe.NroUtenze)" +
                "`n- Lista Targets: $(($InfoSafe.ListaTargets -split " ") -join ", ")"

        Write-Host "`n$dettagliInfo`n"

        # Richiedere conferma all'utente
        if (-not $AccettaTuttiSafe) {
            do {
                $risposta = Read-Host "Vuoi inizializzare la creazione safe per questo fornitore? (Y=Yes, N=No, A=Accept All)"
            } while ($risposta -notmatch "^[YNA]$")
        
            if ($risposta -eq "N") {
                Write-LogMessage -MSG "Creazione safe saltata per fornitore '$($row.Fornitore)'." -Type Warning -LogFile $LOG_FILE_SAFE
                continue
            }
            
            if ($risposta -eq "A") {
                $AccettaTuttiSafe = $true
            }
        }

        switch ($AccountType) {
            'WIN-DOM' {
                Write-LogMessage -MSG "Creazione safe Windows di dominio per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_SAFE
                SafeWinDom -InfoSafe $InfoSafe
            }
            'WIN-LOCAL' {
                Write-LogMessage -MSG "Creazione safe Windows locale per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_SAFE
                SafeWinLocal -InfoSafe $InfoSafe
            }
            'NIX-DOM' {
                Write-LogMessage -MSG "Creazione safe Unix di dominio per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_SAFE
                SafeUnixDom -InfoSafe $InfoSafe
            }
            'NIX-LOCAL' {
                Write-LogMessage -MSG "Creazione safe Unix locale per fornitore '$($row.Fornitore)'..." -Type Info -LogFile $LOG_FILE_SAFE
                SafeUnixLocal -InfoSafe $InfoSafe
            }
            default {
                Write-LogMessage -MSG "Errore: Tipo di account sconosciuto ($AccountType) per fornitore '$($row.Fornitore)'." -Type Error -LogFile $LOG_FILE_SAFE
            }
        }
        Start-Sleep -Seconds 1 # Waits for 1 seconds
    }
    $AccettaTuttiSafe = $false
}
