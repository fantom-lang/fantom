# 
# Copyright (c) 2015, Brian Frank and Andy Frank
# Licensed under the Academic Free License version 3.0
#
# History:
#   23 Jul 15  Matthew Giannini Creation
#
# fanp: fcode disassembler
#

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
. $scriptPath\fanlaunch.ps1
Launch-Fan -Tool "Fan" "compiler::Fanp" @args