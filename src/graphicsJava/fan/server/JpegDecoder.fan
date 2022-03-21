//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 2017  Matthew Giannini  Creation
//

using graphics

**
** Decodes a JPEG file into a ServerImage.
**
** Only the SOF frame is currently decoded. This frame contains the necessary
** information to construct the Image.
**
internal class JpegDecoder
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Create a JPEG decoder for the given stream. The stream will
  ** not be closed after decoding.
  new make(Uri uri, InStream in)
  {
    this.uri = uri
    this.in = in
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** JPEG magic number
  static const Int magic := 0xff_d8

  ** Returns true if Buf starts with `magic` number.
  ** The buf is not modified.
  static Bool isJpeg(Buf buf) { magic == buf[0..<2].readU2() }

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

  ** Decode the Image. Throws IOErr if the JPEG is not properly formatted.
  ServerImage decode()
  {
    // verify magic
    if (magic != in.readU2()) throw IOErr("Missing SOI")

    while (true)
    {
      m := readMarker
      if (app0 == m) readApp0
      else if (sof_markers.contains(m)) return readSof
      else skipSegment
    }
    throw IOErr("Invalid JPEG")
  }

  ** Read APP0 segment. Check contents to see if this JPEG is
  ** is in the JPEG File Interchange Format (JFIF)
  private Void readApp0()
  {
    // read entire APP0 segment
    len := in.readU2
    seg := readSegment(len - 2)
    try
    {
      this.isJFIF = "JFIF\u0000" == seg.readChars(5)
      // Ignore rest of JFIF segment
    }
    catch (IOErr e)
    {
      // Not JFIF
      this.isJFIF = false
    }
  }

  ** Read SOF frame.
  private ServerImage readSof()
  {
    // Image properties
    Str:Obj props := Str:Obj[:]

    // Parse SOF frame
    frameLen      := in.readU2()
    bitsPerSample := in.readU1()
    height        := in.readU2()
    width         := in.readU2()
    numComps      := in.readU1()

    // verify
    if (height <= 0) throw IOErr("Invalid height: $height")
    if (width <= 0)  throw IOErr("Invalid width: $width")
    if (frameLen != 8 + (3 * numComps)) throw IOErr("Invalid SOF frame length: $frameLen")

    // build image
    size := Size.makeInt(width, height)
    props["colorSpace"]     = toColorSpace(numComps)
    props["colorSpaceBits"] = bitsPerSample

    return ServerImage {
      it.uri   = this.uri
      it.mime  = Image.mimeJpeg
      it.size  = size
      it.props = props.toImmutable
    }
  }

  ** Get the color space name based on the number of components
  private Str toColorSpace(Int numComps)
  {
    switch (numComps)
    {
      case 1: return "Gray"
      case 3: return isJFIF ? "YCbCr" : "RGB"
      case 4: return "CMYK"
    }
    throw IOErr("Unsupported color space for $numComps components")
  }

  ** Skip a segment. The 2-byte marker has already been read. The next
  ** 2 bytes are the length of the segment (including the 2 bytes of length).
  private Void skipSegment()
  {
    len := in.readU2
    in.readBufFully(null, len-2)
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  ** Read the next 2 bytes and verify that it is a marker.
  ** The 2-byte marker is returned (0xFF_<id>)
  private Int readMarker()
  {
    m := in.readU2
    if (!isMarker(m)) throw IOErr("expected marker, got ${m.toHex(4)}")
    return m
  }

  ** Return true if the given 2-byte word is a marker
  private Bool isMarker(Int word)
  {
    high := word.and(0xffff).shiftr(8)
    if (high != 0xff) return false

    low := word.and(0xff)
    if (low == 0x00 || low == 0xff) return false

    return true
  }

  ** Read len bytes from the input stream into and return the Buf
  ** with the position set to zero (ready to read).
  private Buf readSegment(Int len)
  {
    segment := Buf()
    in.readBuf(segment, len)
    return segment.flip
  }

//////////////////////////////////////////////////////////////////////////
// Markers
//////////////////////////////////////////////////////////////////////////

  ** APP0
  private static const Int app0 := 0xff_e0

  ** SOF frame markers
  private const Int[] sof_markers := [
    0xff_c0, 0xff_c1, 0xff_c2, 0xff_c3, // non-differential, Huffman coding
    0xff_c5, 0xff_c6, 0xff_c7,          // differential, Huffman coding
    0xff_c9, 0xff_ca, 0xff_cb,          // non-differential, arithmetic coding
    0xff_cd, 0xff_ce, 0xff_cf,          // differential, arithmetic coding
  ]

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Uri uri
  private InStream in
  private Bool isJFIF := false
}