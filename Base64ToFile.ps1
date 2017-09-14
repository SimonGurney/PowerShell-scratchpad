$inputFilePath = "C:\b64_text.txt"
$outputFilePath = "C:\file"
$PEBytes = [System.Convert]::FromBase64String([IO.File]::ReadAllText($InputFilePath))  
[System.IO.File]::WriteAllBytes($outputFilePath, $PEBytes);