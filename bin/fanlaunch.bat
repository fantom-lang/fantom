@echo OFF
REM
REM Copyright (c) 2015, Brian Frank and Andy Frank
REM Licensed under the Academic Free License version 3.0
REM
REM History:
REM    27 Jul 2015	Matthew Giannini	Creation
REM
REM fanlaunch: launcher for Fantom programs
REM

SETLOCAL
set FAN_HOME=%~dp0%..
set JAVA=java
set FAN_JAVA_OPTS=

REM the first arg is the tool name, the rest are passed
REM as arguments to the tool itself.
set TOOL=%1
SHIFT
set TOOL_ARGS=
:argactionstart
if -%1-==-- goto argactionend
set TOOL_ARGS=%TOOL_ARGS% %1
shift
goto argactionstart
:argactionend

REM normalize path for fan home
pushd "%FAN_HOME%"
set FAN_HOME=%CD%
popd

call:getJava JAVA
call:getProp FAN_JAVA_OPTS
set FAN_CP="%FAN_HOME%\lib\java\sys.jar";"%FAN_HOME%\lib\java\jline.jar"

REM echo %JAVA% %FAN_JAVA_OPTS% -cp %FAN_CP% "-Dfan.home=%FAN_HOME%" fanx.tools.%TOOL% %TOOL_ARGS%
%JAVA% %FAN_JAVA_OPTS% -cp %FAN_CP% "-Dfan.home=%FAN_HOME%" fanx.tools.%TOOL% %TOOL_ARGS%
ENDLOCAL

:getJava
SETLOCAL
set JAVA=java
IF "%FAN_JAVA%" == "" GOTO :USEJAVAHOME
:USEFANJAVA
  SET JAVA="%FAN_JAVA%"
  GOTO :ENDFANJAVA
:USEJAVAHOME
IF "%JAVA_HOME%" == "" GOTO :ENDFANJAVA
  SET JAVA="%JAVA_HOME%\bin\java.exe"
:ENDFANJAVA
(ENDLOCAL
	IF "%~1" NEQ "" SET %~1=%JAVA%
)
GOTO:EOF

:getProp
SETLOCAL
For /F "tokens=1* delims==" %%A IN (%FAN_HOME%\etc\sys\config.props) DO (
    IF "%%A"=="java.options" set OPTIONS=%%B
    )
(ENDLOCAL
	IF "%~1" NEQ "" SET %~1=%OPTIONS%
)
GOTO:EOF
