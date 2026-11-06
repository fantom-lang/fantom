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
**
**      [Click this totally safe url](javascript:document.xss=true;)
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
    uri := url.toUri
    if (uri.scheme == null) return url
    return protocols.contains(uri.scheme) ? url : ""
  }
}
