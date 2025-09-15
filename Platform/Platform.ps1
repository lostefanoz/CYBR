# Funzione che crea la platform se assente
function createPlatform {
    param (
        [string]$PlatformName
    )

    $SourcePlatformID = $MapPlatform[$PlatformName]

    try {
        Write-LogMessage -MSG "Inizio creazione platform '$PlatformName'" -Type Debug -LogFile $LOG_FILE_PLATFORM
        $Platform = Copy-PASPlatform -TargetPlatform -ID $sourcePlatformID -name $PlatformName -Description ""
        if ($Platform) {
            Write-LogMessage -MSG "Platform '$PlatformName' creata con successo." -Type Success -LogFile $LOG_FILE_PLATFORM
            Enable-PASPlatform -TargetPlatform -ID $Platform.Details.ID
            Write-LogMessage -MSG "Platform '$PlatformName' abilitata con successo." -Type Debug -LogFile $LOG_FILE_PLATFORM
        } else {
            Write-LogMessage -MSG "Errore nella creazione della platform '$PlatformName'." -Type Error -LogFile $LOG_FILE_PLATFORM
        }
    }
    catch {
        Write-LogMessage -MSG "'$PlatformName' gia' esistente" -Type Debug -LogFile $LOG_FILE_PLATFORM 
    }
}

# Funzione che genera il nome della platform ed effettua un check sulla sua esistenza
function checkPlatform {

    param (
        [string]$SO,
        [string]$LocDom,
        [string]$Suffix  
    )

    Write-LogMessage -MSG "Avvio verifica piattaforma con SO: '$SO', LocDom: '$LocDom', Suffix: '$Suffix'" -Type Debug -LogFile $LOG_FILE_PLATFORM

    $platform = platformName -SO $SO -LocDom $LocDom -Suffix $Suffix

    Write-LogMessage -MSG "Piattaforma '$platform' generata" -Type Verbose -LogFile $LOG_FILE_PLATFORM

    createPlatform -PlatformName $platform

    Write-LogMessage -MSG "Check completato per la piattaforma '$platform'" -Type Debug -LogFile $LOG_FILE_PLATFORM

    return $platform
}
