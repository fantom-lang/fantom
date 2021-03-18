//
// Copyright (c) 2021, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 2021  Brian Frank  Creation
//

**
** Decodes a SVG file into an `Image`
**
@NoDoc @Js class SvgDecoder
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Creates a SVG decoder for the given stream. The stream will
  ** not be closed after decoding.
  new make(InStream in)
  {
    this.in = in
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** SVG mime type
  static const MimeType mime := MimeType("image/svg+xml")

  ** Returns true if Buf starts looks like XML
  static Bool isSvg(Buf buf)
  {
    if (buf[0] != '<') return false
    if (buf[1] == 's' && buf[2] == 'v' && buf[3] == 'g') return true
    if (buf[1] == '?' && buf[2] == 'x' && buf[3] == 'm' && buf[4] == 'l') return true
    return false
  }

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

  Image decode()
  {
    width  := 100f
    height := 100f

    // simple mechanism to get size from viewbox with parsing XML
    str := in.readAllStr
    attrName := "viewBox="
    attri := str.index(attrName)
    if (attri != null)
    {
      attri += attrName.size
      quote := str[attri]
      endi := str.index(quote.toChar, attri+1)
      val := str[attri..<endi]
      nums := val.split
      width = Float(nums[2])
      height = Float(nums[3])
    }

    return Image
    {
      it.mime  = SvgDecoder.mime
      it.size  = Size(width, height)
      it.props = Str:Obj[:]
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private InStream in
}

