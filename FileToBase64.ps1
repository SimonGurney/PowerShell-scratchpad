$inputFilePath = "C:\file"
$outputFilePath = "C:\b64_text.txt"

[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($inputFilePath)) > $outputFilePath