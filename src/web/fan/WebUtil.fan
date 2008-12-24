//
// Copyright (c) 2007, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Jun 07  Brian Frank  Creation
//

**
** WebUtil encapsulates several useful utility web methods.
**
class WebUtil
{

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a list of comma separated tokens.  Any leading
  ** or trailing whitespace is trimmed from the list of tokens.
  **
  static Str[] parseList(Str s)
  {
    return s.split(',')
  }

  **
  ** Parse a series of HTTP headers according to RFC 2616 section
  ** 4.2.  The final CRLF which terminates headers is consumed with
  ** the stream positioned immediately following.  The headers are
  ** returned as a [case insensitive]`sys::Map.caseInsensitive` map.
  ** Throw ParseErr if headers are malformed.
  **
  static Str:Str parseHeaders(InStream in)
  {
    headers := Str:Str[:]
    headers.caseInsensitive = true
    Str? last := null

    // read headers into map
    while (true)
    {
      peek := in.peek

      // CRLF is end of headers
      if (peek == CR) break

      // if line starts with space it is
      // continuation of last header field
      if (peek.isSpace && last != null)
      {
        headers[last] += " " + in.readLine.trim
        continue
      }

      // key/value pair
      key := token(in, ':').trim
      val := token(in, CR).trim
      if (in.read != LF)
        throw ParseErr("Invalid CRLF line ending")

      // check if key already defined in which case
      // this is an append, otherwise its a new pair
      dup := headers[key]
      if (dup == null)
        headers[key] = val
      else
        headers[key] = dup + "," + val
      last = key
    }

    // consume final CRLF
    if (in.read != CR || in.read != LF)
      throw ParseErr("Invalid CRLF headers ending")

    return headers
  }

  **
  ** Read the next token from the stream up to the specified
  ** separator. We place a limit of 512 bytes on a single token.
  ** Consume the separate char too.
  **
  private static Str token(InStream in, Int sep)
  {
    // read up to separator
    tok := in.readStrToken(maxTokenSize) |Int ch->Bool| { return ch == sep }

    // sanity checking
    if (tok == null) throw IOErr("Unexpected end of stream")
    if (tok.size >= 512) throw ParseErr("Token too big")

    // read separator
    in.read

    return tok
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const static Int CR  := '\r'
  internal const static Int LF  := '\n'
  internal const static Int HT  := '\t'
  internal const static Int SP  := ' '
  internal const static Int maxTokenSize := 512

}

**************************************************************************
** ChunkInStream
**************************************************************************

internal class ChunkInStream : InStream
{
  new make(InStream in, Int? fixed := null) : super(null)
  {
    this.in = in
    this.isFixed  = (fixed != null)
    this.chunkRem = (fixed != null) ? fixed : -1
  }

  override Int? read()
  {
    if (pushback != null && !pushback.isEmpty) return pushback.pop
    if (!checkChunk) return null
    chunkRem -= 1
    return in.read
  }

  override Int? readBuf(Buf buf, Int n)
  {
    if (pushback != null && !pushback.isEmpty && n > 0)
    {
      buf.write(pushback.pop)
      return 1
    }
    if (!checkChunk) return null
    n = chunkRem.min(n)
    chunkRem -= n
    return in.readBuf(buf, n)
  }

  override This unread(Int b)
  {
    if (pushback == null) pushback = Int[,]
    pushback.push(b)
    return this
  }

  private Bool checkChunk()
  {
    try
    {
      // if we have bytes remaining in this chunk return true
      if (chunkRem > 0) return true

      // if this is a single fixed "chunk" we are at end of stream
      if (isFixed) return false

      // we expect \r\n unless this is first chunk
      if (chunkRem != -1 && !in.readLine.isEmpty) throw Err()

      // read the next chunk status line
      line := in.readLine
      semi := line.index(";")
      if (semi != null) line = line[0..semi]
      chunkRem = line.toInt(16)

      // if we have more chunks keep chugging,
      // otherwise read any trailing headers
      if (chunkRem > 0) return true
      WebUtil.parseHeaders(in)
      return false
    }
    catch throw IOErr("Invalid format for HTTP chunked stream")
  }

  InStream in         // underlying input stream
  Bool isFixed        // if non-null, then we're using as one fixed chunk
  Int chunkRem        // remaining bytes in current chunk (-1 for first chunk)
  Int[]? pushback     // stack for unread
}