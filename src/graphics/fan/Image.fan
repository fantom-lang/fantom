//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2017  Matthew Giannini  Creation
//

**
** Graphical image.  Images are loaded from a file using `GraphicsEnv.image`.
**
@Js
mixin Image
{
  ** Unique uri key for this image in the GraphicsEnv cache.
  abstract Uri uri()

  ** Is this image completely loaded into memory for use.  When a given
  ** uri is first accessed by `GraphicsEnv.image` it may be asynchronously
  ** loaded in the background and false is returned until load is complete.
  abstract Bool isLoaded()

  ** Image format based on file type:
  **   - 'image/png'
  **   - 'image/gif'
  **   - 'image/jpeg'
  **   - 'image/svg+xml'
  abstract MimeType mime()

  ** Get the natural size of this image.
  ** If the image has not been loaded yet, then return 0,0.
  abstract Size size()

  ** Image properties
  **  - 'colorSpace' (Str) - the image color space (e.g.RGB, RGBA, CMYK)
  **  - 'colorSpaceBits' (Int) - bits-per-channel of the color space
  @NoDoc @Operator abstract Obj? get(Str prop)
}

**************************************************************************
** PngImage
**************************************************************************

**
** Details for an PNG image.  This is just a temporary solution
** until we flush out formal APIs for color models, pixel access, etc.
**
@Js @NoDoc
mixin PngImage : Image
{
  ** Does the image have an alpha channel
  Bool hasAlpha() { colorType == 4 || colorType == 6 }

  ** Does the image have a palette index
  Bool hasPalette() { palette.size > 0 }

  ** Does the image have simple transparency alpha channel
  Bool hasTransparency() { transparency.size > 0 }

  ** Color type code
  Int colorType() { get("colorType") }

  ** Number of color components
  Int colors()
  {
    c := (colorType == 2 || colorType == 6) ? 3 : 1
    return hasAlpha ? c + 1 : c
  }

  ** Number of bits in a pixel
  Int pixelBits() { colors * ((Int)get("colorSpaceBits")) }

  ** The palette index. The Buf is immutable.
  Buf palette() { get("palette") }

  ** The simple transparency alpha channel. The Buf is immutable.
  Buf transparency() { get("transparency") }

  ** Raw image data. The Buf is immutable.
  Buf imgData() { get("imgData") }

  ** Get decompressed pixels. The Buf is immutable.
  abstract Buf pixels()
}