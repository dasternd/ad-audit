#
#  This script exports consolidated and filtered event logs to CSV
#  Author: Danil Stepanov, msware.ru (c) 2022
#

Set-Variable -Name EventAgeDays -Value 7     #we will take events for the latest 7 days
Set-Variable -Name CompArr -Value @("DC1", "DC2")   # replace it with your server names
Set-Variable -Name LogNames -Value @("Application", "System", "DFS Replication", "Directory Service", "DNS Server")  # Checking app and system logs
Set-Variable -Name EventTypes -Value @("Error", "Warning")  # Loading only Errors and Warnings
Set-Variable -Name ExportFolder -Value "C:\Temp\"


$el_c = @()   #consolidated error log
$now = Get-Date
$startdate = $now.AddDays(-$EventAgeDays)
$ExportFile = $ExportFolder + "el" + $now.ToString("yyyy-MM-dd--hh-mm-ss") + ".csv"  # we cannot use standard delimiteds like ":"

foreach($comp in $CompArr)
{
  foreach($log in $LogNames)
  {
    Write-Host Processing $comp\$log
    $el = Get-EventLog -ComputerName $comp -Log $log -After $startdate -EntryType $EventTypes
    $el_c += $el  #consolidating
  }
}
$el_sorted = $el_c | Sort-Object TimeGenerated    #sort by time
Write-Host Exporting to $ExportFile
# $el_sorted | Select EntryType, TimeGenerated, Source, EventID, MachineName | Export-CSV $ExportFile -NoTypeInfo  #EXPORT
$el_sorted | Export-CSV $ExportFile -NoTypeInfo  #EXPORT
Write-Host Done!