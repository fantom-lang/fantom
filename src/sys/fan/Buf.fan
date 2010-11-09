//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Mar 06  Brian Frank  Creation
//

**
** Buf is used to model a block of bytes with random access.  Buf is
** typically backed by a block of memory, but can also be backed by
** a file:
**   - `Buf.make`: backed by RAM
**   - `File.open`: backed by random access file
**   - `File.mmap`: backed by memory mapped file
**
** Buf provides an `InStream` and `OutStream` to read and write into
** the buffer using a configurable position accessed via `Buf.pos`
** and `Buf.seek`.
**
** When using an InStream, bytes are read starting at pos where pos
** is advanced after each read.  The end of stream is reached when pos
** reaches size.  When using the OutStream, bytes are written starting at pos
** with pos advanced after each write.  If pos is less then size then
** the existing bytes are rewritten and size is not advanced, otherwise
** the buffer is automatically grown and size is advanced as bytes are
** appended.  It is common to write bytes into the buffer using the
** OutStream, then call `Buf.flip` to prepare the buffer to be used for reading.
**
class Buf
{

//////////////////////////////////////////////////////////////////////////
// Factory
//////////////////////////////////////////////////////////////////////////

  **
  ** Allocate a byte buffer in RAM with the initial given capacity.
  **
  static Buf make(Int capacity := 1024)

  **
  ** Generate a random series of bytes.
  **
  ** Example:
  **   Buf.random(8).toHex  => "d548b54989028b90"
  **
  static Buf random(Int size)

  **
  ** Buf cannot be subclassed outside of sys since we do
  ** much optimization under the covers in Java and C#.
  **
  internal new internalMake()

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Buf equality is based on reference equality using the === operator.
  **
  override Bool equals(Obj? that)

  **
  ** Return string summary of the buffer.
  **
  override Str toStr()

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if size() == 0.
  **
  Bool isEmpty()

  **
  ** Return the total number of bytes in the buffer.  If the size is
  ** set greater than capacity then the buffer's capacity is automatically
  ** grown, otherwise capacity remains the same.  Setting size does not
  ** actually change any bytes in the buffer.  A mmap buffer can never
  ** be increased from its initial size.
  **
  Int size

  **
  ** The number of bytes this buffer can hold without allocating more
  ** memory.  Capacity is always greater or equal to size.  If adding a
  ** large number of bytes, it may be more efficient to manually set
  ** capacity.  See the `trim` method to automatically set capacity to
  ** size.  Throw ArgErr if attempting to set capacity less than size.
  ** This method is ignored on a file buffer, and unsupported on mmap.
  **
  Int capacity

  **
  ** Return the current position for the next read or write.  The
  ** position is always between 0 and `size`.  If pos is less then
  ** size then future writes will rewrite the existing bytes without
  ** growing size.  Change the position with `seek`.
  **
  Int pos()

  **
  ** Return the remaining number of bytes to read: size-pos.
  **
  Int remaining()

  **
  ** Return if more bytes are available to read: remaining() > 0.
  **
  Bool more()

  **
  ** Set the current position to the specified byte offset.  A
  ** negative index may be used to access from the end of the buffer.
  ** For example seek(-1) is translated into seek(size-1).
  ** Return this.
  **
  This seek(Int pos)

  **
  ** Flip a buffer from write-mode to read-mode.  This method sets
  ** total size to current position, and position to 0.  Return this.
  **
  This flip()

  **
  ** Get the byte at the specified absolute index.  A negative index
  ** may be used to access from the end of the buffer.  For example
  ** get(-1)  is translated into get(size()-1).  This method accesses
  ** the buffer absolutely independent of current position.  The get
  ** method is accessed via the [] shortcut operator.  Throw IndexErr
  ** if index out of range.
  **
  @Operator Int get(Int index)

