<# .SYNOPSIS
     Simple script that connects to Nessus via the API and deletes all scan histories over 7 days old.  
     Useful for those installations that do persistent nessus scanning but do want to manually rotate 
     scan history.
.NOTES
     Author     : Simon Gurney - simongurney@outlook.com
#>

$Server = "127.0.0.1"

add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
            return true;
        }
 }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function Convert-FromUnixdate ($UnixDate) {
   [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').`
   AddSeconds($UnixDate))
}

Function Log ($code, $message){
switch ($code){
0 {$colour = "Green"}
1 {$colour = "Red"}
default {$colour = "Yellow"}
} 
Write-Host $message -ForegroundColor $colour
}

$Target = "https://$server"+":8834"
while(!$stoploop)
{
Try
    {
    $Credz = @{
        username="admin"
        password= Read-Host -Prompt "Please provide the password"
        }
    $Token = (Invoke-RestMethod "$Target/session" -Body $Credz -Method POST).token
    Log 0 "Connected to $Target"
    $stopLoop = $true
    }
Catch
    {
    Log 1 "Failed Connection"
    }
}  

$stopLoop = $false


function GET ($URL){
Invoke-RestMethod "$Target/$URL" -Method GET -Headers @{"X-Cookie"="token=$token"}
}

function DELETE ($ScanID, $HistoryID){
Invoke-RestMethod "$Target/scans/$ScanID/history/$HistoryID" -Method DELETE -Headers @{"X-Cookie"="token=$token"}
}

function Update ($ScanID, $Body){
Invoke-RestMethod "$Target/scans/$ScanID" -Method PUT -Headers @{"X-Cookie"="token=$token"} -Body $Body
}

function IsItOld ($UnixTime){
if ((Convert-FromUnixdate $UnixTime) -lt (Get-Date).AddDays(-6))
{
return $true
}
else
{
return $false
}
}

$Token = (Invoke-RestMethod "$Target/session" -Body $Credz -Method POST).token

$scanIDs = (GET scans).scans.id

foreach ($scanID in $ScanIDs)
    {
    $scanHistories = (Get "scans/$scanID").history
        foreach ($scanHistory in $scanHistories)
        {
        if (IsItOld $scanHistory.last_modification_date)
            {
            Log 0 "Scan being deleted"
            DELETE $scanID $scanHistory.history_id
            }
        }
    }
