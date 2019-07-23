$UserComputerEntry = Read-Host -Prompt 'What is the computer name?'

Function Get-RemoteProgram {
<#
.Synopsis
Generates a list of installed programs on a computer

.DESCRIPTION
This function generates a list by querying the registry and returning the installed programs of a local or remote computer.

.NOTES   
Name       : Get-RemoteProgram
Author     : Jaap Brasser
Version    : 1.4.1
DateCreated: 2013-08-23
DateUpdated: 2018-04-09
Blog       : http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.PARAMETER ComputerName
The computer to which connectivity will be checked

.PARAMETER Property
Additional values to be loaded from the registry. Can contain a string or an array of string that will be attempted to retrieve from the registry for each program entry

.PARAMETER IncludeProgram
This will include the Programs matching that are specified as argument in this parameter. Wildcards are allowed. Both Include- and ExcludeProgram can be specified, where IncludeProgram will be matched first

.PARAMETER ExcludeProgram
This will exclude the Programs matching that are specified as argument in this parameter. Wildcards are allowed. Both Include- and ExcludeProgram can be specified, where IncludeProgram will be matched first

.PARAMETER ProgramRegExMatch
This parameter will change the default behaviour of IncludeProgram and ExcludeProgram from -like operator to -match operator. This allows for more complex matching if required.

.PARAMETER LastAccessTime
Estimates the last time the program was executed by looking in the installation folder, if it exists, and retrieves the most recent LastAccessTime attribute of any .exe in that folder. This increases execution time of this script as it requires (remotely) querying the file system to retrieve this information.

.PARAMETER ExcludeSimilar
This will filter out similar programnames, the default value is to filter on the first 3 words in a program name. If a program only consists of less words it is excluded and it will not be filtered. For example if you Visual Studio 2015 installed it will list all the components individually, using -ExcludeSimilar will only display the first entry.

.PARAMETER SimilarWord
This parameter only works when ExcludeSimilar is specified, it changes the default of first 3 words to any desired value.

.EXAMPLE
Get-RemoteProgram

Description:
Will generate a list of installed programs on local machine

.EXAMPLE
Get-RemoteProgram -ComputerName server01,server02

Description:
Will generate a list of installed programs on server01 and server02

.EXAMPLE
Get-RemoteProgram -ComputerName Server01 -Property DisplayVersion,VersionMajor

Description:
Will gather the list of programs from Server01 and attempts to retrieve the displayversion and versionmajor subkeys from the registry for each installed program

.EXAMPLE
'server01','server02' | Get-RemoteProgram -Property Uninstallstring

Description
Will retrieve the installed programs on server01/02 that are passed on to the function through the pipeline and also retrieves the uninstall string for each program

.EXAMPLE
'server01','server02' | Get-RemoteProgram -Property Uninstallstring -ExcludeSimilar -SimilarWord 4

Description
Will retrieve the installed programs on server01/02 that are passed on to the function through the pipeline and also retrieves the uninstall string for each program. Will only display a single entry of a program of which the first four words are identical.

.EXAMPLE
Get-RemoteProgram -Property installdate,uninstallstring,installlocation -LastAccessTime | Where-Object {$_.installlocation}

Description
Will gather the list of programs from Server01 and retrieves the InstallDate,UninstallString and InstallLocation properties. Then filters out all products that do not have a installlocation set and displays the LastAccessTime when it can be resolved.

.EXAMPLE
Get-RemoteProgram -Property installdate -IncludeProgram *office*

Description
Will retrieve the InstallDate of all components that match the wildcard pattern of *office*

.EXAMPLE
Get-RemoteProgram -Property installdate -IncludeProgram 'Microsoft Office Access','Microsoft SQL Server 2014'

Description
Will retrieve the InstallDate of all components that exactly match Microsoft Office Access & Microsoft SQL Server 2014

.EXAMPLE
Get-RemoteProgram -IncludeProgram ^Office -ProgramRegExMatch

Description
Will retrieve the InstallDate of all components that match the regex pattern of ^Office.*, which means any ProgramName starting with the word Office
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(ValueFromPipeline              =$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0
        )]
        [string[]]
            $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
        [string[]]
            $Property,
        [string[]]
            $IncludeProgram,
        [string[]]
            $ExcludeProgram,
        [switch]
            $ProgramRegExMatch,
        [switch]
            $LastAccessTime,
        [switch]
            $ExcludeSimilar,
        [int]
            $SimilarWord
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'

        if ($psversiontable.psversion.major -gt 2) {
            $HashProperty = [ordered]@{}    
        } else {
            $HashProperty = @{}
            $SelectProperty = @('ComputerName','ProgramName')
            if ($Property) {
                $SelectProperty += $Property
            }
            if ($LastAccessTime) {
                $SelectProperty += 'LastAccessTime'
            }
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                $socket = New-Object Net.Sockets.TcpClient($Computer, 445)
                if ($socket.Connected) {
                    $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
                    $RegistryLocation | ForEach-Object {
                        $CurrentReg = $_
                        if ($RegBase) {
                            $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                            if ($CurrentRegKey) {
                                $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                                    $HashProperty.ComputerName = $Computer
                                    $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                                    
                                    if ($IncludeProgram) {
                                        if ($ProgramRegExMatch) {
                                            $IncludeProgram | ForEach-Object {
                                                if ($DisplayName -notmatch $_) {
                                                    $DisplayName = $null
                                                }
                                            }
                                        } else {
                                            $IncludeProgram | ForEach-Object {
                                                if ($DisplayName -notlike $_) {
                                                    $DisplayName = $null
                                                }
                                            }
                                        }
                                    }

                                    if ($ExcludeProgram) {
                                        if ($ProgramRegExMatch) {
                                            $ExcludeProgram | ForEach-Object {
                                                if ($DisplayName -match $_) {
                                                    $DisplayName = $null
                                                }
                                            }
                                        } else {
                                            $ExcludeProgram | ForEach-Object {
                                                if ($DisplayName -like $_) {
                                                    $DisplayName = $null
                                                }
                                            }
                                        }
                                    }

                                    if ($DisplayName) {
                                        if ($Property) {
                                            foreach ($CurrentProperty in $Property) {
                                                $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                            }
                                        }
                                        if ($LastAccessTime) {
                                            $InstallPath = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('InstallLocation') -replace '\\$',''
                                            if ($InstallPath) {
                                                $WmiSplat = @{
                                                    ComputerName = $Computer
                                                    Query        = $("ASSOCIATORS OF {Win32_Directory.Name='$InstallPath'} Where ResultClass = CIM_DataFile")
                                                    ErrorAction  = 'SilentlyContinue'
                                                }
                                                $HashProperty.LastAccessTime = Get-WmiObject @WmiSplat |
                                                    Where-Object {$_.Extension -eq 'exe' -and $_.LastAccessed} |
                                                    Sort-Object -Property LastAccessed |
                                                    Select-Object -Last 1 | ForEach-Object {
                                                        $_.ConvertToDateTime($_.LastAccessed)
                                                    }
                                            } else {
                                                $HashProperty.LastAccessTime = $null
                                            }
                                        }
                                        
                                        if ($psversiontable.psversion.major -gt 2) {
                                            [pscustomobject]$HashProperty
                                        } else {
                                            New-Object -TypeName PSCustomObject -Property $HashProperty |
                                            Select-Object -Property $SelectProperty
                                        }
                                    }
                                    $socket.Close()
                                }

                            }

                        }

                    }
                }
            } catch {
                Write-Error $_
            }
        }
    }
}

