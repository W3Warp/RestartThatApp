# RestartThatApp
Automatically restart failed application

		Author: Blackkatt
		Version: 1.1.3
		Name: RestartThatApp

		Purpose: Restart failed application

		Instructions:
		please run 'RestartThatApp.cmd' to install

		What Will Happen:
		the task 'RestartThatApp.xml' is created & imported under "Event Viewer Tasks\RestartThatApp"
		the task will (Trigger On an Event 1000, Application Error) - then restart that application if not on the "whitelist"
		if 'RestartThatApp.ps1' is moved after install, the task will stop working.
		also, the script will write Event entry in "Windows Powershell" found under "Applications and Service Logs"

		Whitelist:
		Applications on this list will not be restarted if they crash. Follow the current format below to add/remove.
