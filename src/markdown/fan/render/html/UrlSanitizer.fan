//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

**
** Sanitizes uris for img and a elements by whitelisting protocols.
** This is intended to prevent XSS payloads like
**    [Click this totally safe url](javascript:document.xss=true;)
**
** Implementation based on https://github.com/OWASP/java-html-sanitizer/blob/f07e44b034a45d94d6fd010279073c38b6933072/src/main/java/org/owasp/html/FilterUrlByProtocolAttributePolicy.java
**
@Js
const mixin UrlSanitizer
{
  ** Sanitize a url for use in the href attribute of a Link
  abstract Str sanitizeLink(Str url)

  ** Sanitize a url for use in the src attribute of a Image
  virtual Str sanitizeImage(Str url) { sanitizeLink(url) }
}

**************************************************************************
** DefaultUrlSanitizer
**************************************************************************

**
** Allows http, https, mailto, and data protocols for url.
** Also allows protocol relative urls, and relative urls.
**
@Js
internal const class DefaultUrlSanitizer : UrlSanitizer
{
  new make_default() : this.make(["http", "https", "mailto", "data"]) { }

  new make(Str[] protocols)
  {
    this.protocols = protocols
  }

  const Str[] protocols

  override Str sanitizeLink(Str url)
  {
    // I actually simplified this implementation since Fantom has Uri type
    // uri = `${stripHtmlSpaces(uri.toStr)}`
    uri := url.toUri
    if (uri.scheme == null) return url
    return protocols.contains(uri.scheme) ? url : ""
  }

  /*
  private Str stripHtmlSpaces(Str s)
  {
    i := 0
    n := s.size
    for (; n > i; --n)
    {
      if (!isHtmlSpace(s[n-1])) break
    }
    for (; i < n; ++i)
    {
      if (!isHtmlSpace(s[i])) break
    }
    if (i == 0 && n == s.size) return s
    return s[i..<n]
  }

  private Bool isHtmlSpace(Int ch)
  {
    switch (ch)
    {
      case ' ':
      case '\t':
      case '\n':
      case '\u000c':
      case '\r':
        return true
      default:
        return false
    }
  }
  */
}