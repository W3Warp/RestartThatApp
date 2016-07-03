# RestartThatApp
Automatically restart failed application

		Author: Blackkatt
		Version: 1.1.0
		Name: RestartThatApp

		Purpose: Restart failed application

		Instructions:
		please run 'RestartThatApp.cmd' to install

		What Will Happen:
		the task 'RestartThatApp.xml' is created & imported under "Event Viewer Tasks\RestartThatApp"
		the task will (Trigger On an event Event 1000, Application Error) - then restart that application if not on the "whitelist"
		if 'RestartThatApp.ps1' is moved after install, the task will stop working.
		also, the script will write an Event log in "Windows Powershell" found under "Applications and Service Logs"

		Whitelist:
		add to the list simply follow the example bellow. applications on the whitelist will not be restarted if crashed.

