function Set-ServiceRecovery{
    param
    (
        [string] 
        [Parameter(Mandatory=$true)]
        $ServiceName,

        [string]
        [Parameter(Mandatory=$true)]
        $Server
    )

    sc.exe "\\$Server" failure $ServiceName reset= 0 actions= restart/60000
}
