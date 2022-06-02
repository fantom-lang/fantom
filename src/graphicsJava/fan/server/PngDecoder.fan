//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jun 2017  Matthew Giannini  Creation
//

using concurrent
using graphics

**
** Decodes a PNG file into a ServerImage
**
internal class PngDecoder
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Creates a PNG decoder for the given stream. The stream will
  ** not be closed after decoding.
  new make(Uri uri, InStream in)
  {
    this.uri = uri
    this.in = in
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** PNG magic number
  static const Int magic := 0x89_50_4e_47_0d_0a_1a_0a

  ** Returns true if Buf starts with `magic` number.
  ** The buf is not modified.
  static Bool isPng(Buf buf) { magic == buf[0..<8].readS8 }

//////////////////////////////////////////////////////////////////////////
// Decode
//////////////////////////////////////////////////////////////////////////

  ServerImage decode()
  {
    // verify magic
    if (magic != in.readS8) throw IOErr("Missing magic")
    data := Buf()
    while (true)
    {
      len  := in.readU4
      type := in.readChars(4)
      data  = in.readBufFully(data.clear, len)
      crc  := in.readU4
      switch (type)
      {
        case "IHDR": readImageHeader(data)
        case "PLTE": readPalette(data)
        case "IDAT": readImageData(data)
        case "tRNS": readTransparency(data)
        case "IEND": break
      }
    }
    return toImage
  }

  private ServerPngImage toImage()
  {
    ServerPngImage {
      it.uri = this.uri
      it.mime = Image.mimePng
      it.size = Size(width, height)
      it.props = [
        "colorType":       this.colorType,
        "colorSpace":      this.colorSpace,
        "colorSpaceBits":  isIndexedColor ? 8 : bitDepth,
        "interlaceMethod": this.interlaceMethod,
        "palette":         this.palette.flip,
        "transparency":    this.transparency.flip,
        "imgData":         this.imgData.flip,
      ].toImmutable
    }
  }

  private Void readImageHeader(Buf data)
  {
    this.width  = data.readU4
    if (width <= 0) throw IOErr("Invalid width: $width")

    this.height = data.readU4
    if (height <= 0) throw IOErr("Invalid height: $height")

    this.bitDepth  = data.readU1
    this.colorType = data.readU1

    compressionMethod := data.readU1
    if (compressionMethod != 0) throw IOErr("Invalid compression method: $compressionMethod")

    filterMethod := data.readU1
    if (filterMethod != 0) throw IOErr("Invalid filter method: $filterMethod")

    this.interlaceMethod = data.readU1
    if (interlaceMethod > 1) throw IOErr("Invalid interlace method: $interlaceMethod")
  }

  private Void readPalette(Buf data)
  {
    if (data.size % 3 != 0) throw IOErr("Invalid palette data size: ${data.size}")
    palette.writeBuf(data)
  }

  private Void readImageData(Buf data)
  {
    imgData.writeBuf(data)
  }

  private Void readTransparency(Buf data)
  {
    transparency.writeBuf(data)
    if (colorType == 3)
      transparency.fill(255, palette.size - transparency.size)
  }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  ** Is there a palette index
  private Bool isIndexedColor() { colorType == 3 }

  private Str colorSpace()
  {
    switch (colorType)
    {
      case 0: return "Gray"
      case 2: return "RGB"
      case 3: return "RGB"  // palette index
      case 4: return "Gray" // with alpha
      case 6: return "RGB"  // with alpha
    }
    throw IOErr("Invalid color type: $colorType")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Uri uri
  private InStream in
  private Str:Obj props := [:]

  // IHDR
  private Int? width
  private Int? height
  private Int? bitDepth
  private Int? colorType
  private Int? interlaceMethod

  // PLTE
  private Buf palette := Buf()

  // tRNS
  ** simple transparency alpha channel
  private Buf transparency := Buf()

  // IDAT
  ** Concatenation of all IDAT *compressed* data chunks.
  private Buf imgData := Buf()
}

**************************************************************************
** PngImage
**************************************************************************

internal const class ServerPngImage : ServerImage, PngImage
{
  new make(|This| f) : super(f) { }

  override Buf pixels()
  {
    if (pixelsRef.val != null) return pixelsRef.val

    data := Zip.deflateInStream(imgData.in).readAllBuf
    pixelBytes  := pixelBits / 8
    scanLineLen := pixelBytes * size.w.toInt
    numPixels   := scanLineLen * size.h.toInt
    pixels      := Buf(numPixels)
    row         := 0
    while (data.more)
    {
      filter := data.read
      (0..<scanLineLen).each |i|
      {
        // None
        if (0 == filter) return pixels.write(data.read)

        byte  := data.read
        col   := (i - (i % pixelBytes)) / pixelBytes
        left  := i < pixelBytes ? 0 : pixels[pixels.size - pixelBytes]
        upper := row == 0 ? 0 : pixels[((row - 1) * scanLineLen) + (col * pixelBytes) + (i % pixelBytes)]
        upperLeft := row == 0 || col == 0 ? 0 : pixels[((row - 1) * scanLineLen) + ((col - 1) * pixelBytes) + (i % pixelBytes)]

        Int? val := null
        switch (filter)
        {
          case 1: // Sub
            val = byte + left
          case 2: // Up
            val = upper + byte
          case 3: // Avg
            val = (byte + ((left + upper).toFloat / 2f).floor.toInt)
          case 4: // Paeth
            p  := left + upper - upperLeft
            pa := (p - left).abs
            pb := (p - upper).abs
            pc := (p - upperLeft).abs

            paeth := upperLeft
            if (pa <= pb && pa <= pc)
              paeth = left
            else if (pb <= pc)
              paeth = upper

            val = byte + paeth
        }
        pixels.write(val % 256)
      }
      ++row
    }

    pixelsRef.val = pixels.flip.toImmutable
    return pixelsRef.val
  }
  private const AtomicRef pixelsRef := AtomicRef(null)
}

