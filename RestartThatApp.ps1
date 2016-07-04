#requires -Version 3
Clear-Host

<#
		Author: Blackkatt
		Version: 1.1.3
		Name: RestartThatApp

		Purpose:
		Restart an faulting V.I.P. application.

		Instructions:
		Please run 'RestartThatApp.cmd' to install.

		What Will Happen:
		If not present, 'RestartThatApp.xml' is created & imported in Task Scheduler under  "Event Viewer Tasks\RestartThatApp"
		this task triggers on an (Event 1000, Application Error) and will restart faulting app if found on the VIP List.
		
		Note:
		If you move 'RestartThatApp.ps1' after installation task will stop working. Until you update the task with the new path.

		The VIP List:
		Applications on this list will be restarted if they crash. Use format below to add/remove to/from the list.
#>

  $TheVIPList = '(deluge.*|kodi.*|notepad.*)$'

#region CUSTOMIZE

  $TaskExist      = 'Task Already Exist, Moving On!'
  $TaskMissing    = "Task Doesn't Exist, Creating!"
  $Events         = 'Querying Event Log. . .'
  $Whitelisted    = 'has crashed and is on the VIP list.'
  $Blacklisted    = 'has crashed but NOT on the VIP list. . .'
  $RestartThatApp = "Locating Application. . .`nrestarting"
  $Done           = "I'm done here! thanks for playing."

#endregion CUSTOMIZE
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
    <Description>Restarts crashed application if not found on the The VIP List</Description>
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

  # Manipulate XML Content.
  Set-Location $PSScriptRoot
  $varFile = 'Variable:\RestartThatApp.xml'
  $xmlFile = "$pwd\RestartThatApp.xml"
  $ps1File = @"
 "$pwd\RestartThatApp.ps1"
"@
  [xml]$getXML = Get-Content $varFile
       $getXML.Task.Actions.Exec.Arguments = "-NonInteractive -NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy ByPass -File $ps1File"
       # Export Task.
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

  $EP = {Stop-Process -Name $AppName -Force -ErrorAction SilentlyContinue}
  $SP = {Start-Process -FilePath $AppPath}
  $WP =	{Wait-Process -Name $AppName -Timeout 5 -ErrorAction SilentlyContinue}

if ($AppName -Match $TheVIPList)
{
	$Report = "`n`n$Events`n$AppName $Whitelisted`n`n$RestartThatApp $AppName ($AppPath)`n`n$Done"
	Write-Output -InputObject "$Report"
	Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Report" -Category 1 -RawData 10, 20
	&$EP
	&$WP
	&$SP
}
else 
{
	$Report = "`n`n$Events`n$AppName $Blacklisted $Done"
	Write-Output -InputObject "$Report"
	Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Report" -Category 1 -RawData 10, 20	
}
#endregion RESTART THAT APP
