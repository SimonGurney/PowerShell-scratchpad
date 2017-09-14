#VBS has a line length limit so big string declarations need to be broken up, this script does that.

$inputFilePath = "C:\b64_text.txt"
$outputFilePath = "C:\Output.txt"

$variableName = "StringVariable"
$lineSize = 200
    
$encodedCommand = [IO.File]::ReadAllText($inputFilePath)
$y = 0
$formattingCharacters = "`n","`r","`t"

write-output "" > $outputFilePath
while($y -lt $encodedCommand.Length) 
    {
    $x=0;
    [string]$buffer="";
    while($x -lt $lineSize)
        {
        if ($encodedCommand[$y] -notin $formattingCharacters)
            {
            $buffer=$buffer+$encodedcommand[$y]
            $x++
            }
        $y++
        }
    $line = "$variableName = $variableName & `""+$buffer+"`""
    write-output $line >> $outputFilePath
    }
