@echo off

:: This is the installer for RestartThatApp.ps1. Without it, you'll get an error -
:: RestartThatApp.ps1 cannot be loaded because running scripts is disabled on this system.
:: We temporary bypass that policy using this batch.

:: INSTRUCTIONS
:: Place RestartThatApp.cmd & RestartThatApp.ps1 in the same folder and run RestartThatApp.cmd to install.

set path=%~dp0
set ps="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
%ps% -noprofile -executionpolicy bypass -file  "%path%RestartThatApp.ps1"

