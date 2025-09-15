function AppendSafeToCsv {
    param (
        [string]$SafeName,
        [string]$Descrizione
    )

    # Rinomina il campo per allinearlo con l'intestazione personalizzata
    $newRow = [PSCustomObject]@{
        gruppoAD    = $SafeName
        Descrizione = $Descrizione
    }

    if (-not (Test-Path $CSV_ADGROUP)) {
        # Crea il file scrivendo intestazione e prima riga in un solo blocco
        Write-LogMessage -MSG "Il file CSV non esiste. Creazione in corso: '$CSV_ADGROUP'" -Type Debug -LogFile $LOG_FILE_SAFE

        # Converti l'oggetto in CSV (con intestazione) e scrivi tutto in una volta
        $newRow | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $CSV_ADGROUP -Encoding UTF8

        Write-LogMessage -MSG "Safe '$SafeName' aggiunta al nuovo file CSV con descrizione: '$Descrizione'" -Type Debug -LogFile $LOG_FILE_SAFE
        return
    }

    # Controlla duplicati
    $csvContent = Import-Csv -Path $CSV_ADGROUP
    $existing = $csvContent | Where-Object { $_.gruppoAD -eq $SafeName }

    if ($existing) {
        Write-LogMessage -MSG "La safe '$SafeName' è già presente nel file CSV. Nessun inserimento effettuato." -Type Verbose -LogFile $LOG_FILE_SAFE
        return
    }

    # Append normale (senza intestazione)
    $newRow | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -FilePath $CSV_ADGROUP -Append -Encoding UTF8
    Write-LogMessage -MSG "Safe '$SafeName' aggiunta al file CSV con descrizione: '$Descrizione'" -Type Debug -LogFile $LOG_FILE_SAFE
}

function AddADGroupInSafe {
    param ([string]$Name, [string]$ADGroup)

    if (-not $Name -or -not $ADGroup) {
        Write-LogMessage -MSG "Nome o gruppo AD non specificato" -Type Debug -LogFile $LOG_FILE_SAFE
        return 
    }

    $ExistingMembers = Get-PASSafeMember -SafeName $Name | Select-Object -ExpandProperty MemberName

    if ($ExistingMembers -contains $ADGroup) { 
        Write-LogMessage -MSG "Il gruppo AD '$ADGroup' e' gia' presente nella safe '$Name'" -Type Debug -LogFile $LOG_FILE_SAFE
        return 
    }
    
    try {
        $Source = "Active Directory: $Dominio"
        $UserExists = Get-PASUser -Search $ADGroup -ErrorAction SilentlyContinue 
        
        if (-not $UserExists) { 
            Write-LogMessage -MSG "Il gruppo AD '$ADGroup' non esiste" -Type Debug -LogFile $LOG_FILE_SAFE
            return 
        }

        $ConnectOnlyRole | Add-PASSafeMember -SafeName $Name -MemberName $ADGroup -MemberType Group -SearchIn $Source | Out-Null
        Write-LogMessage -MSG "Gruppo AD '$ADGroup' aggiunto con successo alla safe '$Name'" -Type Success -LogFile $LOG_FILE_SAFE
 
    } catch {
        Write-LogMessage -MSG "Errore durante l'aggiunta del gruppo AD '$ADGroup' alla safe '$Name'. $_" -Type Error -LogFile $LOG_FILE_SAFE
    }
}

function RemoveMemberInSafe {
    param ([string]$Name)

    if (-not $Name) {
        Write-LogMessage -MSG "Nome della safe non specificato" -Type Error -LogFile $LOG_FILE_SAFE
        return 
    }

    $CurrentUser = (Get-PASSession).User

    $ExistingMembers = Get-PASSafeMember -SafeName $Name | Select-Object -ExpandProperty MemberName

    if ($ExistingMembers -notcontains  $CurrentUser) { 
        Write-LogMessage -MSG "L'utente '$CurrentUser' non e' un membro della safe '$Name'" -Type Debug -LogFile $LOG_FILE_SAFE
        return 
    }

    try {
        Write-LogMessage -MSG "Utente '$CurrentUser' rimosso dalla safe '$Name'" -Type Success -LogFile $LOG_FILE_SAFE
        Remove-PASSafeMember -SafeName $Name -MemberName $CurrentUser  | Out-Null
    } catch {
        Write-LogMessage -MSG "Errore durante la rimozione dell'utente '$CurrentUser' dalla safe '$Name'" -Type Error -LogFile $LOG_FILE_SAFE
    }
}


