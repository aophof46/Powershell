$NumberOfLogicalProcessors = Get-WmiObject win32_processor | Select-Object -ExpandProperty NumberOfLogicalProcessors
 
ForEach ($core in 1..$NumberOfLogicalProcessors){ 
 
start-job -ScriptBlock{
 
    $result = 1;
    foreach ($loopnumber in 1..2147483647){
        $result=1;
        
        foreach ($loopnumber1 in 1..2147483647){
        $result=1;
            
            foreach($number in 1..2147483647){
                $result = $result * $number
            }
        }
 
            $result
        }
    }
}
 
$resultsarray = @()
do {
  $row = New-Object psobject
  $battery = Get-WMIObject Win32_Battery
  
  $row | Add-Member -MemberType NoteProperty -Name Time -Value $time
  $row | Add-Member -MemberType NoteProperty -Name ChangeLeft -Value $battery.EstimatedChargeRemaining
  $row | Add-Member -MemberType NoteProperty -Name TimeLeft -Value $battery.EstimatedRunTime
  
  $row
  $resultsarray += $row
  
  start-sleep 5
}
while($true)

Stop-Job * 
