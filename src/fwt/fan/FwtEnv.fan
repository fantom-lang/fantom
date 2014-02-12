//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   30 Apr 09  Brian Frank  Creation
//

using gfx

**
** FwtEnv the gfx environment implementation for the Fantom Widget Toolkit.
**
@NoDoc
@Js
internal const class FwtEnv : GfxEnv
{
  override native Size imageSize(Image i)
  override native Image imageResize(Image i, Size s)
  override native Image imagePaint(Size s, |Graphics| f)
  override native Void imageDispose(Image i)
  override native Void imageWrite(Image i, MimeType t, OutStream o)

  override native Int fontHeight(Font f)
  override native Int fontAscent(Font f)
  override native Int fontDescent(Font f)
  override native Int fontLeading(Font f)
  override native Int fontWidth(Font f, Str s)
  override native Void fontDispose(Font f)

  override native Void colorDispose(Color c)

}