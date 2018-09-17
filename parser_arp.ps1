[System.Collections.ArrayList] $interfaces = @()
[System.Collections.ArrayList] $records = @()
switch -regex (&arp -a)
{
"\W*Internet" {continue;}
"Interface:\W*(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})\ \-\-\-\ ([^\W]*)" 
{
$interfaces.Add((New-Object -TypeName PSObject -Property @{
"IP" = $Matches[1];
"ID" = $Matches[2];
})) | out-null ;continue
}
"\W*(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})\W*([^\ ]*)\W*([^\ ]*)" 
{
$records.Add((New-Object -TypeName PSObject -Property @{
"Ip" = $Matches[1];
"Mac" = $Matches[2];
"Type" = $Matches[3];
"InterfaceIP" = $interfaces[$interfaces.Count-1].IP
"InterfaceID" = $interfaces[$interfaces.Count-1].ID
})) | out-null ;continue
}
default {$_}
}


########### Look for multiple IPs with the same MAC to maybe show arp spoofing
$records | select -property Mac, InterfaceIP |  Group-Object Mac | ? Count -gt 1 | ft Count, Name, @{label="IPs";e={$_.Group.InterfaceIP}}

