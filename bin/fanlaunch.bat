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
IF "%FAN_HOME%" == "" SET FAN_HOME=%~dp0%..
SET JAVA=java
SET FAN_JAVA_OPTS=

REM point FAN_HOME to rel if this is a buildscript that requires fansubstitute
call :fansubstitute FAN_HOME %1 %2 || EXIT /B 1

REM the first arg is the tool name, the rest are passed
REM as arguments to the tool itself.
SET TOOL=%1
SHIFT
SET TOOL_ARGS=
:argactionstart
IF -%1-==-- GOTO :argactionend
SET TOOL_ARGS=%TOOL_ARGS% %1
SHIFT
GOTO :argactionstart
:argactionend

REM normalize path for fan home
pushd "%FAN_HOME%"
SET FAN_HOME=%CD%
popd

call:getJava JAVA
call:getProp FAN_JAVA_OPTS
SET FAN_CP="%FAN_HOME%\lib\java\sys.jar";"%FAN_HOME%\lib\java\jline.jar"

IF "%FAN_LAUNCHER_DEBUG%" == "true" (
  ECHO -- LAUNCHER DEBUG ON
	ECHO -- Launcher Args: %*
	ECHO -- FAN_HOME: "%FAN_HOME%"
	ECHO -- Java: %JAVA%
	ECHO -- Fantom classpath: %FAN_CP%
	ECHO -- Java Options: %FAN_JAVA_OPTS%
	ECHO -- Fantom Tool: %TOOL%
	ECHO -- Tool Args: %TOOL_ARGS%
	ECHO -- Command:
	ECHO --    %JAVA% %FAN_JAVA_OPTS% -cp %FAN_CP% "-Dfan.home=%FAN_HOME%" fanx.tools.%TOOL% %TOOL_ARGS%
)
%JAVA% %FAN_JAVA_OPTS% -cp %FAN_CP% "-Dfan.home=%FAN_HOME%" fanx.tools.%TOOL% %TOOL_ARGS%
ENDLOCAL
EXIT /B %errorlevel%

:getJava
SETLOCAL
SET JAVA=java
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
For /F "tokens=1* delims==" %%A IN ('type "%FAN_HOME%\etc\sys\config.props"') DO (
    IF "%%A"=="java.options" set OPTIONS=%%B
    )
(ENDLOCAL
	IF "%~1" NEQ "" SET %~1=%OPTIONS%
)
GOTO:EOF

REM If the tool is Fan, and we are running against a file,
REM then check the first line of the file to see if it has
REM the unix "#! /usr/bin/env fansubstitute" shebang. If
REM we detect this, then we reset FAN_HOME to the value of
REM FAN_SUBSTITUTE environment variable.
:fansubstitute
SETLOCAL
IF "%~2" NEQ "Fan" EXIT /B 0
IF EXIST "%~3\*" EXIT /B 0   REM check if it is a directory
IF NOT EXIST "%~3" EXIT /B 0
SET /P HEAD=<%~dpnx3
SET "SEARCH=%HEAD%"

ECHO.%SEARCH%|findstr /C:"fansubstitute" >nul 2>&1
IF ERRORLEVEL 1 EXIT /B 0

IF "%FAN_SUBSTITUTE%" == "" (
	ECHO FAN_SUBSTITUTE environment variable must be set
	EXIT /B 1
)
(ENDLOCAL
	IF "%~1" NEQ "" SET %~1=%FAN_SUBSTITUTE%
)
EXIT /B 0
