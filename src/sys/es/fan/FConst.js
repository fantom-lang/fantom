//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   12 Apr 2023  Matthew Giannini  Refactor to ES
//

class FConst {

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  static Abstract   = 0x00000001;
  static Const      = 0x00000002;
  static Ctor       = 0x00000004;
  static Enum       = 0x00000008;
  static Facet      = 0x00000010;
  static Final      = 0x00000020;
  static Getter     = 0x00000040;
  static Internal   = 0x00000080;
  static Mixin      = 0x00000100;
  static Native     = 0x00000200;
  static Override   = 0x00000400;
  static Private    = 0x00000800;
  static Protected  = 0x00001000;
  static Public     = 0x00002000;
  static Setter     = 0x00004000;
  static Static     = 0x00008000;
  static Storage    = 0x00010000;
  static Synthetic  = 0x00020000;
  static Virtual    = 0x00040000;
  static FlagsMask  = 0x0007ffff;
}