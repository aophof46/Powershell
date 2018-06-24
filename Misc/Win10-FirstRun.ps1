

# check if choco was installed
if(!(get-command choco -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue ))
    { 
    # Install Choco
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

choco feature enable -n allowGlobalConfirmation

# install software

$software = @{}
$software = "7zip", "rufus", "itunes", "dropbox", "chrome", "firefox", "putty", "postman", "pibakery", "evernote", "notepad++", "steam", "realvnc", "spotify", "teamviewer", "google-drive-file-stream"

foreach($install in $software)
    {
    choco install $install
    }
