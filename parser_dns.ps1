[System.Collections.ArrayList] $domains = @()
[System.Collections.ArrayList] $records = @()
switch -regex (&ipconfig /displaydns)
{
"Windows IP Configuration" {continue;}
"No records of type" {continue;}
"^\ *$" {continue;}
"^\ *\-*$"  {continue;}
"^\ *([^\ ]*\.[^\ ]*)" 
{
$domains.Add((New-Object -TypeName PSObject -Property @{
"Name" = $Matches[1];
"ID" = get-random -Minimum 1TB -Maximum 9TB;
})) | out-null ;continue
}
"\ *Record\ Name[\ \.]*:\ ([^\ ]*)" 
{
$records.Add((New-Object -TypeName PSObject -Property @{
"Name" = $Matches[1];
"OriginalTarget" = $domains[$domains.Count-1].Name
"ID" = get-random -Minimum 1TB -Maximum 9TB;
"ParentRecord" = if ($records.Count -gt 0 -and $records[$records.Count-1].OriginalTarget -eq $domains[$domains.Count-1].Name -and 
                    $Matches[1] -ne $records[$records.Count-1].Name){$records[$records.Count-1].ID}else{$domains[$domains.Count-1].ID}
                    # If thist isnt the first record, the potential parent is still the latest original target 
                    # and this record nameisn't the same as the parent (as that might be a secondary)
})) | out-null ;continue
}
"\ *(Record Type|Time To Live|Data Length|Section|A \(Host\) Record|CNAME Record|A \(HOST\) Record|PTR Record|AAAA Record)[\ \.]*:\ ([^\ ]*)" 
{
$records[$records.Count-1] | add-member NoteProperty $Matches[1] $Matches[2]; continue;
}
default {$_}
}


########### Look for Punycode DNS records
# $records | ? Name -like "xn*" | fl Name, "A (Host) Record"
