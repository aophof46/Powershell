$SizeofFile = "100000000" # Size in Bytes, will be the maximum of the random number generated
$NameOfFile =  "Dummy"
$NumberOfFiles = "5"
$LocationOfFiles = "C:\temp"

if(!(Test-Path $LocationOfFiles))
    {
    New-Item -ItemType Directory $LocationOfFiles
    }

for($i = 1; $i -le $NumberOfFiles; $i++)
    {
    $Size = Get-Random -Minimum 1 -Maximum $SizeofFile
    $Path = $LocationOfFiles + '\' + $NameOfFile + '_' + $i + '.TestFile'
    $File = [io.file]::Create($Path)
    $File.SetLength($Size)
    $File.Close()  
    sleep 0.5
    }
