
#Import the PS PKI Module
# Install-Module -Name PSPKI -RequiredVersion 3.2.7.0 -Force
if(!(Get-Module -ListAvailable -Name "PSPKI"))
    {
    Import-Module PSPKI
    }

$daysforward = "30"
$daysbackward = "30"

#Variables
$TempFile = "C:\Temp\CA_Report.html"
$Today = get-date
$To = "recipient@example.org"
$From = "sender@example.org"
$SMTPServer = "smtp.example.org"

$expiringdeadline = (Get-Date).AddDays($daysforward)   #Set deadline date
$expireddeadline = (Get-Date).AddDays(-$daysbackward )   #Set deadline date

#Get the CA Name
$CAName = (Get-CA | select Computername).Computername

#Get Details on Issued Certs
# $Output = Get-CA | Get-IssuedRequest | select RequestID, CommonName, NotAfter, CertificateTemplate | sort Notafter
$Output = Get-CA | Get-IssuedRequest | select CommonName, NotAfter, CertificateTemplate | sort Notafter

#Take the above, and exclude CAExchange Certs, Select the first one, and get an integer value on how many days until the earliest renewal is necessary
#$RelevantInfo = ($Output | where-Object {$_.CertificateTemplate -notlike "CAExchange"})

# Choose what certificate templates you want to report from
# use the following command to get unique cert names
# $output | select-object -Property CertificateTemplate -Unique
$RelevantInfo = ($output | where {($_.CertificateTemplate -eq "desired cert template 1") `
-or ($_.CertificateTemplate -eq "desired cert template 2") `
-or ($_.CertificateTemplate -eq "desired cert template 3") `
-or ($_.CertificateTemplate -eq "desired cert template 4") `
-or ($_.CertificateTemplate -eq "desired cert template 5") `
-or ($_.CertificateTemplate -eq "desired cert template 6")})


# Get certs that will expire in the next $daysforward and have expired in the past $daysbackward
$expiringcerts = $RelevantInfo | where-object {($_.NotAfter -le $expiringdeadline) -and ($_.NotAfter -gt $(Get-date))}
$expiredcerts = $RelevantInfo | where-object {($_.NotAfter -ge $expireddeadline) -and ($_.NotAfter -lt $(Get-date))}

$expiringHTML = $expiringcerts | ConvertTo-Html -Body "<h2 style='color:#0000FF'>Certificates expiring in $daysforward days</h2>" 
$expiredHTML = $expiredcerts | ConvertTo-Html -Body "<h2 style='color:#FF0000'>Certificates expired in the last $daysbackward days</h2>" 

#Make the mail body
$Body = [string]$expiringHTML + "<br><br><br>" + [string]$expiredHTML
$Body = $Body -replace "\<table\>",'<table cellpadding="10" border=1>'

# Write to file if desired
#$Body | out-file -FilePath $TempFile

$Subject = "PS Report - Expiring and Expired Certificates"

# Send an email
Send-mailmessage -To $To -From $From -SmtpServer $SMTPServer -Subject $Subject -Body $Body -BodyAsHtml

