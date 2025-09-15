# Definizione dei ruoli
$ConnectOnlyRole = [PSCustomObject]@{
    UseAccounts = $true
    ListAccounts = $true
    ViewAuditLog = $false
    ViewSafeMembers = $false
}
  
$FullRole = [PSCustomObject]@{
    ListAccounts = $true
    UseAccounts = $true
    RetrieveAccounts = $true
    AddAccounts = $true
    UpdateAccountProperties = $true
    UpdateAccountContent = $true
    InitiateCPMAccountManagementOperations = $true
    SpecifyNextAccountContent = $true
    RenameAccounts = $true
    DeleteAccounts = $true
    UnlockAccounts = $true
    ManageSafe = $true
    ManageSafeMembers = $true
    BackupSafe = $true
    ViewAuditLog = $true
    ViewSafeMembers = $true
    RequestsAuthorizationLevel1 = $true
    AccessWithoutConfirmation = $true
    MoveAccountsAndFolders = $true
    CreateFolders = $true
    DeleteFolders = $true
}



$global:SafeReconDom = "PROD-SRV" + "-" + $Windows.ToUpper() + "-" + $Domain.ToUpper() + "-" + $Recon.ToUpper() 

$global:SafeWinEme = $PrefixSafe.ToUpper() + "-" + $Windows.ToUpper() + "-" + $Emergenza.ToUpper()

$global:SafeNixEmeDom = $PrefixSafe.ToUpper() + "-" + $Unix.ToUpper() + "-" + $Emergenza.ToUpper() + "-" + $Domain.ToUpper()

$global:SafeNixEmeLoc = $PrefixSafe.ToUpper() + "-" + $Unix.ToUpper() + "-" + $Emergenza.ToUpper() + "-" + $Local.ToUpper()

$MapSafes = @{}
$MapSafes[$SafeWinEme]      = "Gruppo di emergenza dei server e delle utenze Windows"
$MapSafes[$SafeNixEmeDom]   = "Gruppo di emergenza dei server e delle utenze *NIX locali"
$MapSafes[$SafeNixEmeLoc]   = "Gruppo di emergenza dei server e delle utenze *NIX di dominio"
$MapSafes[$SafeReconDom]    = "Safe dedicata alla gestione delle utenze di recon di dominio"


function GenerateSafeDescription {
    param ( [string]$fornitore, [string]$SO, [string]$Suffisso )
    
    $body = "Gruppo responsabile della "

    if ($Suffisso -match $Recon) { 
        
        $body += "recon dei server "

        if ($SO -match $Unix) { $body += "Unix " } 

        else { $body += "Windows " }

        $body += "e utenze locali per fornitore "
    } 
    else {  
        
        $body += "gestione dei server "

        if ($SO -match $Unix) { $body += "Unix " } 

        else { $body += "Windows " }

        $body += "e utenze "

        if ($Suffisso -match $Domain) { $body += "di dominio " } 

        else {
            if ($Suffisso -match $Admin) { 
                $body += "adm " 
            } else {
                $body += "locali "
            }
        }

        $body += "per fornitore "
    }

    $body += $fornitore

    if ($body.Length -gt 100 ) {
        $body = $body.Substring(0, 100)
    }

    return $body
}

class SafeInfo {
    [string]$Alias
    [string]$SO
    [string]$Suffisso
    [string]$descrizione

    SafeInfo([string]$Fornitore, [string]$Alias, [string]$SO, [string]$Suffisso) 
    {
        $this.SO = $SO + "-"
        $this.Alias = $Alias.ToUpper() + "-"
        $this.Suffisso = $Suffisso
        $this.descrizione = GenerateSafeDescription -fornitore $Fornitore -SO $SO.ToLower() -Suffisso $Suffisso.ToLower()
    }
    [string] GenerateSafeName() {
        return $global:PrefixSafe + "-" + $this.SO + $this.Alias + $this.Suffisso
    }
}
