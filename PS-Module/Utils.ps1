
# Moduli PS-Module
$ReadConfig = "$ScriptLocation\PS-Module\ReadConfig.psm1"
$LoggingModulePath = "$ScriptLocation\PS-Module\LoggingModule.psm1"

# Importa moduli
if (Test-Path $ReadConfig) {
    Import-Module $ReadConfig -Force
} else {
    Write-Host "Errore: Modulo ReadConfig.psm1 non e' stato trovato!" -ForegroundColor Red
    exit 1
}

if (Test-Path $LoggingModulePath) {
    Import-Module $LoggingModulePath -Force
} else {
    Write-Host "Errore: Modulo LoggingModule.psm1 non e' stato trovato!" -ForegroundColor Red
    exit 1
}

# Directory Platform
. "$ScriptLocation\Platform\Platform.ps1"
. "$ScriptLocation\Platform\PlatformConfig.ps1"

# Directory Account
. "$ScriptLocation\Account\AddAccount.ps1"
. "$ScriptLocation\Account\AccountConfig.ps1"
. "$ScriptLocation\Account\Dominio.ps1"
. "$ScriptLocation\Account\Locale.ps1"
. "$ScriptLocation\Account\LinkAccount.ps1"

# Directory Safe
. "$ScriptLocation\Safe\Safe.ps1"
. "$ScriptLocation\Safe\SafeConfig.ps1"
. "$ScriptLocation\Safe\AddSafe.ps1"


# Log File
$global:LOG_FILE_MAIN = "$ScriptLocation\LOG\_PS_Onboarding.log"
$global:LOG_FILE_ACCOUNT = "$ScriptLocation\LOG\_Account.log"
$global:LOG_FILE_SAFE = "$ScriptLocation\LOG\_Safe.log"
#$global:LOG_FILE_PLATFORM = "$ScriptLocation\LOG\_Platform.log"
$global:LOG_FILE_PLATFORM = "$ScriptLocation\LOG\_UnixLocalRecon.log"

# Safe Output
$safeCSV = "AdGroup_" + $Dominio + ".csv"
$global:CSV_ADGROUP = "$ScriptLocation\Output\$safeCSV"

# Account Output
$accountCSV = "Utenze_" + $Dominio + ".csv"
$global:CSV_UTENZE = "$ScriptLocation\Output\$accountCSV"
$global:FornitoriUtenze = @{}
