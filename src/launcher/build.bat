@echo off
rem
rem build.bat
rem
rem   This batch file builds the launcher executables for Win32.
rem   You will need to install the C++ compiler and Platform SDK, we
rem   assume the PlatformSDK include and libs are available under
rem   the VC directory:
rem     http://forums.microsoft.com/MSDN/ShowPost.aspx?PostID=7004&SiteID=1
rem
rem   Environment variables which must be passed in:
rem      VCINSTALLDIR - Microsoft Visual Studio C++ (use vcvars32.bat)
rem      fan_home     - home directory of Fan installation
rem      java_home    - home directory of installed JDK
rem

rem sdk is the Windows PlatformSDK dir (we assume installed under VC)
set sdk=%VCINSTALLDIR%\PlatformSDK
set ndk=%VCINSTALLDIR%\..\SDK\v2.0

rem compiler setup
set includes=/I"%sdk%\Include" /I"%ndk%\include" /I"%java_home%\include" /I"%java_home%\include\win32"
set libs="%sdk%\Lib\uuid.lib" "%sdk%\Lib\advapi32.lib"
set defs=/D_CRT_SECURE_NO_DEPRECATE
set compile=cl %defs% %includes% launcher.cpp props.cpp java.cpp dotnet.cpp utils.cpp %libs%

rem compile each executable
%compile% /DFAN_TOOL="\"Fan\""   /Fe%fan_home%\bin\fan.exe
%compile% /DFAN_TOOL="\"Fant\""  /Fe%fan_home%\bin\fant.exe
%compile% /DFAN_TOOL="\"Jstub\"" /Fe%fan_home%\bin\jstub.exe
%compile% /DFAN_TOOL="\"Nstub\"" /Fe%fan_home%\bin\nstub.exe
%compile% /DFAN_TOOL="\"Fan\"" /DFAN_MAIN="\"compiler::Fanp\"" /Fe%fan_home%\bin\fanp.exe
%compile% /DFAN_TOOL="\"Fan\"" /DFAN_MAIN="\"fansh::Main\"" /Fe%fan_home%\bin\fansh.exe
%compile% /DFAN_TOOL="\"Fan\"" /DFAN_MAIN="\"flux::Main\""  /Fe%fan_home%\bin\flux.exe

rem cleanup
del *.obj
del *.tlh

echo
echo **
echo ** SUCCESS!
echo **