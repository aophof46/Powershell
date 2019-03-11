$DelegateUser = "Authenticated Users"

$gpos = get-gpo -all
foreach($gpo in $gpos)
    {
    $gpo.displayname
    $UserFound = $false
    if($gpo.GetSecurityInfo().trustee.name -contains $DelegateUser)
        {
        write-host "$DelegateUser found" -ForegroundColor Green
        }
    else
        {
        write-host "$DelegateUser not found" -ForegroundColor Red
        }
    }
