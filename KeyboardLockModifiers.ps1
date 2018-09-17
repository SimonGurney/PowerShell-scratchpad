$keyBoardObject = New-Object -ComObject WScript.Shell 
$KeyStatus = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock') # Capslock, NumLock or Scroll
$keyBoardObject.SendKeys("{SCROLLLOCK}") # CAPSLOCK, NUMLOCK or SCROLLLOCK

