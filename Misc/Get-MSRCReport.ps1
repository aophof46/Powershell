# Adapted from https://paullimblog.wordpress.com/2018/10/06/microsoft-security-update-api/

if(!(Get-module -Name MsrcSecurityUpdates)) {
    Install-Module -Name MsrcSecurityUpdates -Force -Confirm:$false
    Get-Command -Module MsrcSecurityUpdates
}

#https://portal.msrc.microsoft.com/en-us/developer
$APIKey = "Put your API Key here"
Set-MSRCApiKey -ApiKey $APIKey -Verbose

$cveMonth = get-date -UFormat %Y-%b

Get-MsrcCvrfDocument -ID $cveMonth | Get-MsrcVulnerabilityReportHtml | Out-File -FilePath "c:\temp\$cveMonth-cvrf-CVE-Summary.html"
