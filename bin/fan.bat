@echo off
REM
REM Copyright (c) 2015, Brian Frank and Andy Frank
REM Licensed under the Academic Free License version 3.0
REM
REM History:
REM    27 Jul 2015	Matthew Giannini	Creation
REM
REM fan: launcher for Fantom programs
REM

call "%~fs0\..\fanlaunch.bat" Fan %*
EXIT /B %errorlevel%