  **
  ** Return a new buffer containing the bytes in the specified absolute
  ** range.  Negative indexes may be used to access from the end of
  ** the buf.  This method accesses the buffer absolutely independent
  ** of current position.  This method is accessed via the [] operator.
  ** Throw IndexErr if range illegal.
  **
  ** Examples:
  **   buf := Buf.make
  **   buf.write(0xaa).write(0xbb).write(0xcc).write(0xdd)
  **   buf[0..2]   => 0x[aabbcc]
  **   buf[3..3]   => 0x[dd]
  **   buf[-2..-1] => 0x[ccdd]
  **   buf[0..<2]  => 0x[aabb]
  **   buf[1..-2]  => 0x[bbcc]
  **
  @Operator Buf getRange(Range range)

  ** TODO: use `getRange`
  @Deprecated Buf slice(Range range)

  **
  ** Create a new buffer in memory which deeply clones this buffer.
  **
  Buf dup()

//////////////////////////////////////////////////////////////////////////
// Modification
//////////////////////////////////////////////////////////////////////////

  **
  ** Set is used to overwrite the byte at the specified the index.  A
  ** negative index may be used to access an index from the end of the
  ** buffer.  The set method is accessed via the []= shortcut operator.
  ** Return this.  Throw IndexErr if index is out of range.
  **
  @Operator This set(Int index, Int byte)

  **
  ** Read the buffer for a fresh read by reseting the buffer's pos
  ** and size to zero.  The buffer's capacity remains the same.
  ** Return this.
  **
  This clear()

  **
  ** Trim the capacity such that the underlying storage is optimized
  ** for the current size.  Return this.
  **
  This trim()

  **
  ** If this buffer is backed by a file, then close it.  If a memory
  ** buffer then do nothing.  This method is guaranteed to never
  ** throw an IOErr.  Return true if the buffer was closed
  ** successfully or false if closed abnormally.
  **
  Bool close()

  **
  ** If this Buf is backed by a file, then force all changes
  ** to the storage device.  Throw IOErr on error.  Return this.
  **
  This flush()

  **
  ** Byte order mode for both OutStream and InStream.
  ** Default is `Endian.big` (network byte order).
  **
  Endian endian

  **
  ** Character set for both the OutStream and InStream.
  **
  Charset charset

  **
  ** Write the specified byte to the end of the buffer using given count.
  **
  ** Examples:
  **   Buf().fill(0xff, 4)  =>  0xffffffff
  **
  This fill(Int byte, Int times)

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the OutStream which writes to this buffer.
  ** This method always returns the same instance.
  ** If this buffer is backed by a file, then 'out.close'
  ** will not close the file - you must use `Buf.close`.
  **
  OutStream out()

  **
  ** Convenience for [out.write]`OutStream.write`
  ** Return this.
  **
  This write(Int byte)

  **
  ** Convenience for [out.writeBuf]`OutStream.writeBuf`
  ** Return this.
  **
  This writeBuf(Buf buf, Int n := buf.remaining)

  **
  ** Convenience for [out.writeI2]`OutStream.writeI2`
  ** Return this.
  **
  This writeI2(Int n)

  **
  ** Convenience for [out.writeI4]`OutStream.writeI4`
  ** Return this.
  **
  This writeI4(Int n)

  **
  ** Convenience for [out.writeI8]`OutStream.writeI8`
  ** Return this.
  **
  This writeI8(Int n)

  **
  ** Convenience for [out.writeF4]`OutStream.writeF4`
  ** Return this.
  **
  This writeF4(Float r)

  **
  ** Convenience for [out.writeF8]`OutStream.writeF8`
  ** Return this.
  **
  This writeF8(Float r)

  **
  ** Convenience for [out.writeDecimal]`OutStream.writeDecimal`
  ** Return this.
  **
  This writeDecimal(Decimal d)

  **
  ** Convenience for [out.writeBool]`OutStream.writeBool`
  ** Return this.
  **
  This writeBool(Bool b)

  **
  ** Convenience for [out.writeUtf]`OutStream.writeUtf`
  ** Return this.
  **
  This writeUtf(Str s)

  **
  ** Convenience for [out.writeChar]`OutStream.writeChar`
  ** Return this.
  **
  This writeChar(Int char)

  **
  ** Convenience for [out.writeChars]`OutStream.writeChars`
  ** Return this.
  **
  This writeChars(Str str, Int off := 0, Int len := str.size-off)

