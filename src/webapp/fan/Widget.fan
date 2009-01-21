//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   18 Mar 08  Andy Frank  Creation
//

using web

**
** Widget is the base class for all web-based UI widgets.
**
** See `docLib::WebWidget`
**
abstract class Widget : Weblet
{

  **
  ** Handle configuring the inital Widget pipeline.  To allow
  ** Widgets to be nested, we use two thread local Bufs to capture
  ** the output for the '<head>' and '<body>' tags separately.
  ** After the request has been serviced, we flush the Bufs to the
  ** actual output stream.
  **
  ** If this method is called again (on any instance) after the
  ** initial call, it short-circuits and simply calls the default
  ** `web::Weblet.service` implementation.
  **
  override Void service()
  {
    // if service has already been called on this thread
    // then just route to the default implementation
    if (Thread.locals["webapp.widget.head"] != null)
    {
      super.service
      return
    }

    try
    {
      // create bufs
      head := Buf(1024)
      body := Buf(8192)

      // add thread locals
      Thread.locals["webapp.widget.head"] = WebOutStream(head.out)
      Thread.locals["webapp.widget.body"] = WebOutStream(body.out)

      // write content
      res.headers["Content-Type"] = "text/html; charset=utf8"
      startRes
      super.service
      finishRes

      // flush streams
      res.headers["Content-Length"] = (head.size + body.size).toStr
      res.out.writeBuf(head.flip)
      res.out.writeBuf(body.flip)
    }
    finally
    {
      // remove thread locals
      Thread.locals.remove("webapp.widget.head")
      Thread.locals.remove("webapp.widget.body")
    }
  }

  **
  ** Start the response.  For HTML pages, this method is
  ** responsible for creating the markup up to and including
  ** the starting '<head>' and '<body>' tags in their
  ** respective buffers.
  **
  virtual Void startRes()
  {
    if (req.method == "GET")
    {
      head.docType
      head.html
      head.head
      body.body
    }
  }

  **
  ** Finish the response.  For HTML pages, this method is
  ** responsible for writing the ending '<head>' and '<body>'
  ** tags in the respective buffers.
  **
  virtual Void finishRes()
  {
    if (req.method == "GET")
    {
      head.headEnd
      body.bodyEnd
      body.htmlEnd
    }
  }

  **
  ** The buffered WebOutStream for the <head> element.
  **
  once WebOutStream head()
  {
    buf := Thread.locals["webapp.widget.head"] as WebOutStream
    if (buf == null) throw Err("Widget.head not found")
    return buf
  }

  **
  ** The buffered WebOutStream for the <body> element.
  **
  once WebOutStream body()
  {
    buf := Thread.locals["webapp.widget.body"] as WebOutStream
    if (buf == null) throw Err("Widget.body not found")
    return buf
  }

}