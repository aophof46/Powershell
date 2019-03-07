<#
.Synopsis
   Removes Office 365 licenses from users that are blocked in Office 365 - Written by Richard Drzaz
.DESCRIPTION
   Removes Office 365 licenses from users that are blocked in Office 365 due to their On-prem Active Directory account being disabled. AAD COnnect doesn't remove Office 365 licenses when a users get disabled in Active Directory. It just blocks the user from logging
   into Office 365 ever again.

   Prerequaites:

   Save your encrypted credential file:

   Get-Credential | Export-Clixml -Path "CredentialFIlepath.xml"

.EXAMPLE
   .\Remove-office365Licenses.ps1 -AdstaffGroup <ADStaffGroupName> -ADStudentGroup <ADStudentGroupName> -o365adminPwdFile C:\creds\YourCredentialsFIle.xml

#>

[CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://www.microsoft.com/',
                  ConfirmImpact='Medium')]
    Param
    (
       
        # Creds file for connection automation
        [Parameter(Mandatory=$true)]
        [string]$o365AdminPwdFile

    )


    Install-Module MSOnline
    Install-Module AzureAD
    Import-Module AzureAD
   

    #$o365AdminPwdFile = "C:\creds\o365Creds.xml" #This is the recommended location to store the encrypted password file
    #$credential = Import-Clixml $o365AdminPwdFile
    Connect-MsolService -Credential $(get-credential)

    #write-verbose "$LicenseSKU" -Verbose
   
    $users = Get-MsolUser -All -Synchronized | where {$_.islicensed -eq $true -and $_.blockcredential -eq $true} #| select userPrincipalName, islicensed, blockCredential | ft -AutoSize

    foreach ($user in $users)
        {
        if($user -eq $null) 
            {
            continue
            }

        else
            {
            $UserLicense = $user.Licenses.accountskuid
            $upn = $user.UserPrincipalName
            foreach($license in $UserLicense)
                {
                Set-MsolUserLicense -UserPrincipalName $upn -RemoveLicenses $license
                }
            # Temp write out to screen to verify license has been removed.
            Get-MsolUser -UserPrincipalName $upn | select userprincipalName,islicensed >> C:\Temp\Unlincense.txt                                                               
            # Write-EventLog -LogName Application -Source "Office 365 Licensing" -EventId 999 -EntryType Information -Message "Office 365 Licensing - License Name: $Userlicense, User: $upn"
            } 
           
         } 
                  
                  
                    
             
                    
