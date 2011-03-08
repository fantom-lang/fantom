//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   20 Jul 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import fan.gfx.Size;
import fan.gfx.Halign;
import fan.gfx.Valign;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.ToolItem;

/**
 * Props are used to manage a field's value and how they
 * bind to the SWT getter/setters.  Each Prop is responsible
 * for caching the value until the widget can be mounted and
 * mapped to a SWT control.
 */
public abstract class Prop
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public Prop(WidgetPeer peer)
  {
    this.peer = peer;
  }

  public abstract void syncToControl();

  public abstract void syncFromControl();

//////////////////////////////////////////////////////////////////////////
// BoolProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class BoolProp extends Prop
  {
    public BoolProp(WidgetPeer peer, boolean def)
    {
      super(peer);
      this.val = def;
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public boolean get()
    {
      Widget w = peer.control;
      return w == null ? val : get(w);
    }

    public void set(boolean v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v);
    }

    public abstract boolean get(Widget w);
    public abstract void set(Widget w, boolean v);

    protected boolean val;
  }

//////////////////////////////////////////////////////////////////////////
// IntProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class IntProp extends Prop
  {
    public IntProp(WidgetPeer peer, int def) { this(peer, def, false); }
    public IntProp(WidgetPeer peer, int def, boolean negIsNull)
    {
      super(peer);
      this.val = Long.valueOf(def);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public Long get()
    {
      Widget w = peer.control;
      if (w == null) return val;
      int i = get(w);
      if (negIsNull && i < 0) return null;
      return Long.valueOf(i);
    }

    public void set(Long v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v.intValue());
    }

    public abstract int get(Widget w);
    public abstract void set(Widget w, int v);

    protected Long val;
    protected boolean negIsNull;
  }

//////////////////////////////////////////////////////////////////////////
// StrProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class StrProp extends Prop
  {
    public StrProp(WidgetPeer peer, String def)
    {
      super(peer);
      this.val = def;
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public String get()
    {
      Widget w = peer.control;
      return w == null ? val : get(w);
    }

    public void set(String v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v == null ? null : v);
    }

    public abstract String get(Widget w);
    public abstract void set(Widget w, String v);

    protected String val;
  }

//////////////////////////////////////////////////////////////////////////
// PosProp
//////////////////////////////////////////////////////////////////////////

  public static class PosProp extends Prop
  {
    public PosProp(WidgetPeer peer) { super(peer); }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public fan.gfx.Point get()
    {
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        val = WidgetPeer.point(c.getLocation());
      }
      else if (peer.control instanceof ToolItem)
      {
        ToolItem ti = (ToolItem)peer.control;
        val = WidgetPeer.point(ti.getBounds());
      }
      return val;
    }

    public void set(fan.gfx.Point v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setLocation((int)v.x, (int)v.y);
      }
    }

    protected fan.gfx.Point val = fan.gfx.Point.defVal;
  }

//////////////////////////////////////////////////////////////////////////
// SizeProp
//////////////////////////////////////////////////////////////////////////

  public static class SizeProp extends Prop
  {
    public SizeProp(WidgetPeer peer) { super(peer); }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public Size get()
    {
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        val = WidgetPeer.size(c.getSize());
      }
      else if (peer.control instanceof ToolItem)
      {
        ToolItem ti = (ToolItem)peer.control;
        val = WidgetPeer.size(ti.getBounds());
      }
      return val;
    }

    public void set(Size v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setSize((int)v.w, (int)v.h);
      }
    }

    protected Size val = Size.defVal;
  }

//////////////////////////////////////////////////////////////////////////
// ItemsProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class ItemsProp extends Prop
  {
    public ItemsProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public List get() { return val; }

    public void set(List v)
    {
      val = v.ro();
      Widget w = peer.control;
      if (w != null)
        set(w, val.toStrings());
    }

    public abstract void set(Widget w, String[] v);

    protected List val = new List(Sys.ObjType).ro();
  }

//////////////////////////////////////////////////////////////////////////
// IntsProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class IntsProp extends Prop
  {
    public IntsProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public List get()
    {
      Widget w = peer.control;
      if (w == null) return val;
      int[] ints = get(w);
      val = new List(Sys.IntType);
      for (int i=0; i<ints.length; ++i) val.add(Long.valueOf(ints[i]));
      return val;
    }

    public void set(List v)
    {
      Widget w = peer.control;
      val = v == null ? null : v.ro();
      if (w != null)
        set(w, val == null ? null : val.toInts());
    }

    public abstract int[] get(Widget w);
    public abstract void set(Widget w, int[] v);

    protected List val = new List(Sys.IntType).ro();
  }

//////////////////////////////////////////////////////////////////////////
// CursorProp
//////////////////////////////////////////////////////////////////////////

  public static class CursorProp extends Prop
  {
    public CursorProp(WidgetPeer peer) { super(peer); }

    public void syncToControl() { set(val); }

    public void syncFromControl() { val = get(); }

    public Cursor get() { return val; }

    public void set(Cursor v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        ((Control)peer.control).setCursor(Fwt.get().cursor(val));
      }
    }

    protected Cursor val = null;
  }

//////////////////////////////////////////////////////////////////////////
// ColorProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class ColorProp extends Prop
  {
    public ColorProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public fan.gfx.Color get() { return val; }

    public void set(fan.gfx.Color v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().color(val));
    }

    public abstract void set(Widget w, Color v);

    protected fan.gfx.Color val;
  }

//////////////////////////////////////////////////////////////////////////
// ImageProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class ImageProp extends Prop
  {
    public ImageProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public fan.gfx.Image get() { return val; }

    public void set(fan.gfx.Image v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().image(val));
    }

    public abstract void set(Widget w, Image v);

    protected fan.gfx.Image val;
  }

//////////////////////////////////////////////////////////////////////////
// FontProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class FontProp extends Prop
  {
    public FontProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public fan.gfx.Font get() { return val; }

    public void set(fan.gfx.Font v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().font(val));
    }

    public abstract void set(Widget w, Font v);

    protected fan.gfx.Font val;
  }

//////////////////////////////////////////////////////////////////////////
// KeyProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class KeyProp extends Prop
  {
    public KeyProp(WidgetPeer peer)
    {
      super(peer);
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public fan.fwt.Key get() { return val; }

    public void set(fan.fwt.Key v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, WidgetPeer.accelerator(val));
    }

    public abstract void set(Widget w, int v);

    protected fan.fwt.Key val;
  }

//////////////////////////////////////////////////////////////////////////
// HalignProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class HalignProp extends Prop
  {
    public HalignProp(WidgetPeer peer, Halign def)
    {
      super(peer);
      this.val = def;
    }

    public void syncToControl() { set(val); }

    public void syncFromControl() {}

    public Halign get() { return val;  }

    public void set(Halign v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, WidgetPeer.style(val));
    }

    public abstract void set(Widget w, int v);

    protected Halign val;
  }

//////////////////////////////////////////////////////////////////////////
// CustomProp
//////////////////////////////////////////////////////////////////////////

  public static abstract class Custom extends Prop
  {
    public Custom(WidgetPeer peer) { super(peer); }
    public abstract Object get();
    public abstract void set(Object val);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final WidgetPeer peer;
}