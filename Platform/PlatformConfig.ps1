
# Impostazioni di default per Platform
$MapPlatform = @{}
$MapPlatform["WIN-DOM"] =  6
$MapPlatform["WIN-LOCAL"] = 5
$MapPlatform["NIX-DOM"] = 6
$MapPlatform["NIX-LOCAL"] = 2
$MapPlatform["WIN-LOCAL-EME"] = 5
$MapPlatform["WIN-EME"] = 6
$MapPlatform["WIN-DOM-RECON"] = 6
$MapPlatform["WIN-LOCAL-RECON"] = 5
$MapPlatform["NIX-DOM-EME"] = 6

$MapPlatform["NIX-LOCAL-RECON"] = 2
$MapPlatform["NIX-LOCAL-EME"] = 2

function platformName {
    param (
        [string]$SO,
        [string]$LocDom,
        [string]$Suffix  
    )

    if ($LocDom -match $Domain) {$LocDom = "DOM"}
    elseif ($LocDom -match $Local) {$LocDom = "LOCAL"}

    $body = $SO.ToUpper() + "-"
    if ($SO -match $Windows -and $Suffix -match $Emergenza -and $LocDom -match "DOM") {
        $body += $Suffix.ToUpper()
        if ($PrefixSafe -match "TEST-SRV") {
            $body += "-TEST"
        }
        return $body 
    }

    $body += $LocDom.ToUpper()
    if ($Suffix -match $Emergenza -or $Suffix -match $Recon) {
        $body += "-" + $Suffix.ToUpper()
    }

    if ($PrefixSafe -match "TEST-SRV") {
        $body += "-TEST"
    }

    return $body
}
