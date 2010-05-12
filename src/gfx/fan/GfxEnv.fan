//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Apr 09  Brian Frank  Creation
//

using concurrent

**
** GfxEnv models an implementation of the gfx graphics API.
**
@Js
abstract const class GfxEnv
{

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the current thread's graphics environment.  If no
  ** environment is active then throw Err or return null based
  ** on checked flag.  The current environment is configured
  ** with the "gfx.env" Actor local.
  **
  static GfxEnv? cur(Bool checked := true)
  {
    GfxEnv? env := Actor.locals["gfx.env"]
    if (env != null) return env
    if (checked) throw Err("No GfxEnv is active")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Image Support
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the size of the image or 0,0 if not loaded yet for
  ** this environment.
  **
  abstract Size imageSize(Image img)

  **
  ** Resize this image into a new image for this environment.
  **
  abstract Image imageResize(Image img, Size size)

//////////////////////////////////////////////////////////////////////////
// Font Support
//////////////////////////////////////////////////////////////////////////

  **
  ** Get height of this font for this environment.  The height
  ** is the pixels is the sum of ascent, descent, and leading.
  **
  abstract Int fontHeight(Font f)

  **
  ** Get ascent of this font for this environment.  The ascent
  ** is the distance in pixels from baseline to top of chars, not
  ** including any leading area.
  **
  abstract Int fontAscent(Font f)

  **
  ** Get descent of this font for this environment.  The descent
  ** is the distance in pixels from baseline to bottom of chars, not
  ** including any leading area.
  **
  abstract Int fontDescent(Font f)

  **
  ** Get leading of this font for this environment.  The leading
  ** area is the distance in pixels above the ascent which may include
  ** accents and other marks.
  **
  abstract Int fontLeading(Font f)

  **
  ** Get the width of the string in pixels when painted
  ** with this font for this environment.
  **
  abstract Int fontWidth(Font f, Str s)


}