$keyBoardObject = New-Object -ComObject WScript.Shell 

$CAPSLOCK = @{"CONTROL" = "{CAPSLOCK}"; "STATUS" = "CapsLock"}
$NUMLOCK = @{"CONTROL" = "{NUMLOCK}"; "STATUS" = "NumLock"}
$SCROLLLOCK = @{"CONTROL" = "{SCROLLLOCK}"; "STATUS" = "Scroll"}
$allLEDs = ($CAPSLOCK, $NUMLOCK, $SCROLLLOCK)

$timingLED = $CAPSLOCK
$firstBitLED = $SCROLLLOCK
$secondBitLED = $NUMLOCK
$sendDelay = 1 #ms


function get-LEDState($LED)
{
#if ($LED -notin $allLEDs ){return $False;}
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
Start-Sleep -Milliseconds $sendDelay
return $True
}

function send-TwoBits([bool]$bit1,[bool]$bit2)
{
$r = set-LEDState $firstBitLED $bit1
$r = set-LEDState $secondBitLED $bit2
$r = switch-LEDState $timingLED
}

set-LEDState $allLEDs[0] $False
set-LEDState $allLEDs[1] $False
set-LEDState $allLEDs[2] $False

$array = @()
$buf = ""
$State = get-LEDState $timingLED
while ((get-LEDState $timingLED) -eq $State){}

:control while($true)
{
if ($buf.length -eq 8){$array = $array + $buf;$buf=""}
if (get-LEDState $firstBitLED) {$buf += "1"}
else {$buf += "0"}
if (get-LEDState $secondBitLED) {$buf += "1"}
else {$buf += "0"}
echo $buf
$time = Get-Date
$State = get-LEDState $timingLED
while ((get-LEDState $timingLED) -eq $State)
{
if ($time.AddSeconds(500) -lt (get-date)){break control}
}
}

Foreach ($byte in $array)
{
$int = 0
for ($x = 1; $x -lt 9; $x++){
if ($byte[$x-1] -eq "0")
{
$bit = 0
}
else
{
$bit = 1
}
$int += ($bit * ([math]::pow(2,($x-1))))
}
$int
}