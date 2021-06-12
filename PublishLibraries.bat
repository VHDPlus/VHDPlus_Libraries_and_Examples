SET version=1.6
Set OUTPUT=publish

::Clear output
MKDIR %OUTPUT%
del /f /s /q %OUTPUT% 1>nul

powershell Compress-Archive -DestinationPath %OUTPUT%\Libraries_%version%.zip -Path Libraries\* -Force
echo %version% https://cdn.vhdplus.com/vhdpluslibraries/Libraries_%version%.zip > %OUTPUT%\VersionInfoWin64.txt
echo %version% https://cdn.vhdplus.com/vhdpluslibraries/Libraries_%version%.zip > %OUTPUT%\VersionInfoLinux64.txt

"C:\Program Files (x86)\WinSCP\WinSCP.com" /ini=nul /script=UploadLibraries.txt

PAUSE