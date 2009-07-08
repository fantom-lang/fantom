//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//


function sys_FConst() {}

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

sys_FConst.Abstract   = 0x00000001;
sys_FConst.Const      = 0x00000002;
sys_FConst.Ctor       = 0x00000004;
sys_FConst.Enum       = 0x00000008;
sys_FConst.Final      = 0x00000010;
sys_FConst.Getter     = 0x00000020;
sys_FConst.Internal   = 0x00000040;
sys_FConst.Mixin      = 0x00000080;
sys_FConst.Native     = 0x00000100;
sys_FConst.Override   = 0x00000200;
sys_FConst.Private    = 0x00000400;
sys_FConst.Protected  = 0x00000800;
sys_FConst.Public     = 0x00001000;
sys_FConst.Setter     = 0x00002000;
sys_FConst.Static     = 0x00004000;
sys_FConst.Storage    = 0x00008000;
sys_FConst.Synthetic  = 0x00010000;
sys_FConst.Virtual    = 0x00020000;
sys_FConst.FlagsMask  = 0x0003ffff;