
param (
	[string]$Directory = ".",
    [string]$Age = "14"
	)


$timeStamp = Get-Date

$files = Get-ChildItem $Directory -Recurse -Force | where { ! $_.PSIsContainer }

foreach ($file in $files)
    {
    if($file.LastWriteTime -le (get-date).AddDays(-$Age))
        {
        write-host "$($file.LastWriteTime) - $($file.FullName)"
        # remove-item $file.FullName -recurse -force <- will delete the file
        }
    }