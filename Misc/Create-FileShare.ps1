$LocationOfFiles = "C:\temp"
$NameOfShare = "Temp IT Files"


if(!((Get-SmbShare | Where-Object {$_.Path -eq $LocationOfFiles})) `
        -or (Get-SmbShare | Where-Object {$_.Name -eq $NameOfShare}))
    {
    New-SmbShare -Name $NameOfShare -Path $LocationOfFiles
    }
