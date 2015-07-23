# 
# Copyright (c) 2015, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0
#
# History:
#   23 Jul 15  Matthew Giannini Creation
#
# fanr: Fantom Repository Manager
#
# NOTE: PowerShell does not add quotes around a parameter when passing it
# to native app (like java) when the parameter does not contain a space or
# begin with a quote. So, to do a fanr query for all pods using PowerShell
# you must do:
# 
# C:\fan\bin> .\fanr.ps1 """*"""
#   or
# C:\fan\bin> .\fanr.ps1 '"*"'
#

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. $scriptPath\fanlaunch.ps1
Launch-Fan -Tool "Fan" fanr @args