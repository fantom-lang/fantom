# 
# Copyright (c) 2015, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0
#
# History:
#   22 Jul 15  Matthew Giannini Creation
#

# Directory containing this script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Determine fantom home
$fanHome = Split-Path -Parent $scriptPath
if (Test-Path Env:FAN_HOME)
{
    if (Test-Path $Env:FAN_HOME)
    {
        $fanHome = $Env:FAN_HOME
    }
    else
    {
        Write-Warning "FAN_HOME is set, but does not exist: '${Env:FAN_HOME}'. Using default '${fanHome}'"
    }
}

# Determine java classpath
$javaLib = (Join-Path (Join-Path $fanHome "lib") "java")
$fanCp = ((Join-Path $javaLib "sys.jar"), 
          (Join-Path $javaLib "jline.jar")) -Join ";" 
if (Test-Path Env:FAN_CP)
{
    $fanCp = $Env:FAN_CP 
}

# Verify java
$javaCmd = "java.exe"
function verifyJava($action)
{
    if ((Get-Command $javaCmd -ErrorAction SilentlyContinue) -eq $null)
    {
        Write-Error -Message "java not found '${javaCmd}'" -RecommendedAction $action
        Break
    }
}
if (Test-Path Env:FAN_JAVA)
{
    $javaCmd = $Env:FAN_JAVA
    verifyJava "Fix FAN_JAVA environment variable"
}
elseif (Test-Path Env:JAVA_HOME)
{
    $javaCmd = (Join-Path (Join-Path $Env:JAVA_HOME "bin") "java.exe")
    verifyJava "Fix JAVA_HOME environment variable"
}
else
{
    verifyJava "Ensure Java is installed and in the PATH"
}

# This function gets a single property value from etc/sys/config.props.
# It is pretty basic and only works for single-line property definitions.
function Get-SysConfigProp($prop)
{
    $configProps = (Join-Path (Join-Path (Join-Path $fanHome "etc") "sys") "config.props")
    $contents = (Get-Content $configProps) -split "`n"
    $props = $contents | where { $t = $_.Trim(); -Not ([String]::IsNullOrEmpty($t) -or $t.startsWith("//")) }
    $line = $props | where { $_.Trim().StartsWith($prop) }
    $line.Split("=", 2)[1]
}

# Launcher function. Takes the class name of the tool to run.
# A java command is launched to run that class and we pass all
# undeclared parameters as arguments to that tool's main method.
function Launch-Fan()
{
    Param([string]$Tool)
    $javaOpts = Get-SysConfigProp "java.options"
    & $javaCmd -cp ('"'+$fanCp+'"') ('"'+$javaOpts+'"') ('"-Dfan.home='+$fanHome+'"') "fanx.tools.${Tool}" $args
}