function AddCloudAdminInSafe {
    param ( [string]$name )
    
    $Member = "Privilege Cloud Administrators"

    if (-not $name) { 
        Write-LogMessage -MSG "Nome safe non specificato" -Type Error -LogFile $LOG_FILE_SAFE
        return 
    }

    $ExistingMembers = Get-PASSafeMember -SafeName $Name | Select-Object -ExpandProperty MemberName

    if ($ExistingMembers -contains $Member) { 
        Write-LogMessage -MSG "Il ruolo '$Member' e' gia' presente nella safe '$Name'" -Type Debug -LogFile $LOG_FILE_SAFE
        return 
    }

    try {
        $FullRole | Add-PASSafeMember -SafeName $Name -MemberName $Member -MemberType Role | Out-Null
        Write-LogMessage -MSG "Ruolo '$Member' aggiunto con successo alla safe '$Name'" -Type Success -LogFile $LOG_FILE_SAFE
    } catch {
        Write-LogMessage -MSG "Errore durante l'aggiunta del ruolo '$Member' alla safe '$Name'. $_" -Type Error -LogFile $LOG_FILE_SAFE
    }
}

function CreateSafe {
    param([string]$name, [string]$description)

    if (-not $name) { 
        Write-LogMessage -MSG "Nome della safe non specificato" -Type Error -LogFile $LOG_FILE_SAFE
        return 
    }
    try {

        Add-PASSafe -SafeName $name -Description $description -ManagingCPM $CPM -NumberOfVersionsRetention 7 | Out-Null

        Write-LogMessage -MSG "Safe '$name' creata con successo" -Type Success -LogFile $LOG_FILE_SAFE
        
    } catch { 
        Write-LogMessage -MSG "Errore nella creazione della safe '$name'" -Type Error -LogFile $LOG_FILE_SAFE
    }
}

function CheckStandardSafe {

    param ( [string]$SafeName )

    if (-not(Get-PASSafe -SafeName $SafeName -ErrorAction SilentlyContinue)){

        $description = $MapSafes[$SafeName]
        Write-LogMessage -MSG "La safe '$SafeName' non esiste, creazione in corso..." -Type Debug -LogFile $LOG_FILE_SAFE
        CreateSafe -name $SafeName -description $description

    }

    $SafeExists = Get-PASSafe -SafeName $SafeName -ErrorAction SilentlyContinue

    if (-not $SafeExists) {
        Write-LogMessage -MSG "La safe '$SafeName' non e' stata trovata" -Type Error -LogFile $LOG_FILE_SAFE
        Write-LogMessage -MSG "La safe viene impostata a $NoName per informazioni non corrette" -Type Verbose -LogFile $LOG_FILE_SAFE
        return $NoName
    }

    Write-LogMessage -MSG "Aggiunta del ruolo Privilege Cloud Administrators come membro dalla safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    AddCloudAdminInSafe -name $SafeName
    Write-LogMessage -MSG "Rimozione dell'utente corrente dai membri dalla safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    RemoveMemberInSafe -name $SafeName
    Write-LogMessage -MSG "Verifica completata per la safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    return $SafeName
}


function CheckSafe {
    
    param (
        [string]$fornitore,
        [string]$alias,
        [string]$SO,
        [string]$suffix
    )

    Write-LogMessage -MSG "Generazione safe con Fornitore: '$fornitore', Alias: '$Alias', Sistema operativo: '$SO', Suffisso: '$Suffix'" -Type Debug -LogFile $LOG_FILE_SAFE

    $safeInfo = [SafeInfo]::new($fornitore, $alias, $SO, $suffix)
    $safeName = $safeInfo.GenerateSafeName()

    Write-LogMessage -MSG "Nome safe generato '$safeName'" -Type Verbose -LogFile $LOG_FILE_SAFE

    if (-not(Get-PASSafe -SafeName $SafeName -ErrorAction SilentlyContinue)){
        Write-LogMessage -MSG "La safe '$SafeName' non esiste, creazione in corso..." -Type Info -LogFile $LOG_FILE_SAFE
        CreateSafe -name $SafeName -description $safeInfo.descrizione
    }

    $SafeExists = Get-PASSafe -SafeName $SafeName -ErrorAction SilentlyContinue

    if (-not $SafeExists) {
        Write-LogMessage -MSG "La safe '$SafeName' non e' stata trovata" -Type Error -LogFile $LOG_FILE_SAFE
        Write-LogMessage -MSG "La safe viene impostata a $NoName per informazioni non corrette" -Type Verbose -LogFile $LOG_FILE_SAFE
        return $NoName
    }

    Write-LogMessage -MSG "Aggiunta del ruolo Privilege Cloud Administrators come membro dalla safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    AddCloudAdminInSafe -name $SafeName

    if (-not ($suffix -match $Recon)) { 
        Write-LogMessage -MSG "Aggiunta del gruppo AD alla safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
        AddADGroupInSafe -name $SafeName -ADGroup $SafeName
        AppendSafeToCsv -SafeName $SafeName -Descrizione $safeInfo.Descrizione
    }
    Write-LogMessage -MSG "Rimozione dell'utente corrente dai membri dalla safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    RemoveMemberInSafe -name $SafeName
    Write-LogMessage -MSG "Verifica completata per la safe '$SafeName'" -Type Debug -LogFile $LOG_FILE_SAFE
    return $SafeName
}
