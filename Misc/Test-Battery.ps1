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