Function Find-ADComputer
    {
    <#
    .SYNOPSIS
    Function to search all domains for a matching AD computer account, retrieve a match or a list of matches for selection one one name, and return it.
    .EXAMPLE
    Find-ADComputer -ComputerName laptop1
    .PARAMETER ComputerName
    Computer name
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$ComputerName,
        [bool]$Output = $false
        ) 
     $Domains = $(Get-ADForest).Domains
     $GlobalCatalogs = $(Get-ADForest).GlobalCatalogs

    # Get all matches from all global catalog 

    TRY
        {
		$computerlistarray += Get-ADComputer -Identity $ComputerName -server "$($GlobalCatalogs[0]):3268" -Properties *
		}
	Catch
        {
		$computerlistarray += Get-AdComputer -server "$($GlobalCatalogs[0]):3268" -Properties * -LDAPFilter "(name=*$ComputerName*)"
		}

    # If just one match, return it.  Otherwise let the user pick.
    if($computerlistarray.count -eq "1")
        {
        $value = $computerlistarray
        return $value
        }
    elseif($computerlistarray.count -eq "0")
        {
        $value = ""
        return $value
        }
    else
        {
        # Keep presenting the user with choices until just one name is chosen
        $Choices = "2"
        While($Choices -gt "1")
            {
            $ComputerChoice = $computerlistarray | select-object name, PasswordLastSet, DistinguishedName| Out-gridview -PassThru -Title "Multiple computers found.  Select the correct computer that you would like to pull the applications from"
            $Choices = $ComputerChoice.Count
            }
        $value = $computerlistarray  | where-object {$_.DistinguishedName -eq $ComputerChoice.DistinguishedName }
        return $value
        }
}

$computer = Find-ADComputer $UserComputerEntry

$NameOfReport = "$($Computer.name) Application Report"

# Source
$a = "<meta name=`"Source`" content=`"$([system.environment]::MachineName)`">`n"
# email style sheet
$a = $a + "<style>`n"
$a = $a + "body {color:#333333;}`n"
$a = $a + "table {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;width: 75%;}`n"
$a = $a + "th {text-align:left; font-weight:bold; border-width: 1px;padding: 5px;border-style: solid;border-color: black; color:#eeeeee; background-color:#333333;}`n"
$a = $a + "td {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}`n"
$a = $a + ".success { background-color: #66ff66; }`n"
$a = $a + ".warning { background-color: yellow; }`n"
$a = $a + ".failure { background-color: #ff6666; }`n"
$a = $a + ".inprocess { background-color: #00aaff; }`n"
$a = $a + "</style>`n"

$top = $a
$top += "<h3>" + $NameOfReport + " " + $(get-date).ToString() + "</h3>"



$apps = get-remoteprogram -ComputerName $computer.Name
$bodystring = $apps | select-object computername, ProgramName -unique | sort-object programname | ConvertTo-Html -Fragment
$bodystring = $top + $bodystring

$bodystring | Out-File -FilePath "c:\temp\$($computer.name)_ApplicationReport.html"
