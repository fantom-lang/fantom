//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Jun 08  Andy Frank  Creation
//

using Fan.Sys;
using System.Drawing;
using System.Windows.Forms;

//using System.Collections;
//using System.Diagnostics;
//using System.Drawing;
//using System.Drawing.Drawing2D;
//using System.IO;
//using System.Runtime.InteropServices;
//using System.Windows.Forms;

namespace Fan.Fwt
{
  /// <summary>
  /// Native methods for Widget.
  /// </summary>
  public abstract class WidgetPeer
  {

  //////////////////////////////////////////////////////////////////////////
  // Constructor
  //////////////////////////////////////////////////////////////////////////

    public static WidgetPeer make(Widget self)
    {
      System.Type type = System.Type.GetType("Fan.Fwt." + self.type().name().val + "Peer");
      WidgetPeer peer = (WidgetPeer)System.Activator.CreateInstance(type);
      peer.m_self = self;
      return peer;
    }

  //////////////////////////////////////////////////////////////////////////
  // Layout
  //////////////////////////////////////////////////////////////////////////

    public Point pos(Widget self)
    {
      //if (control == null) return pos;
      //Point p = control.getLocation();
      //return fan.fwt.Point.make(Long.valueOf(p.x), Long.valueOf(p.y));
      return null;
    }

    public void pos(Widget self, Fan.Fwt.Point pos)
    {
      //if (control == null) { this.pos = pos; return; }
      //control.setLocation((int)pos.x.val, (int)pos.y.val);
    }

    public Size size(Widget self)
    {
      if (m_control == null) return m_size;
      return Size.make(Long.valueOf(m_control.Size.Width), Long.valueOf(m_control.Size.Height));
    }

    public void size(Widget self, Fan.Fwt.Size size)
    {
      if (m_control == null) { this.m_size = size; return; }
      m_control.Size = new System.Drawing.Size((int)size.m_w.val, (int)size.m_h.val);
    }

    public Rect bounds(Widget self)
    {
      if (m_control == null) return Rect.make(m_pos.m_x, m_pos.m_y, m_size.m_w, m_size.m_h);
      Rectangle b = m_control.Bounds;
      return Rect.make(Long.valueOf(b.X), Long.valueOf(b.Y), Long.valueOf(b.Width), Long.valueOf(b.Height));
    }

    public void bounds(Widget self, Rect b)
    {
      if (m_control == null) { m_pos = b.pos(); m_size = b.size(); return; }
      m_control.Bounds = new Rectangle((int)b.m_x.val, (int)b.m_y.val, (int)b.m_w.val, (int)b.m_h.val);
    }

  //////////////////////////////////////////////////////////////////////////
  // Attachment
  //////////////////////////////////////////////////////////////////////////

    public Boolean attached(Widget self)
    {
      return m_control != null ? Boolean.True : Boolean.False;
    }

    public void attach(Widget self)
    {
      // short circuit if I'm already attached
      if (m_control != null) return;

      // short circuit if my parent isn't attached
      Widget parentWidget = self.parent();
      if (parentWidget == null || parentWidget.m_peer.m_control == null) return;

      // create control and initialize
      attachTo(create(parentWidget.m_peer.m_control));
    }

    internal void attachTo(Control control)
    {
      // sync with native control
      this.m_control = control;
      if (m_pos != Fan.Fwt.Point.m_def) pos(m_self, m_pos);
      if (m_size != Fan.Fwt.Size.m_def) size(m_self, m_size);
      sync(null);

      // recursively attach my children
      List kids = m_self.m_kids;
      for (int i=0; i<kids.sz(); ++i)
      {
        Widget kid = (Widget)kids.get(i);
        kid.m_peer.attach(kid);
      }
    }

    public abstract Control create(Control parent);

    public void detach(Widget self)
    {
      if (m_control == null) return;
      m_control.Dispose();
      m_control = null;
    }

  //////////////////////////////////////////////////////////////////////////
  // Widget/Control synchronization
  //////////////////////////////////////////////////////////////////////////

    public void sync(Widget self, string id)
    {
      if (m_control == null) return;
      sync(id);
    }

    public abstract void sync(string id);

    public object send(Widget self, string id)
    {
      return send(id);
    }

    public virtual object send(string id) { System.Console.WriteLine(id); return null; }

  //////////////////////////////////////////////////////////////////////////
  // Fields
  //////////////////////////////////////////////////////////////////////////

    internal Widget m_self;
    internal Control m_control;
    internal Fan.Fwt.Point m_pos = Fan.Fwt.Point.m_def;
    internal Fan.Fwt.Size m_size = Fan.Fwt.Size.m_def;

  }
}
