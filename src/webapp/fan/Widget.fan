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
@serializable @collection
abstract class Widget : Weblet
{

//////////////////////////////////////////////////////////////////////////
// Widget Tree
//////////////////////////////////////////////////////////////////////////

  **
  ** Get this widget's parent or null if not mounted.
  **
  @transient readonly Widget? parent

  **
  ** The unique name for this widget within the parent, or
  ** null if this widget is not mounted.
  **
  @transient readonly Str? name

  **
  ** Iterate the children widgets.
  **
  Void each(|Widget w, Int i| f)
  {
    kids.each(f)
  }

  **
  ** Get the children widgets.
  **
  Widget[] children() { return kids.ro }

  **
  ** Return the child Widget with the given name, or
  ** null if one does not exist.
  **
  Widget? get(Str name)
  {
    return kids.find |Widget w->Bool| { return w.name == name }
  }

  **
  ** Add a child widget.  If child is null, then do nothing.
  ** If child is already parented throw ArgErr.  Return this.
  **
  virtual This add(Widget child)
  {
    if (child == null) return this
    if (child.parent != null)
      throw ArgErr("Child already parented: $child")
    child.parent = this
    child.name = "w" + nextId++
    kids.add(child)
    return this
  }

  **
  ** Remove a child widget.  If child is null, then do
  ** nothing.  If this widget is not the child's current
  ** parent throw ArgErr.  Return this.
  **
  virtual This remove(Widget child)
  {
    if (child == null) return this
    if (kids.removeSame(child) == null)
      throw ArgErr("not my child: $child")
    child.name = null
    return this
  }

  **
  ** Remove all child widgets.  Return this.
  **
  virtual This removeAll()
  {
    kids.dup.each |Widget kid| { remove(kid) }
    return this
  }

  **
  ** Return the uri to this Widget from the base widget,
  ** or null if this widget is not mounted.
  **
  Uri? uri()
  {
    if (name == null) return null
    path := Str[,]
    w := this
    while (w != null && w.name != null)
    {
      path.add(w.name)
      w = w.parent
    }
    return ("/" + path.reverse.join("/")).toUri
  }

  **
  ** Return the Widget with the given Uri, or null
  ** if one cannot be found.
  **
  Widget? find(Uri uri)
  {
    w := this
    path := uri.path
    for (i:=0; i<path.size; i++)
    {
      w = w.get(path[i])
      if (w == null) return null
    }
    return w
  }

//////////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////////

  **
  ** Return the Uri used to invoke the given function. 'func'
  ** must be a Str or a Method type:
  **
  **   toInvoke(&onPost)
  **   toInvoke("onPost")
  **
  ** The Uri required to invoke functions follows the form:
  **
  **   req.uri.plusQuery(["invoke":"$uri/$name"])
  **
  Uri toInvoke(Obj func)
  {
    Str name := null
    if (func is Func && func->method != null)
    {
      name = (func as Func).method.name
    }
    else if (func is Str)
    {
      name = func as Str
    }
    else
    {
      throw ArgErr("func must be Method or Str: $func.type")
    }
    uri := uri
    if (uri == null) throw Err("Widget not mounted")
    return req.uri.plusQuery(["invoke":"$uri/$name"])
  }

  **
  ** Invoke the Func defined by 'name'.  The default
  ** implemenation will invoke the method on this Type
  ** with the given name.
  **
  virtual Void invoke(Str name)
  {
    type.method(name).call1(this)
  }

//////////////////////////////////////////////////////////////////////////
// Weblet
//////////////////////////////////////////////////////////////////////////

  **
  ** Handle configuring the inital Widget pipeline.  To allow
  ** Widgets to be nested, we use two thread local Bufs to capture
  ** the output for the '<head>' and '<body>' tags separately.
  ** After the request has been serviced, we flush the Bufs to the
  ** actual output stream via `complete`.
  **
  ** If this method is called again (on any instance) after the
  ** initial call, it short-circuits and simply calls the default
  ** `web::Weblet.service` implemenation.
  **
  override Void service()
  {
    // if service has already been called on this thread
    // then just route to the default implemenation
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

      // add locals
      Thread.locals["webapp.widget.head"] = WebOutStream(head.out)
      Thread.locals["webapp.widget.body"] = WebOutStream(body.out)

      // verify flash exists
      if (req.session["webapp.widget.flash"] == null)
        req.session["webapp.widget.flash"] = Str:Obj[:]

      // if func exist, then invoke, otherwise route to super
      func := req.uri.query["invoke"]?.toUri
      if (req.method == "POST" && func != null)
      {
        try
          w := find(func[0..-2])->invoke(func.name)
        catch (Err e)
          throw Err("Could not invoke $func", e)
      }
      else
      {
        super.service
      }

      // complete request
      complete(head, body)
    }
    finally
    {
      // clear flash on gets
      if (req.method == "GET") flash.clear

      // remove locals
      Thread.locals.remove("webapp.widget.head")
      Thread.locals.remove("webapp.widget.body")
    }
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  **
  ** The buffered WebOutStream for the <head> element.
  **
  once WebOutStream head()
  {
    return Thread.locals["webapp.widget.head"] as WebOutStream
  }

  **
  ** The buffered WebOutStream for the <body> element.
  **
  once WebOutStream body()
  {
    return Thread.locals["webapp.widget.body"] as WebOutStream
  }

  **
  ** A short-term map that only exists for a single GET request,
  ** and is then automatically cleaned up.  It is convenient for
  ** passing notifications following a POST.
  **
  Str:Obj? flash()
  {
    return req.session["webapp.widget.flash"] as Str:Obj?
  }

  **
  ** Complete the current request by flushing the 'head' and 'body'
  ** Bufs to the actual response OutStream.  If the current request
  ** is a GET, this method is responsible for adding the appropriate
  ** markup to make the resulting HTML a valid page.
  **
  virtual Void complete(Buf head, Buf body)
  {
    // if the response is already committed, assume this is
    // an error or redirect, in which case, we don't need to
    // deal with the buffers
    if (res.isCommitted) return

    get := req.method == "GET"
    if (get)
    {
      // TODO - we need to get our charset without calling 'out'
      // which flushes the headers, so we can't set them after!
      charset := "UTF-8" //res.out.charset.name
      res.headers["Content-Type"] = "text/html; charset=$charset"
      res.headers["Content-Encoding"] = charset
      res.out.docType
      res.out.html
      res.out.head
      res.out.printLine("<meta http-equiv='Content-Type' content='text/html; charset=$charset'/>")
    }
    res.out.writeBuf(head.flip)
    if (get)
    {
      res.out.headEnd
      res.out.body
    }
    res.out.writeBuf(body.flip)
    if (get)
    {
      res.out.bodyEnd
      res.out.htmlEnd
    }
  }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  private Widget[] kids := Widget[,]
  private Int nextId := 0

}