  **
  ** Convenience for [out.print]`OutStream.print`
  ** Return this.
  **
  This print(Obj? s)

  **
  ** Convenience for [out.printLine]`OutStream.printLine`
  ** Return this.
  **
  This printLine(Obj? obj := "")

  **
  ** Convenience for [out.writeProps]`OutStream.writeProps`
  ** Return this.
  **
  This writeProps(Str:Str props)

  **
  ** Convenience for [out.writeObj]`OutStream.writeObj`
  ** Return this.
  **
  This writeObj(Obj? obj, [Str:Obj]? options := null)

  **
  ** Convenience for [out.writeXml]`OutStream.writeXml`
  ** Return this.
  **
  This writeXml(Str s, Int flags := 0)

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the InStream which reads from this buffer.
  ** This method always returns the same instance.
  ** If this buffer is backed by a file, then 'in.close'
  ** will not close the file - you must use `Buf.close`.
  **
  InStream in()

  **
  ** Convenience for [in.read]`InStream.read`
  **
  Int? read()

  **
  ** Convenience for [in.readBuf]`InStream.readBuf`
  **
  Int? readBuf(Buf buf, Int n)

  **
  ** Convenience for [in.unread]`InStream.unread`
  ** Memory backed buffers support a stack based pushback model
  ** like IO streams.  File backed buffers will simply rewrite
  ** the last position in the file.  Return this.
  **
  This unread(Int b)

  **
  ** Convenience for [in.readAllBuf]`InStream.readAllBuf`
  **
  Buf readAllBuf()

  **
  ** Convenience for [in.readBufFully]`InStream.readBufFully`
  **
  Buf readBufFully(Buf? buf, Int n)

  **
  ** Convenience for [in.peek]`InStream.peek`
  **
  Int? peek()

  **
  ** Convenience for [in.readU1]`InStream.readU1`
  **
  Int readU1()

  **
  ** Convenience for [in.readS1]`InStream.readS1`
  **
  Int readS1()

  **
  ** Convenience for [in.readU2]`InStream.readU2`
  **
  Int readU2()

  **
  ** Convenience for [in.readS2]`InStream.readS2`
  **
  Int readS2()

  **
  ** Convenience for [in.readU4]`InStream.readU4`
  **
  Int readU4()

  **
  ** Convenience for [in.readS4]`InStream.readS4`
  **
  Int readS4()

  **
  ** Convenience for [in.readS8]`InStream.readS8`
  **
  Int readS8()

  **
  ** Convenience for [in.readF4]`InStream.readF4`
  **
  Float readF4()

  **
  ** Convenience for [in.readF8]`InStream.readF8`
  **
  Float readF8()

  **
  ** Convenience for [in.readDecimal]`InStream.readDecimal`
  **
  Decimal readDecimal()

  **
  ** Convenience for [in.readBool]`InStream.readBool`
  **
  Bool readBool()

  **
  ** Convenience for [in.readUtf]`InStream.readUtf`
  **
  Str readUtf()

  **
  ** Convenience for [in.readChar]`InStream.readChar`
  **
  Int? readChar()

  **
  ** Convenience for [in.unreadChar]`InStream.unreadChar`
  ** Memory backed buffers support a stack based pushback model
  ** like IO streams.  File backed buffers will simply rewrite
  ** the last position in the file.  Return this.
  **
  This unreadChar(Int b)

  **
  ** Convenience for [in.peekChar]`InStream.peekChar`
  **
  Int? peekChar()

  **
  ** Convenience for [in.readChars]`InStream.readChars`
  **
  Str readChars(Int n)

  **
  ** Convenience for [in.readLine]`InStream.readLine`
  **
  Str? readLine(Int? max := 4096)

  **
  ** Convenience for [in.readStrToken]`InStream.readStrToken`
  **
  Str? readStrToken(Int? max := 4096, |Int ch->Bool|? c := null)

  **
  ** Convenience for [in.readAllLines]`InStream.readAllLines`
  **
  Str[] readAllLines()

  **
  ** Convenience for [in.eachLine]`InStream.eachLine`
  **
  Void eachLine(|Str line| f)

