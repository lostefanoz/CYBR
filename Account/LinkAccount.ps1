
function LinkAccount {
    param (
        [PSCustomObject]$account,
        [PSCustomObject]$linkedAccount,
        [int]$type,
        [string]$UsernameLink,
        [string]$UsernameLinked
    )

    if ($linkedAccount) {
        $LinkedAccountParams = @{
            AccountID = $account.id
            safe = $linkedAccount.safeName
            extraPasswordIndex = $type
            name = $linkedAccount.name
            folder = "root"
        }
        try {
            Set-PASLinkedAccount @LinkedAccountParams | Out-Null
            if ($type -eq 1) {
                Write-LogMessage -MSG "Account '$UsernameLink' impostato come account di logon di '$UsernameLinked'" -Type Success -LogFile $LOG_FILE_ACCOUNT
            } else {
                Write-LogMessage -MSG "Account '$UsernameLink' impostato come account di reconcile di '$UsernameLinked'" -Type Success -LogFile $LOG_FILE_ACCOUNT
            }
        } catch {
            Write-LogMessage -MSG "Errore durante il LinkedAccount per l'account '$UsernameLinked': $_" -Type Error -LogFile $LOG_FILE_ACCOUNT
        }
    }
}
