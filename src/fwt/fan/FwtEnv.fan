//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Apr 09  Brian Frank  Creation
//

using gfx

**
** FwtEnv the gfx environment implementation for the Fan Widget Toolkit.
**
const class FwtEnv : GfxEnv
{

//////////////////////////////////////////////////////////////////////////
// Font Support
//////////////////////////////////////////////////////////////////////////

  override native Int fontHeight(Font f)
  override native Int fontAscent(Font f)
  override native Int fontDescent(Font f)
  override native Int fontLeading(Font f)
  override native Int fontWidth(Font f, Str s)


}