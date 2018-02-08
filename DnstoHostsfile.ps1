# A little script to cycle through the DNS zones of a DNS server and generate a static hosts file.
# Useful for times when DNS is down, i.e. Emergency and DR PCs / Laptops
# Set your output path

# Generates lots of errors but thats expected, dont panic.

$outputFilePath = "/hosts.txt"

function FindTheIP ($HostName){
Try
{
$IPAddress = Resolve-DnsName $HostName -ErrorAction Stop | ? Type -eq "A" -ErrorAction Stop | select IPAddress -First 1
}
Catch
{
$IPAddress = $A_Records | ? HostName -eq ($HostName.Split("."))[0] | select RecordData.IPv4Address.IPAddressToString
}
if ($IPAddress)
{
return ($IPAddress.IPAddress)
}
}

function WriteOut ($Line){
Write-Debug $Line
Write-Output $Line >> $outputFilePath
}

$ErrorActionPreference = "Continue"

Try
{
Write-Output ("##### Start of Simons Host File
###
###
### Generated on: " + (get-date) +"
###
###
### How Exciting!
###
###
#####") > $outputFilePath
Write-Debug "Successfully cleared $outputFilePath"
}
Catch
{
Write-Error "Cant write to $outputFilePath"
exit(2)
}

Try
{
$PrimaryForwardZones = Get-DnsServerZone | Where-Object {
$_.IsReverseLookupZone -eq $false -and 
$_.ZoneType -eq "Primary" -and 
$_.Zonename -ne "TrustAnchors"
}
Write-Debug ("Got " + $PrimaryForwardZones.Length + " DNS Zones")
}
Catch
{
Write-Error "Can't get DNZ zones"
exit(2)
}

$PrimaryForwardZones | foreach {
$Suffix = $_.ZoneName
WriteOut ("########## Begin Zone $Suffix ##########")
Try
{
$ResourceRecords = $_ | Get-DnsServerResourceRecord -ErrorAction Stop
Write-Debug ("Successfully got "+$ResourceRecords.length+" records for $Suffix")
}
Catch
{
Write-Error "Couldn't get records for $Suffix"
}
$ResourceRecords | foreach {
if($_.RecordType -eq "A")
{
$IPAddress = $_.RecordData.IPv4Address.IPAddressToString
}
if($_.RecordType -eq "CNAME")
{
$IPAddress = FindTheIP($_.RecordData.HostNameAlias)
if (! $IPAddress)
{
Write-Error ("Couldn't resolve " + $_.RecordData.HostNameAlias + " which is the alias for "+ $_.HostName )
}
}
if ($IPAddress)
{
WriteOut($IPAddress+"`t"+$_.Hostname+"."+$Suffix)
}
Remove-Variable IPAddress -ErrorAction SilentlyContinue ## Clear up so we don't reuse old data in later calls
}
}

