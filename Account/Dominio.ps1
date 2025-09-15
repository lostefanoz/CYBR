
function DomAccount {
    param ( 
        $InfoForn,
        $Username,
        $InfoAccount
    )
    # CHECK ESISTENZA
    if (-not (Get-PASAccount -search $Username -safeName $InfoAccount.Safe -ErrorAction SilentlyContinue)) { 
        $Params = @{
            SafeName         = $InfoAccount.Safe
            platformID       = $InfoAccount.Platform
            address          = $Dominio
            userName         = $Username
            automaticManagementEnabled = $true
            platformAccountProperties = @{ 'LogonDomain'= $Dominio }
            remoteMachines = $InfoForn.RemoteMachine
            accessRestrictedToRemoteMachines = $true
        }

        Write-LogMessage -MSG "Creazione account con seguenti caratteristiche: Username: '$Username'; Safe: '$($InfoAccount.Safe)'; Platform: '$($InfoAccount.Platform)'; Address: '$Dominio'; remoteMachines: '$($InfoForn.ListaTargets)'; LogonDomain: '$Dominio'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
        try {
            $Account = Add-PASAccount @Params 
            Write-LogMessage -MSG "Account '$Username' creato con successo" -Type Success -LogFile $LOG_FILE_ACCOUNT
            AppendUser -Fornitore $InfoForn.Fornitore -Utenza $Username
            return $Account

        } catch {
            Write-LogMessage -MSG "Errore nella creazione dell'account '$Username': $_" -Type Error -LogFile $LOG_FILE_ACCOUNT
            return $false
        }
    }
}

function WinDomRecon {

    Write-LogMessage -MSG "Inizio creazione account '$UsernameRecon'" -Type Info -LogFile $LOG_FILE_ACCOUNT

    # CHECK PLATFORM
    $Platform = checkPlatform -PlatformName -SO $Windows -LocDom "DOM" -Suffix $Recon
    Write-LogMessage -MSG "Platform '$Platform' rilevata " -Type Debug -LogFile $LOG_FILE_ACCOUNT

    # CHECK SAFE
    CheckStandardSafe -SafeName $SafeReconDom
    Write-LogMessage -MSG "Safe '$SafeReconDom' rilevata" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    # CHECK ESISTENZA
    if (Get-PASAccount -search $UsernameRecon -safeName $SafeReconDom -ErrorAction SilentlyContinue) { 
        Write-LogMessage -MSG "L'account '$UsernameRecon' esiste gia'" -Type Warning -LogFile $LOG_FILE_ACCOUNT
        return
    }

    $accountParams = @{
        SafeName         = $SafeReconDom
        platformID       = $Platform
        address          = $Dominio
        userName         = $UsernameRecon 
        automaticManagementEnabled = $true
        platformAccountProperties = @{ 'LogonDomain'= $Dominio }
    }

    Write-LogMessage -MSG "Creazione account con seguenti caratteristiche: Username: '$UsernameRecon'; Safe: '$SafeReconDom'; Platform: '$Platform'; Address: '$Dominio'; LogonDomain: '$Dominio'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT
    
    try {
        Add-PASAccount @accountParams | Out-Null
        Write-LogMessage -MSG "Account '$UsernameRecon' creato con successo" -Type Success -LogFile $LOG_FILE_ACCOUNT
    } catch {
        Write-LogMessage -MSG "Errore nella creazione dell'account '$UsernameRecon': $_" -Type Error -LogFile $LOG_FILE_ACCOUNT
    }
}

function DomEME {
    param ( 
        $InfoForn,
        [string]$Safe
    )

    $InfoEME = InfoStandardAccount -InfoForn $InfoForn -Suffix $Emergenza -StandardSafe $Safe

    Write-LogMessage -MSG "Username '$($InfoEME.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    $AccountEME = DomAccount -InfoForn $InfoForn -Username $($InfoEME.Username) -InfoAccount $InfoEME

    if ($AccountEME) {
        $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1
        LinkAccount -account $AccountEME -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $InfoEME.Username
    }
}

