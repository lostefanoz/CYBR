# Funzione per leggere il file INI e restituire un oggetto PowerShell
function Get-IniContent {
    param (
        [string]$FilePath
    )

    $IniContent = @{}
    $Section = ""

    foreach ($Line in Get-Content -Path $FilePath) {
        $Line = $Line.Trim()

        # Ignora linee vuote e commenti
        if ($Line -match "^\s*;|^\s*$") { continue }

        # Riconosce le sezioni [Sezione]
        if ($Line -match "^\[(.+)\]$") {
            $Section = $matches[1]
            $IniContent[$Section] = @{}
        }
        # Riconosce le coppie chiave=valore
        elseif ($Line -match "^(.+?)\s*=\s*(.*)$") {
            $Key, $Value = $matches[1], $matches[2]
            $IniContent[$Section][$Key] = $Value
        }
    }

    return $IniContent
}
Write-Host "$ScriptLocation"
# Percorso del file di configurazione
$ConfigPath = "$ScriptLocation\config.ini"

# Controlla se il file di configurazione esiste
if (-not (Test-Path $ConfigPath)) {
    Write-Host "Errore: Il file di configurazione config.ini non esiste!" -ForegroundColor Red
    Write-Host "$ScriptLocation"
    exit 1
}

# Legge il file di configurazione
$Config = Get-IniContent -FilePath $ConfigPath


# Assegna le variabili globali

# Tenant config
$global:Tenant = $Config["CONFIG"]["Tenant"]
$global:Dominio = $Config["CONFIG"]["Dominio"]
$global:CPM = $Config["CONFIG"]["CPM"]
$global:User = $Config["CONFIG"]["User"]

# Safe naming convention
$global:PrefixSafe = $Config["SAFE"]["Ambiente"] + "-" + $Config["SAFE"]["Device"]

# System naming convention
$global:Windows = $Config["SO"]["Windows"]
$global:Unix = $Config["SO"]["Unix"]
$global:Local = $Config["SO"]["Local"]
$global:Domain = $Config["SO"]["Domain"]
$global:Recon = $Config["SO"]["Recon"]
$global:Admin = $Config["SO"]["Admin"]
$global:Emergenza = $Config["SO"]["Emergenza"]

# User naming convention
$global:UsernameSTD = $Config["USER"]["UsernameSTD"] + "-"

$global:NoName = "UNKNOWN"
