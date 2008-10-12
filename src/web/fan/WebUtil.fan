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
      if (peek === CR) break

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
    if (in.read !== CR || in.read !== LF)
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