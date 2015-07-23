# 
# Copyright (c) 2015, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0
#
# History:
#   23 Jul 15  Matthew Giannini Creation
#
# fansh: interactive shell
#

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. $scriptPath\fanlaunch.ps1
Launch-Fan -Tool "Fan" fansh @args