  **
  ** Convenience for [in.readAllStr]`InStream.readAllStr`
  **
  Str readAllStr(Bool normalizeNewlines := true)

  **
  ** Convenience for [in.readProps]`InStream.readProps`
  **
  Str:Str readProps()

  **
  ** Convenience for [in.readObj]`InStream.readObj`
  **
  Obj? readObj([Str:Obj]? options := null)

//////////////////////////////////////////////////////////////////////////
// Conversions
//////////////////////////////////////////////////////////////////////////

  **
  ** Encode the buffer contents from 0 to size into a
  ** hexadecimal string.  This method is unsupported for
  ** mmap buffers.
  **
  ** Example:
  **   Buf.make.print("\r\n").toHex   => "0d0a"
  **   Buf.fromHex("0d0a").readAllStr => "\r\n"
  **
  Str toHex()

  **
  ** Decode the specified hexadecimal string into its binary
  ** contents.  Any characters which are not included in the
  ** set "0-9, a-f, A-F" are ignored as long as they appear
  ** between bytes (hi and lo nibbles must be contiguous).
  **
  ** Example:
  **   Buf.make.print("\r\n").toHex   => "0d0a"
  **   Buf.fromHex("0d0a").readAllStr => "\r\n"
  **
  static Buf fromHex(Str s)

  **
  ** Encode the buffer contents from 0 to size to a Base64
  ** string as defined by MIME RFC 2045.  No line breaks are
  ** added.  This method is only supported by memory backed
  ** buffers, file backed buffers will throw UnsupportedErr.
  **
  ** Example:
  **   Buf.make.print("Fan").toBase64    => "RmFu"
  **   Buf.fromBase64("RmFu").readAllStr => "Fan"
  **
  Str toBase64()

  **
  ** Decode the specified Base64 string into its binary contents
  ** as defined by MIME RFC 2045.  Any characters which are not
  ** included in the Base64 character set are safely ignored.
  **
  ** Example:
  **   Buf.make.print("Fan").toBase64    => "RmFu"
  **   Buf.fromBase64("RmFu").readAllStr => "Fan"
  **
  static Buf fromBase64(Str s)

  **
  ** Apply the specified message digest algorthm to this buffer's
  ** contents from 0 to size and return the resulting hash.  Digests
  ** are secure one-way hash functions which input an arbitrary sized
  ** buffer and return a fixed sized buffer.  Common algorithms include:
  ** "MD5", "SHA-1", and "SHA-256"; the full list supported is platform
  ** dependent.  On the Java VM, the algorithm maps to those avaialble
  ** via the 'java.security.MessageDigest' API.  Throw ArgErr if the
  ** algorithm is not available.  This method is unsupported for mmap
  ** buffers.
  **
  ** Example:
  **   Buf.make.print("password").print("salt").toDigest("MD5").toHex
  **    =>  "b305cadbb3bce54f3aa59c64fec00dea"
  **
  Buf toDigest(Str algorithm)

  **
  ** Generate an HMAC message authentication as specified by RFC 2104.
  ** This buffer is the data input, 'algorithm' specifies the hash digest,
  ** and 'key' represents the secret key:
  **   - 'H': specified by algorthim parameter - "MD5" or "SHA1"
  **   - 'K': secret key specified by key parameter
  **   - 'B': fixed at 64
  **   - 'text': this instance
  **
  ** The HMAC is computed using:
  **   ipad = the byte 0x36 repeated B times
  **   opad = the byte 0x5C repeated B times
  **   H(K XOR opad, H(K XOR ipad, text))
  **
  ** Throw ArgErr if the algorithm is not available.  This method is
  ** only supported for memory buffers.
  **
  ** Examples:
  **   "hi there".toBuf.hmac("MD5", "secret".toBuf)
  **
  Buf hmac(Str algorithm, Buf key)

}

**************************************************************************
** MemBuf
**************************************************************************

internal class MemBuf : Buf
{
  private new init()
}

**************************************************************************
** FileBuf
**************************************************************************

internal class FileBuf : Buf
{
  private new init()
}

**************************************************************************
** MmapBuf
**************************************************************************

internal class MmapBuf : Buf
{
  private new init()
}