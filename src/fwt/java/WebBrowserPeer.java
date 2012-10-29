//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import org.eclipse.swt.*;
import org.eclipse.swt.browser.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;

public class WebBrowserPeer
  extends WidgetPeer
  implements LocationListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static WebBrowserPeer make(fan.fwt.WebBrowser self)
    throws Exception
  {
    WebBrowserPeer peer = new WebBrowserPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    Browser b = new Browser((Composite)parent, 0);
    control = b;
    b.addLocationListener(this);
    if (loadUri != null) load((WebBrowser)self, loadUri);
    else if (loadStr != null) loadStr((WebBrowser)self, loadStr);
    return b;
  }

//////////////////////////////////////////////////////////////////////////
// Commands
//////////////////////////////////////////////////////////////////////////

  public WebBrowser load(WebBrowser self, Uri uri)
  {
    Browser b = (Browser)this.control;
    if (b == null) { loadUri = uri; return self; }
    explicitLoad = true;
    try
    {
      b.setUrl(uri.toString());
      return self;
    }
    finally
    {
      explicitLoad = false;
    }
  }

  public WebBrowser loadStr(WebBrowser self, String html)
  {
    Browser b = (Browser)this.control;
    if (b == null) { loadStr = html; return self; }
    explicitLoad = true;
    try
    {
      b.setText(html);
      return self;
    }
    finally
    {
      explicitLoad = false;
    }
  }

  public WebBrowser refresh(WebBrowser self)
  {
    Browser b = (Browser)this.control;
    if (b != null) b.refresh();
    return self;
  }

  public WebBrowser stop(WebBrowser self)
  {
    Browser b = (Browser)this.control;
    if (b != null) b.stop();
    return self;
  }

  public WebBrowser back(WebBrowser self)
  {
    Browser b = (Browser)this.control;
    if (b != null) b.back();
    return self;
  }

  public WebBrowser forward(WebBrowser self)
  {
    Browser b = (Browser)this.control;
    if (b != null) b.forward();
    return self;
  }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public void changing(LocationEvent event)
  {
    // don't handle event if load() called
    if (explicitLoad) return;

    // map to a Uri, this is a bit hacky, but it appears that links
    // on local file system give us back an OS path instead of a URI;
    // we need to handle the Windows case of "c:\..." since the drive
    // will be interpretted as a scheme
    String loc = event.location;
    if (loc.startsWith("file:///")) loc = "file:/" + loc.substring(8);
    if (loc.startsWith("file://"))  loc = "file:/" + loc.substring(7);
    Uri uri = Uri.fromStr(loc);
    if (uri.scheme() == null || uri.scheme().length() == 1)
      uri = File.os(loc).normalize().uri();

    fan.fwt.WebBrowser self = (fan.fwt.WebBrowser)this.self;
    fan.fwt.Event fe = event(EventId.hyperlink, uri);
    self.onHyperlink().fire(fe);
    if (fe.data == null)
    {
      event.doit = false;
    }
    else
    {
      event.doit = true;
      event.location = fe.data.toString();
    }
  }

  public void changed(LocationEvent event)
  {
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Uri loadUri;
  String loadStr;
  boolean explicitLoad;
}