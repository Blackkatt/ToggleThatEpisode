@echo off

:: DON'T CHANGE ANYTHING IN THIS FILE, THANKS

:: This is the launcher for ToggleThatEpisode.ps1. Without it, you'll get an error -
:: ToggleThatEpisode.ps1 cannot be loaded because running scripts is disabled on this system.
:: We temporary bypass that policy using this batch.

:: NOTES
:: Place ToggleThatEpisodeLNCHR.cmd & ToggleThatEpisode.ps1 in the same folder.
:: Read easy instructions in ToggleThatEpisode.ps1

set path=%~dp0
set ps="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
%ps% -noprofile -executionpolicy bypass -file  "%path%ToggleThatEpisode.ps1"

