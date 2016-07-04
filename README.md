# RestartThatApp
Automatically restart failed application

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
