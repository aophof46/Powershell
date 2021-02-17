if($($env:username) -like "<my management id>")
    {
	function prompt 
	    {
	    Write-Host "PS " -nonewline -foregroundcolor White
	    Write-Host "[$Env:username]" -nonewline -foregroundcolor Red
	    Write-Host " $PWD >" -nonewline -foregroundcolor White
	    return " "
	    } 
    net use t: "\\path\to\drive\i\want\to\map"
	}
else
	{
	function prompt 
	    {
	    Write-Host "PS " -nonewline -foregroundcolor White
	    Write-Host "[$Env:username]" -nonewline -foregroundcolor Green
	    Write-Host " $PWD >" -nonewline -foregroundcolor White
	    return " "
	    } 
	}	
