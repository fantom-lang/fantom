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
@serializable
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
    if (Actor.locals["webapp.widget.head"] != null)
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
      Actor.locals["webapp.widget.head"] = WebOutStream(head.out)
      Actor.locals["webapp.widget.body"] = WebOutStream(body.out)

      // write content
      res.headers["Content-Type"] = "text/html; charset=UTF-8"
      q := req.uri.query["webappWidgetCall"]
      if (q != null)
      {
        m := Slot.findMethod(q)
        if (!m.parent.fits(Widget#))
          throw ArgErr("Type not Widget: $m.parent")
        m.parent.make()->onCall(m)
      }
      else
      {
        startRes
        super.service
        finishRes
      }

      // flush streams
      if (!res.isCommitted)
      {
        res.headers["Content-Length"] = (head.size + body.size).toStr
        res.out.writeBuf(head.flip)
        res.out.writeBuf(body.flip)
      }
    }
    finally
    {
      // remove thread locals
      Actor.locals.remove("webapp.widget.head")
      Actor.locals.remove("webapp.widget.body")
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
    buf := Actor.locals["webapp.widget.head"] as WebOutStream
    if (buf == null) throw Err("Widget.head not found")
    return buf
  }

  **
  ** The buffered WebOutStream for the <body> element.
  **
  once WebOutStream body()
  {
    buf := Actor.locals["webapp.widget.body"] as WebOutStream
    if (buf == null) throw Err("Widget.body not found")
    return buf
  }

  **
  ** Return a Uri that can be used to call a specific method
  ** on a Widget, bypassing the normal 'service' implementation.
  **
  Uri call(Method m, Uri uri := req.uri)
  {
    if (!m.parent.fits(Widget#))
      throw ArgErr("Type must be Widget: $m.parent")

    return uri.plusQuery(["webappWidgetCall":m.qname])
  }

  **
  ** Return a new Uri that removes the 'Widget.call' specifics
  ** from the given Uri.
  **
  Uri minusCall(Uri uri)
  {
    path  := uri.pathStr
    query := uri.query.rw
    query.remove("webappWidgetCall")
    return path.toUri.plusQuery(query)
  }

  **
  ** Handle invoking a method requested using a Uri from 'Widget.call'.
  **
  virtual Void onCall(Method m)
  {
    m.call1(this)
  }

  **
  ** Return a name that is unique to this web request.  The name
  ** returned can be used as a valid HTML name or id attribute, as
  ** well as a JavaScript variable name.
  **
  Str unique()
  {
    Int last := Actor.locals.get("webapp.widget.unique", -1)
    Actor.locals["webapp.widget.unique"] = ++last
    return "n$last"
  }

}