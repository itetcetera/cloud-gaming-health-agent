

# Based on https://gist.github.com/19WAS85/5424431


# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on
$http.Prefixes.Add("http://*:80/")

# Start the Http Server 
$http.Start()



# Log ready message to terminal 
if ($http.IsListening) {
    write-host " HTTP Server Ready!  " -f 'black' -b 'gre'
    write-host "now try going to $($http.Prefixes)" -f 'y'
}



while ($http.IsListening) {




    $context = $http.GetContext()



    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/health/') {


        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'


        [string]$html = $(start-job -name Cloudhealth -ScriptBlock {
        

New-Item -ItemType File -Path C:\ParsecTemp\Busy.txt | Out-Null

function CheckInstallDependancies {
if ((Get-PackageProvider -name Nuget).name -eq 'Nuget'){} Else {Install-PackageProvider -Name "Nuget" -Force}
if (((Get-ChildItem Env:PATH).value -like '*C:\Program Files\WindowsPowerShell\Scripts*') -eq $true) {} else {[System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + ";C:\Program Files\WindowsPowerShell\Scripts", "Machine")}
if ((get-command speedtest).CommandType -eq 'ExternalScript') {} Else {Install-Script -Name Speedtest -Force}
if ((Get-Package -Name AudioDeviceCmdlets).Name -EQ 'AudioDeviceCmdlets') {} Else { Install-Package AudioDeviceCmdLets -Force}
}

CheckInstallDependancies



function SpeedtestModified {

<#PSScriptInfo

.VERSION 2.0

.GUID a6048a09-3e66-467a-acd4-ce3e97098a65

.AUTHOR velecky@velecky.onmicrosoft.com

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 WAN speed test 

#> 

Param()


Function downloadSpeed($strUploadUrl)
{
    $topServerUrlSpilt = $strUploadUrl -split 'upload'
    $url = $topServerUrlSpilt[0] + 'random2000x2000.jpg'
    $col = new-object System.Collections.Specialized.NameValueCollection 
    $wc = new-object system.net.WebClient
    $wc.QueryString = $col 
    $downloadElaspedTime = try {(measure-command {$webpage1 = $wc.DownloadData($url)}).totalmilliseconds} 
    catch {}
    $string = [System.Text.Encoding]::ASCII.GetString($webpage1)
    $downSize = ($webpage1.length + $webpage2.length) / 1Mb
    $downloadSize = [Math]::Round($downSize, 2)
    $downloadTimeSec = $downloadElaspedTime * 0.001
    $downSpeed = ($downloadSize / $downloadTimeSec) * 8
    $downloadSpeed = [Math]::Round($downSpeed, 2)
    return $downloadSpeed 
}

<#
Using this method to make the submission to speedtest. Its the only way i could figure out how to interact with the page since there is no API.
More information for later here: https://support.microsoft.com/en-us/kb/290591
#>
$objXmlHttp = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp.Open("GET", "http://www.speedtest.net/speedtest-config.php", $False)
$objXmlHttp.Send()

#Retrieving the content of the response.
[xml]$content = $objXmlHttp.responseText

<#
Gives me the Latitude and Longitude so i can pick the closer server to me to actually test against. It doesnt seem to automatically do this.
Lat and Longitude for tampa at my house are $orilat = 27.9238 and $orilon = -82.3505
This is corroborated against: http://www.travelmath.com/cities/Tampa,+FL - It checks out.
#>
$oriLat = $content.settings.client.lat
$oriLon = $content.settings.client.lon

#Making another request. This time to get the server list from the site.
$objXmlHttp1 = New-Object -ComObject MSXML2.ServerXMLHTTP
$objXmlHttp1.Open("GET", "http://www.speedtest.net/speedtest-servers.php", $False)
$objXmlHttp1.Send()

#Retrieving the content of the response.
[xml]$ServerList = $objXmlHttp1.responseText

<#
$Cons contains all of the information about every server in the speedtest.net database. 
I was going to filter this to US servers only which would speed this up a lot but i know we have overseas partners we run this against. 
Results returned look like this for each individual server:

url     : http://speedtestnet.rapidsys.com/speedtest/upload.php
lat     : 27.9709
lon     : -82.4646
name    : Tampa, FL
country : United States
cc      : US
sponsor : Rapid Systems
id      : 1296

#>
$cons = $ServerList.settings.servers.server 

#Below we calculate servers relative closeness to you by doing some math against latitude and longitude. 
foreach($val in $cons) 
{ 
    $R = 6371;
    [float]$dlat = ([float]$oriLat - [float]$val.lat) * 3.14 / 180;
    [float]$dlon = ([float]$oriLon - [float]$val.lon) * 3.14 / 180;
    [float]$a = [math]::Sin([float]$dLat/2) * [math]::Sin([float]$dLat/2) + [math]::Cos([float]$oriLat * 3.14 / 180 ) * [math]::Cos([float]$val.lat * 3.14 / 180 ) * [math]::Sin([float]$dLon/2) * [math]::Sin([float]$dLon/2);
    [float]$c = 2 * [math]::Atan2([math]::Sqrt([float]$a ), [math]::Sqrt(1 - [float]$a));
    [float]$d = [float]$R * [float]$c;

    $ServerInformation +=
@([pscustomobject]@{Distance = $d; Country = $val.country; Sponsor = $val.sponsor; Url = $val.url })

}

$serverinformation = $serverinformation | Sort-Object -Property distance

#Runs the functions 4 times and takes the highest result.
$DLResults1 = downloadSpeed($serverinformation[0].url) 
$SpeedResults += @([pscustomobject]@{Speed = $DLResults1;})

$DLResults2 = downloadSpeed($serverinformation[1].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults2;})

$DLResults3 = downloadSpeed($serverinformation[2].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults3;})

$DLResults4 = downloadSpeed($serverinformation[3].url)
$SpeedResults += @([pscustomobject]@{Speed = $DLResults4;})

$UnsortedResults = $SpeedResults | Sort-Object -Property speed
$WanSpeed = $UnsortedResults[3].speed
Write-Output "Wan Speed is $($Wanspeed) Mbit/Sec"
}

function Provider {
Try {
If($(Invoke-WebRequest -Uri http://metadata.paperspace.com/meta-data/machine -TimeoutSec 1).StatusCode -eq '200'){$true}
}
catch [System.Net.WebException],[System.IO.IOException]
{
Try {
If ($(Invoke-WebRequest -Uri http://169.254.169.254/latest/user-data -TimeoutSec 1).StatusCode -eq  '200') {$true}
Elseif ($(Invoke-WebRequest -Uri http://metadata.google.internal/computeMetadata -TimeoutSec 1).StatusCode -eq  '200') {$true}
Elseif ($(Invoke-WebRequest -Uri http://169.254.169.254/metadata/instance -TimeoutSec 1).StatusCode -eq  '200') {$true}
}
catch [System.Net.WebException],[System.IO.IOException]
{
$false
}
}
}

function jitter {
$pingtest = (Test-Connection 8.8.8.8 -Count 10).ResponseTime 
$jitter = ($pingtest | measure -Maximum).Maximum - ($pingtest | measure -minimum).minimum
if ($jitter -le 1) {"none"}
Elseif ($jitter -le 5) {"low"}
Elseif ($jitter -le 10) {"average"}
Else {"High"}
}


function validDriver {
#checks an important nvidia driver folder to see if it exits
test-path -Path "C:\Program Files\NVIDIA Corporation\NVSMI"
}

function driverVersion {
#Queries WMI to request the driver version, and formats it to match that of a NVIDIA Driver version number (NNN.NN) 
Try {(Get-WmiObject Win32_PnPSignedDriver | where {$_.DeviceName -like "*nvidia*" -and $_.DeviceClass -like "Display"} | Select-Object -ExpandProperty DriverVersion).substring(7,6).replace('.','').Insert(3,'.')}
Catch {return $null}
}

function resolution {
Add-Type -AssemblyName System.Windows.Forms
$resolution = ([System.Windows.Forms.Screen]::AllScreens | Where-Object {$_.Primary -eq 'True'}).bounds
"$($($resolution).width)" + "x" + "$($($resolution).height)"
}

function GPUCurrentMode {
#returns if the GPU is running in TCC or WDDM mode
$nvidiaarg = "-i 0 --query-gpu=driver_model.current --format=csv,noheader"
$nvidiasmi = "c:\program files\nvidia corporation\nvsmi\nvidia-smi" 
try {Invoke-Expression "& `"$nvidiasmi`" $nvidiaarg"}
catch {$null}
}

function diskcheck {
$counter=0 
$disklatency = New-Object -TypeName psobject
do {
write-output $Counter
$disklatency | add-member -membertype NoteProperty -name $("Test" + $counter) -Value $($(Get-Counter -Counter '\LogicalDisk(c:)\Avg. Disk sec/Read').countersamples.cookedvalue * 1000)
start-sleep -s 1
$counter++
}
Until(
$counter -ge 10
)
}
Function Average($array)
{
diskcheck
    $RunningTotal = 0;
    foreach($i in $array){
        $RunningTotal += $i
    }
    return ([decimal]($RunningTotal) / [decimal]($array.Length));
}
function disklatencyaverage {
$items = @($disklatency.Test0, $disklatency.Test1, $disklatency.Test2, $disklatency.Test3, $disklatency.Test4, $disklatency.Test5, $disklatency.Test6, $disklatency.Test7, $disklatency.Test8, $disklatency.Test9);
$average = Average($items)
if ($average -lt 10) {"low"}
Elseif ($average -le 100) {"average"} 
Elseif ($average -gt 101) {"high"}
}

function GetDriverOS {
$inf = $($(Get-CimInstance win32_PnPSignedDriver | Where-Object HardwareID -like "*$((Get-PnpDevice | Where-Object {$_.class -eq 'display' -or $_.FriendlyName -like '3D Video Controller' -and $_.instanceid -like '*PCI\VEN_10DE*'}).instanceid.split('\')[1])").InfName)
$infLocation = (Get-WindowsDriver -Online -All | where-object {$_.Driver -eq $inf}).OriginalFileName
(Get-Content -Path $infLocation | select -first 1).split(';')[1].substring(1)
}

function StartupShutdownLog {
New-Item -ItemType File C:\parsectemp\timeexport.txt | Out-Null
New-Item -ItemType File C:\ParsecTemp\dateexport.txt | Out-Null
foreach ($event in $(Get-WinEvent -LogName System | Where { $_.ProviderName -eq 'EventLog' -and $_.id -eq 6008}).message) {
$event.substring(47,12).replace('','') | Out-File C:\parsectemp\dateexport.txt -Encoding ascii -Force -Append
$event.substring(32,11) | Out-File C:\parsectemp\timeexport.txt -Encoding ascii -Force -Append
}

foreach ($dateparse in $((get-content -Path C:\ParsecTemp\dateexport.txt))){
$dateparse = $dateparse.replace('?','')
if ((($dateparse).split('/')[0]).length -lt 2) {$finaldate = ($dateparse).insert(0,'0')}
Else {$finaldate = $dateparse}
}

$unexpectedshutdown = foreach ($timeparse in $((get-content -Path C:\ParsecTemp\timeexport.txt))) {
$timeparse = if ((($timeparse).split(':')[0]).length -lt 2) {($timeparse).insert(0,'0').replace(' ','')}
Else {($timeparse).replace(' ','')}
foreach ($finaldateline in $finaldate) {}
$datetime = $timeparse +' '+$finaldateline
foreach ($date in $datetime){
$date = [datetime]::parseexact($date, 'hh:mm:sstt MM/dd/yyyy', $null)
}
[pscustomobject]@{
Message = "A Shutdown Occured"
Time = $date
}
}

$expectedshutdown = foreach ($logtime in $(Get-EventLog -LogName system -Source user32).TimeGenerated) {
[pscustomobject]@{
Message = "A Shutdown Occured"
Time = $logtime
}
}


$startup = foreach ($logtime in $(Get-EventLog -LogName System -InstanceId 12).TimeGenerated) {
[pscustomobject]@{
Message = "A Startup Occured"
Time = $logtime
}
}

$ts = New-TimeSpan -Hours 1
(get-date) + $ts | out-file -FilePath $env:APPDATA\ParsecLoader\ShutdownTime.txt

$normalshutdown = get-date(get-date -Date $(Get-content -path $env:APPDATA\ParsecLoader\ShutdownTime.txt)[1])
$prewarmshutdown = Get-Date(Get-Date -Date $(get-content -path $env:USERPROFILE\Downloads\startup-log.txt)[6])

$finalshutdown = IF ((Test-Path -Path C:\parsectemp\FinalShutdown.txt) -eq $true) {(get-content -Path C:\parsectemp\FinalShutdown.txt)[1]} else {Get-Date -Date "01/01/1970"}
$prewarmshutdown = IF ((Test-Path -Path C:\parsectemp\startup-log.txt) -eq $true) {get-date (get-date (get-content -path C:\ParsecTemp\startup-log.txt)[6])} else {Get-Date -Date "01/01/1970"}
$lastshutdown = if ($finalshutdown -gt $prewarmshutdown) {$finalshutdown} Else {$prewarmshutdown} 
$StartupShutdown = $unexpectedshutdown + $expectedshutdown + $startup | sort time | Where-Object time -gt $lastshutdown

$StartupShutdown
Remove-Item C:\ParsecTemp\Dateexport.txt
Remove-Item C:\ParsecTemp\Timeexport.txt
}


$cpu = Get-WmiObject Win32_Processor

$usersession = (((query.exe user).trim() -replace ">" -replace "(?m)^([A-Za-z0-9]{3,})\s+(\d{1,2}\s+\w+)", '$1  none  $2' -replace "\s{2,}", "," -replace "none", $null)) | convertfrom-csv

$gpu = Get-PnpDevice | Where-Object {$_.class -eq 'display' -or $_.FriendlyName -like '3D Video Controller' -and $_.instanceid -like '*PCI\VEN_10DE*'} 

$vigem =  if ((Get-PnpDevice | Where-Object {$_.FriendlyName -like 'Virtual Gamepad Emulation Bus' -and $_.status -eq 'OK'}) -ne $null) {$true} Else {$false}

$service = Get-WmiObject win32_service | Where-Object Name -eq 'Parsec'



$health = @{}
$health.gpu = @{}
$health.parsec = @{}
$health.connectivity = @{}
$health.disk = @{}
$health.cpu = @{}
$health.audio = @{}
$health.user = @{}
$health.python = @{}
$health.log = @{}

$health.connectivity.jitter = jitter
$health.connectivity.resolveUserData = provider
$health.connectivity.httpProxy = if((Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyEnable -eq 1){$true} Else {$false}
$health.connectivity.speedTest = $(SpeedTestModified).split(' ')[3] + ' ' + "Mbit/Sec"
$health.parsec.version = (get-childitem $env:APPDATA\parsec | where {$_.Extension -eq ".dll" -and $_.Name -like 'parsec*'}).BaseName
$health.parsec.echocancellation = (get-childitem $env:APPDATA\parsec | where {$_.Extension -eq ".dll" -and $_.Name -like 'harmony*'}).BaseName
$health.parsec.installed = if ((test-path -path $env:APPDATA\Parsec\Electron\parsec.exe) -eq $true){$true} Else {$false} 
$health.parsec.daemon = if ((get-process -Name parsecd) -ne $null) {"Running"} else {"Stopped"}
$health.parsec.electron = if ((get-process -Name parsec) -ne $null) {"Running"} else {"Stopped"}
$health.parsec.serviceState = ($service | Select-Object -Property state -ExpandProperty state).state
$health.parsec.serviceUser = ($service | Select-Object -Property startname -ExpandProperty startname).startname
$health.parsec.vigemInstalled = $vigem
$health.gpu.hostResolution = resolution
$health.gpu.driverInstalled = validdriver
$health.gpu.driverVersion = driverversion
$health.gpu.mode = gpucurrentmode
$health.gpu.status = $gpu.Status
$health.gpu.name = $gpu.Name
$health.gpu.driverINF = getDriverOS
$health.disk.readLatency = disklatencyaverage
$health.disk.hddSize = [math]::Round($($(get-partition -DriveLetter C).size /1GB))
$health.disk.freeSpace = [math]::Round($($(get-psdrive C).Free /1GB), 2)
$health.cpu.name = ($cpu).Name
$health.cpu.cores = ($cpu).NumberOfLogicalProcessors
$health.cpu.clockSpeed = [math]::Round(($($cpu).MaxClockSpeed / 1000),2)
$health.audio.playbackDevice = (get-audiodevice -playback).name
$health.user.username = $usersession.USERNAME
$health.user.sessionType = $usersession.SESSIONNAME
$health.python.version = $(&{python -V} 2>&1).TargetObject
$health.python.path = if (((Get-ChildItem Env:PATH).value -like '*C:\Python27*' -and '*C:\Python27\Scripts*') -eq $true) {$true} else {$false}
$health.python.python_home = if (((Get-ChildItem Env:PYTHON_HOME).value -like '*C:\Python27*') -eq $true) {$true} else {$false}
$health.log.startupShutdown = StartupShutdownLog

$health | convertto-json | out-file C:\parsectemp\json.json -Force

Remove-Item -Path C:\ParsecTemp\Busy.txt
})
        
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
        $context.Response.OutputStream.Close() # close the response
    
    }
    elseif ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/status/') {
        

        # We can log the request to the terminal
        write-host "$($context.Request.UserHostAddress)  =>  $($context.Request.Url)" -f 'mag'

        # the html/data you want to send to the browser
        # you could replace this with: [string]$html = Get-Content "C:\some\path\index.html" -Raw

        $html = $(if((Test-Path -Path C:\parsectemp\Busy.txt) -eq $true){"Busy"} Else {if((test-path -path C:\parsectemp\json.json) -eq $true) {$(get-content C:\parsectemp\json.json)} else {"Ready"}}
        )
        
        #resposed to the request
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($html) # convert htmtl to bytes
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length) #stream to broswer
        $context.Response.OutputStream.Close() # close the response

        }


} 

# Note:
# To end the loop you have to kill the powershell terminal. ctrl-c wont work :/