function WinDom {
    param ($InfoForn)

    Write-LogMessage -MSG "Inizio verifica Platform e Safes..." -Type Info -LogFile $LOG_FILE_ACCOUNT

    $InfoDU = InfoAccount -InfoForn $InfoForn -Suffix $Domain

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_ACCOUNT

    DomEME -InfoForn $InfoForn -Safe $SafeWinEme

    for ($x = 1; $x -le $InfoForn.NroUtenze; $x++) {
        
        $suff = "{0:D2}" -f $x
        $UsernameDU = $InfoDU.Username + "-" + $suff

        Write-LogMessage -MSG "Username '$Username' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

        $Account = DomAccount -InfoForn $InfoForn -Username $UsernameDU -InfoAccount $InfoDU

        if ($Account) {
            $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1
            LinkAccount -account $Account -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $UsernameDU
        }
    }
}

function UnixDom {
    param ($InfoForn)

    Write-LogMessage -MSG "Inizio verifica Platform e Safes..." -Type Info -LogFile $LOG_FILE_ACCOUNT

    # DU
    $InfoDU = InfoAccount -InfoForn $InfoForn -Suffix $Domain

    # ADM
    $InfoADM = InfoAccount -InfoForn $InfoForn -Suffix $Admin

    # ROOT 
    # $InfoROOT = InfoStandardAccount -InfoForn $InfoForn -Suffix $Root -StandardSafe $SafeROOT
    # Write-LogMessage -MSG "Username '$($InfoROOT.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_ACCOUNT

    DomEME -InfoForn $InfoForn -Safe $SafeNixEmeDom

    # if (-not (Get-PASAccount -search $InfoROOT.Username -safeName $InfoROOT.Safe -ErrorAction SilentlyContinue)) {
    #     $ParamsROOT = @{
    #         SafeName         = $InfoROOT.Safe
    #         platformID       = $InfoROOT.Platform
    #         address          = $Dominio
    #         userName         = $InfoROOT.Username
    #         automaticManagementEnabled = $true
    #         platformAccountProperties = @{ 'LogonDomain'= $Dominio }
    #     }

    #     Write-LogMessage -MSG "Creazione account con seguenti caratteristiche: Username: '$($InfoROOT.Username)'; Safe: '$($InfoROOT.Safe)'; Platform: '$($InfoROOT.Platform)'; Address: '$Dominio'; LogonDomain: '$Dominio'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT

    #     try {
    #         Add-PASAccount @ParamsROOT | Out-Null
    #         Write-LogMessage -MSG "Account '$($InfoROOT.Username)' creato con successo" -Type Success -LogFile $LOG_FILE_ACCOUNT
    #     } catch {
    #         Write-LogMessage -MSG "Errore nella creazione dell'account '$($InfoROOT.Username)': $_" -Type Error -LogFile $LOG_FILE_ACCOUNT
    #     }
    # }
    
    $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1

    for ($x = 1; $x -le $InfoForn.NroUtenze; $x++) {
        
        $suff = "{0:D2}" -f $x
        $UsernameDU = $InfoDU.Username + "-" + $suff

        Write-LogMessage -MSG "Username '$UsernameDU' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

        $AccountDU = DomAccount -InfoForn $InfoForn -Username $UsernameDU -InfoAccount $InfoDU

        if ($AccountDU) {
            LinkAccount -account $AccountDU -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $UsernameDU
        }
        
        $UsernameADM = $InfoADM.Username + "-" + $suff
        Write-LogMessage -MSG "Username '$UsernameADM' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

        $AccountADM = DomAccount -InfoForn $InfoForn -Username $UsernameADM -InfoAccount $InfoADM

        if ($AccountADM) {
            $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1
            LinkAccount -account $AccountADM -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $UsernameADM
            $AccountDU = Get-PASAccount -Search $UsernameDU -safeName $InfoDU.Safe | Select-Object -First 1
            if ($AccountDU) {
                LinkAccount -account $AccountADM -linkedAccount $AccountDU -type 1 -UsernameLink $UsernameDU -UsernameLinked $UsernameADM
            }
        }
    }
}
