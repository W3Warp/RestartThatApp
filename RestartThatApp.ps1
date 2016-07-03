#requires -Version 3
Clear-Host

<#
		Author: Blackkatt
		Version: 1.1.1
		Name: RestartThatApp

		Purpose: Restart failed application

		Instructions:
		please run 'RestartThatApp.cmd' to install

		What Will Happen:
		the task 'RestartThatApp.xml' is created & imported under "Event Viewer Tasks\RestartThatApp"
		the task will (Trigger On an event Event 1000, Application Error) - then restart that application if not on the "whitelist"
		if 'RestartThatApp.ps1' is moved after install, the task will stop working.

		Whitelist:
		Applications on the list will not be restarted if they crash. Follow the current format to add/remove.
#>

$Whitelist = '(notepads.*|firefox.*)$'


#region CREATE TASK

$GetTask = Get-ScheduledTask -TaskPath '\Event Viewer Tasks\' -TaskName RestartThatApp -ErrorAction SilentlyContinue

if($GetTask)
{
	Write-Output -InputObject $TaskExist # Don't Create Task
}
else
{
	Write-Output -InputObject $TaskMissing # Create Task
	$template = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2016-06-25T15:44:21.9111474</Date>
    <Author>BK\Authority</Author>
    <Description>Restarts crashed application if not found on the whitelist</Description>
    <URI>\Event Viewer Tasks\RestartThatApp</URI>
  </RegistrationInfo>
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Application"&gt;&lt;Select Path="Application"&gt;*[System[Provider[@Name='Application Error'] and EventID=1000]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments></Arguments>
      <WorkingDirectory>C:\Windows\System32\WindowsPowerShell\v1.0</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
	$varFile = $template | Tee-Object -Variable RestartThatApp.xml

	# Current Location.
	Set-Location $PSScriptRoot
	$varFile = 'Variable:\RestartThatApp.xml'
	$xmlFile = "$PWD\RestartThatApp.xml"
	$ps1File = @"
"$PWD\RestartThatApp.ps1"
"@
	
	# Manipulate XML Content.
	[xml]$getXML = Get-Content $varFile
			 $getXML.Task.Actions.Exec.Arguments = "-NonInteractive -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy ByPass -File $ps1File"
			 $getXML.Save($xmlFile)
	
	# Import Task.
		schtasks.exe /create /tn 'Event Viewer Tasks\RestartThatApp' /XML $xmlFile
}
#endregion CREATE TASK
#region GET-EVENT LOG

$GetEvent     = Get-WinEvent -ProviderName 'Application Error' -MaxEvents 1
$EventMessage = $GetEvent.Message 
$AppPath      = [regex]::Match($EventMessage,'(Faulting application path: )(.:\\.*\.exe)').Groups[2].Value
$AppPathSplit = $AppPath.Split('\')
$AppName      = $AppPathSplit.Item(2)

#endregion GET-EVENT LOG
#region RESTART THAT APP

# Outputs if you like to change them.
$TaskExist      = 'Task Already Exist, Moving On!'
$TaskMissing    = "Task Doesn't Exist, Creating!"
$Events         = "`nQuerying Event Log. . ."
$Whitelisted    = "has crashed but on the whitelist.`n"
$Blacklisted    = "has crashed and NOT on the whitelist. . .`n"
$RestartThatApp = "Locating Application. . .`nrestarting"
$Done           = "`nI'm done here! thanks for playing."

if ($AppName -Match $Whitelist)
{
	$Report = "`n$Events`n$AppName $Whitelisted $Done"
	Write-Output -InputObject "$Report"
	Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Report" -Category 1 -RawData 10, 20
}
else
{
	$Report = "`n$Events`n$AppName $Blacklisted`n$RestartThatApp $AppName ($AppPath)`n$Done"
	Write-Output -InputObject "$Report"
	Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Report" -Category 1 -RawData 10, 20
	Start-Process -FilePath $AppPath
}

#endregion RESTART THAT APP
