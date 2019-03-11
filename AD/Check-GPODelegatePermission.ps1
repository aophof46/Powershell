$DelegateUser = "Authenticated Users"

$gpos = get-gpo -all
foreach($gpo in $gpos)
    {
    $gpo.displayname
    $security = $gpo.getsecurityinfo()
    foreach($user in $security)
        {
        $UserFound = $false
        if($($user.trustee).name -eq $DelegateUser)
            {
            $UserFound = $true
            break
            }
        }
    If($UserFound)
        {
        write-host "$DelegateUser found" -ForegroundColor Green
        }
    else
        {
        write-host "$DelegateUser not found" -ForegroundColor Red
        }
    }
