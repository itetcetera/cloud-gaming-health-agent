function requesthealth {
if ([System.Text.Encoding]::ASCII.GetString((Invoke-WebRequest -uri "http://localhost/status/").content) -eq "Busy") {"Script Busy, come back later"
pause
exit}
Invoke-WebRequest -Uri "http://localhost/health/" | Out-Null
$timeelapsed = 0
Do {
Start-Sleep -s 5
$timeelapsed += 5
write-host ([System.Text.Encoding]::ASCII.GetString((Invoke-WebRequest -uri "http://localhost/status/").content) +' '+ "-" + ' ' + "Time Elapsed:" +' '+ $timeelapsed + ' '+ "Seconds")
}
Until ([System.Text.Encoding]::ASCII.GetString((Invoke-WebRequest -uri "http://localhost/status/").content) -like '*{*')
}
requesthealth
$output = $(([System.Text.Encoding]::ASCII.GetString((Invoke-WebRequest -uri "http://localhost/status/").content)) | ConvertFrom-Json )
cls
Write-host "Done"
$output