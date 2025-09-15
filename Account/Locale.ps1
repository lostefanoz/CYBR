function WinLocalAccount {
    param (
        $InfoForn, 
        $Username,
        $InfoAccount,
        $target
    )
    if (-not (Get-PASAccount -search $Username -safeName $InfoAccount.Safe -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target })) {
        $Params = @{
            SafeName         = $InfoAccount.Safe
            platformID       = $InfoAccount.Platform
            address          = $target
            userName         = $Username
            automaticManagementEnabled = $true
            platformAccountProperties = @{ 'LogonDomain'= $target }
        }
        Write-LogMessage -MSG "Creazione account con seguenti caratteristiche: Username: '$Username'; Safe: '$($InfoAccount.Safe)'; Platform: '$($InfoAccount.Platform)'; Address: '$target'; LogonDomain: '$target'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT

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

function NixLocalAccount {
    param ( 
        $InfoForn,
        $Username,
        $InfoAccount,
        $target
    )
    if (-not (Get-PASAccount -search $Username -safeName $InfoAccount.Safe -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target })) {
        $Params = @{
            SafeName         = $InfoAccount.Safe
            platformID       = $InfoAccount.Platform
            address          = $target
            userName         = $Username
            automaticManagementEnabled = $true
            platformAccountProperties = @{ 'UseSudoOnReconcile'= "Yes" }
        }
        Write-LogMessage -MSG "Creazione account con seguenti caratteristiche: Username: '$Username'; Safe: '$($InfoAccount.Safe)'; Platform: '$($InfoAccount.Platform)'; Address: '$target'; LogonDomain: '$target'" -Type Verbose -LogFile $LOG_FILE_ACCOUNT

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

function WinLocal {
    param ( $InfoForn )

    Write-LogMessage -MSG "Inizio verifica Platform e Safes..." -Type Info -LogFile $LOG_FILE_ACCOUNT
   
    Write-LogMessage -MSG "Username '$($InfoRECON.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    # Locale
    $InfoLA = InfoAccount -InfoForn $InfoForn -Suffix $Local
    
    # emergenza locale
    $InfoEME = InfoStandardAccount -InfoForn $InfoForn -Suffix $Emergenza -StandardSafe $SafeWinEme

    Write-LogMessage -MSG "Username '$($InfoEME.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_ACCOUNT
    
    foreach ($target in $InfoForn.TargetsArray) {
        if ($target -eq "") {continue}

        $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1

        $AccountEME = WinLocalAccount -InfoForn $InfoForn -Username $InfoEME.Username -InfoAccount $InfoEME -target $target

        if ($AccountEME) {
            $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1
            if ($AccountRecon){
                LinkAccount -account $AccountEME -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $InfoEME.Username
            }
        }

        for ($x = 1; $x -le $InfoForn.NroUtenze; $x++) {

            $suff = "{0:D2}" -f $x
            $UsernameLA = $InfoLA.Username + "-" + $suff

            $AccountLA = WinLocalAccount -InfoForn $InfoForn -Username $UsernameLA -InfoAccount $InfoLA -target $target
            if ($AccountLA) {
                $AccountRecon = Get-PASAccount -Search $UsernameRecon -safeName $SafeReconDom | Select-Object -First 1
                if ($AccountRecon){
                    LinkAccount -account $AccountLA -linkedAccount $AccountRecon -type 3 -UsernameLink $UsernameRecon -UsernameLinked $UsernameLA
                }
            }
        }
    }
}

function UnixLocal {
    param ( $InfoForn )

    Write-LogMessage -MSG "Inizio verifica Platform e Safes..." -Type Info -LogFile $LOG_FILE_ACCOUNT

    # Recon Locale
    $InfoRECON = InfoAccount -InfoForn $InfoForn -Suffix $Recon

    # Locale
    $InfoLA = InfoAccount -InfoForn $InfoForn -Suffix $Local

    # Locale ADM
    $InfoADM = InfoAccount -InfoForn $InfoForn -Suffix $Admin
    
    # emergenza locale
    $InfoEME = InfoStandardAccount -InfoForn $InfoForn -Suffix $Emergenza -StandardSafe $SafeNixEmeLoc
    Write-LogMessage -MSG "Username '$($InfoEME.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

    # ROOT locale
    # $InfoROOT = InfoStandardAccount -InfoForn $InfoForn -Suffix $Root -StandardSafe $SafeROOT
    # Write-LogMessage -MSG "Username '$($InfoROOT.Username)' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT
    
    Write-LogMessage -MSG "Verifica terminata" -Type Info -LogFile $LOG_FILE_ACCOUNT

    foreach ($target in $InfoForn.TargetsArray) {
        if ($target -eq "") {continue}

        # $AccountROOT = NixLocalAccount -InfoForn $InfoForn -Username $InfoROOT.Username -InfoAccount $InfoROOT -target $target
        $AccountRecon = Get-PASAccount -search $InfoRECON.Username -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target -and $_.userName -eq $InfoRECON.Username } |  Select-Object -First 1
        if (-not $AccountRecon) {
            $AccountRecon = NixLocalAccount -InfoForn $InfoForn -Username $InfoRECON.Username -InfoAccount $InfoRECON -target $target
        } else {
            Write-LogMessage -MSG "Per il target NIX-LOCAL: '$target' e' stata utilizzata un utenza '$($InfoRECON.Username)' gia' esistente con Safe: '$($AccountRecon.safeName)'" -Type Info -LogFile $LOG_FILE_PLATFORM 
        }

        $AccountEME = NixLocalAccount -InfoForn $InfoForn -Username $InfoEME.Username -InfoAccount $InfoEME -target $target

        if ($AccountEME) {
            if (-not $AccountRecon) { 
                $AccountRecon = Get-PASAccount -search $InfoRECON.Username -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target -and $_.userName -eq $InfoRECON.Username } | Select-Object -First 1
            }
            LinkAccount -account $AccountEME -linkedAccount $AccountRecon -type 3 -UsernameLink $InfoRECON.Username -UsernameLinked $InfoEME.Username
        }

        for ($x = 1; $x -le $InfoForn.NroUtenze; $x++) {
            $suff = "{0:D2}" -f $x

            $UsernameLA = $InfoLA.Username + "-" + $suff
            Write-LogMessage -MSG "Username '$UsernameLA' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT

            $UsernameADM = $InfoADM.Username + "-" + $suff
            Write-LogMessage -MSG "Username '$UsernameADM' generato" -Type Debug -LogFile $LOG_FILE_ACCOUNT
            
            $AccountLA = NixLocalAccount -InfoForn $InfoForn -Username $UsernameLA -InfoAccount $InfoLA -target $target

            if ($AccountLA) {
                if (-not $AccountRecon) { 
                    $AccountRecon = Get-PASAccount -search $InfoRECON.Username -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target -and $_.userName -eq $InfoRECON.Username } | Select-Object -First 1
                }
                LinkAccount -account $AccountLA -linkedAccount $AccountRecon -type 3 -UsernameLink $InfoRECON.Username -UsernameLinked $UsernameLA
            }

            $AccountADM = NixLocalAccount -InfoForn $InfoForn -Username $UsernameADM -InfoAccount $InfoADM -target $target

            if ($AccountADM) {
                if (-not $AccountRecon) { 
                    $AccountRecon = Get-PASAccount -search $InfoRECON.Username -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target -and $_.userName -eq $InfoRECON.Username } | Select-Object -First 1
                }
                LinkAccount -account $AccountADM -linkedAccount $AccountRecon -type 3 -UsernameLink $InfoRECON.Username -UsernameLinked $UsernameADM
                $AccountLA = Get-PASAccount -search $UsernameLA -safeName $InfoLA.Safe -ErrorAction SilentlyContinue | Where-Object { $_.address -eq $target -and $_.userName -eq $UsernameLA} | Select-Object -First 1
                if ($AccountLA) {
                    LinkAccount -account $AccountADM -linkedAccount $AccountLA -type 1 -UsernameLink $UsernameLA -UsernameLinked $UsernameADM
                }
            }
        }
    }
}
