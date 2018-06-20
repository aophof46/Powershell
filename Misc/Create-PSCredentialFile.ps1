# Specify credentials here and convert to pscredential.  Get-Credentials can be used instead for interactive mode
$user = "<user name>"
$pass = "<plain text password>"
$SecurePass = ConvertTo-SecureString $pass -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($user, $SecurePass)

# Specify File to export to and then export credentials
$outFile = "c:\temp\" + $user + "_pscredential.xml"
$mycreds | export-clixml -Path $outfile

# Use Import-CliXml to import credentials for use
# $credential = Import-CliXml -Path $outfile
