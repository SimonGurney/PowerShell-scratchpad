[System.Collections.ArrayList] $output = @()
switch -regex (&netstat -abno)
{
"^\W*$" {continue}
"^\W*Act.*" {continue}
"Can not obtain" {continue}
"Proto" {continue}
"(TCP|UDP)\W*(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}):(\d{1,5})\W*(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}):(\d{1,5})\W*(LISTENING|ESTABLISHED|TIME_WAIT|CLOSE_WAIT|SYN_SENT)\W*(\d{1,5})" 
{
$output.Add((New-Object -TypeName PSObject -Property @{
"Protocol" = $Matches[1];
"LocalIP" = $Matches[2];
"LocalPort" = $Matches[3];
"RemoteIP" = $Matches[4];
"RemotePort" = $Matches[5];
"State" = $Matches[6];
"ProcessID" = $Matches[7];
"ProcessName" = $false;
"ProcessName2" = $false;
})) | out-null ;continue
}
"(TCP|UDP)\W*(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}):(\d{1,5})\W*(\d{1,5})" 
{
$output.Add((New-Object -TypeName PSObject -Property @{
"Protocol" = $Matches[1];
"LocalIP" = $Matches[2];
"LocalPort" = $Matches[3];
"RemoteIP" = $false
"RemotePort" = $false
"State" = $false
"ProcessID" = $Matches[4];
"ProcessName" = $false;
"ProcessName2" = $false;
})) | out-null ;continue
}
"\W*\[([^\]]*)\].*" {$output[$output.Count-1].ProcessName=$Matches[1];continue}#
"\W*(.*)\W*" {$output[$output.Count-1].ProcessName2=$Matches[1];continue}
default {$_}
}


########### Look for processes outside of system32 or program files
#$output | ? {$_.processid -ne 0 -and (Get-Process -id $_.processid ).Path -notmatch "(.*[sS]ystem32,*|[pP]rogram)"} | ft

