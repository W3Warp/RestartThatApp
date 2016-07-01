#requires -Version 3
Clear-Host

#region DESCRIPTION
<#
		Author: Blackkatt
		Version: 1.0.0
		Name: RestartThatApp

		Purpose: Restart failed application

		Instructions:
		please run 'RestartThatApp.cmd' to install

		What Will Happen:
		the task 'RestartThatApp.xml' is created & imported under "Event Viewer Tasks\RestartThatApp"
		the task will (Trigger On an event Event 1000, Application Error) - then restart that application if not on the "whitelist"
		if 'RestartThatApp.ps1' is moved after install, the task will stop working.

		Whitelist:
		add to the list simply follow the example bellow. applications on the whitelist will not be restarted if crashed.

		Folders:
		add/change directories goto  "#region Get-AppPath"  follow the example
		$folders = ('C:\Program Files\', 'C:\Program Files (x86)\'),

		Exclude:
		add/change folders to exclude goto  "#region Get-AppPath" follow the example
		$exclude = '(BankID.*|COMODO.*|Flirc.*|Google.*|HP\\HP.*|KeePass.*|microsoft.*|NVIDIA.*|VulkanRT.*|Windows.*)$',
#>
#endregion DESCRIPTION

#region WHITELIST & OUTPUTS
$whitelist = '(notepads.*|firefox.*)$'

# Write-Outputs
$TaskExist      = "Task Already Exist, Moving On!`n"
$TaskMissing    = "Task Doesn't Exist!, Creating. . ."
$Events         = 'Querying Event Log. . .'
$Whitelisted    = "has crashed but on the whitelist`n"
$Blacklisted    = "has crashed and is NOT on the whitelist`n"
$AppDir         = 'Locating Application. . .'
$RestartThatApp = 'found! restarting'
$Done           = "`nI'm done here!"

#endregion WHITELIST & OUTPUTS

#region CREATE TASK
$GetTask = Get-ScheduledTask -TaskPath '\Event Viewer Tasks\' -TaskName RestartThatApp -ErrorAction SilentlyContinue
if($GetTask)
{
	Write-Output -InputObject $TaskExist
}
else
{
	Write-Output -InputObject $TaskMissing

# Create Sample XML.
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
      <Command></Command>
      <Arguments></Arguments>
      <WorkingDirectory></WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@
$varFile = $template | Tee-Object -Variable RestartThatApp.xml

# Current Location.
	Set-Location $PSScriptRoot
	$varFile = 'Variable:\RestartThatApp.xml'
	$xmlFile = "$PWD\RestartThatApp.xml"
	$ps1File = 
	@"
"$PWD\RestartThatApp.ps1"
"@
	
# Manipulate XML Content.
	[xml]$getXML = Get-Content $varFile
			 $getXML.Task.Actions.Exec.Command = 'powershell.exe'
			 $getXML.Task.Actions.Exec.Arguments = "-NonInteractive -NoLogo -NoProfile -ExecutionPolicy ByPass -File $ps1File"
			 $getXML.Task.Actions.Exec.WorkingDirectory = 'C:\Windows\System32\WindowsPowerShell\v1.0'
			 $getXML.Save($xmlFile)

# Import the task.
	C:\Windows\System32\schtasks.exe /create /tn 'Event Viewer Tasks\RestartThatApp' /XML $xmlFile
}
#endregion CREATE TASK

#region GET-EVENT LOG
Write-Output -InputObject $Events

$GetEvent = Get-EventLog -LogName Application -EntryType Error -Message 'Faulting application name:*' -Newest 1
$EventMsg = $GetEvent.Message # filter that message
$Application = if ($EventMsg -match '(?<=:).*(?=, v)')
{
	$matches[0] -replace '\s', ''
} # clean that string

#endregion GET-EVENT LOG

#region WHITELIST
if ($Application -Match $whitelist)
{
	Write-Output "$Application $Whitelisted $Done"
	Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Application $Whitelisted" -Category 1 -RawData 10, 20
}
else
{
	Write-Output "$Application $Blacklisted"
#endregion WHITELIST

#region Get-AppPath
	Write-Output -InputObject $AppDir

	function Get-AppPath
	{
		<#
				.SYNOPSIS
				Get applications from folders
				.DESCRIPTION
				Exclude defined folders and Filter extensions
				.EXAMPLE
				$GetAppPath = Get-AppPath | Sort-Object -Unique
				.EXAMPLE
				Get-AppPath | Where-Object -Property Name -eq $Application | Select-Object -First 1 -ExpandProperty FullName
		#>
		[CmdletBinding()]
		param
		(
			[Parameter(Mandatory = $false, Position = 0)]
			[Object]
			$folders = ('C:\Program Files\', 'C:\Program Files (x86)\'),

			[Parameter(Mandatory = $false, Position = 1)]
			[System.String]
			$exclude = '(BankID.*|COMODO.*|Flirc.*|Google.*|HP\\HP.*|KeePass.*|microsoft.*|NVIDIA.*|VulkanRT.*|Windows.*)$',

			[Parameter(Mandatory = $false, Position = 2)]
			[System.String]
			$extensions = '*.exe'
		)

		Get-ChildItem -LiteralPath $folders -Filter $extensions -Recurse |
		Where-Object -FilterScript {
			$_.Name -notlike 'Unins*'
		} |
		Where-Object -FilterScript {
			$_.DirectoryName -notmatch $exclude
		}
	}
#endregion Get-AppPath

#region RESTART THAT APP
	$GetAppPath = Get-AppPath | Sort-Object -Unique
	if ($Item = $GetAppPath |
		Where-Object -Property Name -EQ -Value $Application |
	Select-Object -First 1 -ExpandProperty FullName)
	{
		Write-Output "$RestartThatApp $Item"
		Write-EventLog -LogName 'Windows PowerShell' -Source 'PowerShell' -EventId 300 -EntryType Information -Message "$Blacklisted" -Category 1 -RawData 10, 20
		Start-Process -FilePath $Item
	}
	Write-Output -InputObject $Done
}
#endregion RESTART THAT APP

