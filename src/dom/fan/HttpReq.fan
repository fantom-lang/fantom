//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09  Andy Frank  Creation
//   8 Jul 09  Andy Frank  Split webappClient into sys/dom
//

**
** HttpReq models the request side of an XMLHttpRequest instance.
**
** See [pod doc]`pod-doc#xhr` for details.
**
@Js
class HttpReq
{

  **
  ** Create a new HttpReq instance.
  **
  new make(|This|? f)
  {
    if (f != null) f(this)
  }

  **
  ** The Uri to send the request.
  **
  Uri uri := `#`

  **
  ** The request headers to send.
  **
  Str:Str headers := Str:Str[:]

  **
  ** If true then perform this request asynchronously.
  ** Defaults to 'true'
  **
  Bool async := true

  **
  ** Send a request with the given content using the given
  ** HTTP method (case does not matter).  After receiving
  ** the response, call the given closure with the resulting
  ** HttpRes object.
  **
  native Void send(Str method, Str content, |HttpRes res| c)

  **
  ** Convenience for 'send("GET", "", c)'.
  **
  Void get(|HttpRes res| c)
  {
    send("GET", "", c)
  }

  **
  ** Convenience for 'send("POST", content, c)'.
  **
  Void post(Str content, |HttpRes res| c)
  {
    send("POST", content, c)
  }

  **
  ** Post the 'form' map as a HTML form submission.  Formats
  ** the map into a valid url-encoded content string, and sets
  ** 'Content-Type' header to 'application/x-www-form-urlencoded'.
  **
  Void postForm(Str:Str form, |HttpRes res| c)
  {
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    send("POST", encodeForm(form), c)
  }

  **
  ** Encode the form map into a value URL-encoded string.
  **
  private native Str encodeForm(Str:Str form)

}