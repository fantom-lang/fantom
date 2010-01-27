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

  Prop(WidgetPeer peer)
  {
    this.peer = peer;
  }

  abstract void syncToControl();

  abstract void syncFromControl();

//////////////////////////////////////////////////////////////////////////
// BoolProp
//////////////////////////////////////////////////////////////////////////

  static abstract class BoolProp extends Prop
  {
    BoolProp(WidgetPeer peer, boolean def)
    {
      super(peer);
      this.val = def;
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    boolean get()
    {
      Widget w = peer.control;
      return w == null ? val : get(w);
    }

    void set(boolean v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v);
    }

    public abstract boolean get(Widget w);
    public abstract void set(Widget w, boolean v);

    boolean val;
  }

//////////////////////////////////////////////////////////////////////////
// IntProp
//////////////////////////////////////////////////////////////////////////

  static abstract class IntProp extends Prop
  {
    IntProp(WidgetPeer peer, int def) { this(peer, def, false); }
    IntProp(WidgetPeer peer, int def, boolean negIsNull)
    {
      super(peer);
      this.val = Long.valueOf(def);
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    Long get()
    {
      Widget w = peer.control;
      if (w == null) return val;
      int i = get(w);
      if (negIsNull && i < 0) return null;
      return Long.valueOf(i);
    }

    void set(Long v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v.intValue());
    }

    public abstract int get(Widget w);
    public abstract void set(Widget w, int v);

    Long val;
    boolean negIsNull;
  }

//////////////////////////////////////////////////////////////////////////
// StrProp
//////////////////////////////////////////////////////////////////////////

  static abstract class StrProp extends Prop
  {
    StrProp(WidgetPeer peer, String def)
    {
      super(peer);
      this.val = def;
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    String get()
    {
      Widget w = peer.control;
      return w == null ? val : get(w);
    }

    void set(String v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v == null ? null : v);
    }

    public abstract String get(Widget w);
    public abstract void set(Widget w, String v);

    String val;
  }

//////////////////////////////////////////////////////////////////////////
// PosProp
//////////////////////////////////////////////////////////////////////////

  static class PosProp extends Prop
  {
    PosProp(WidgetPeer peer) { super(peer); }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    fan.gfx.Point get()
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

    void set(fan.gfx.Point v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setLocation((int)v.x, (int)v.y);
      }
    }

    fan.gfx.Point val = fan.gfx.Point.defVal;
  }

//////////////////////////////////////////////////////////////////////////
// SizeProp
//////////////////////////////////////////////////////////////////////////

  static class SizeProp extends Prop
  {
    SizeProp(WidgetPeer peer) { super(peer); }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    Size get()
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

    void set(Size v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setSize((int)v.w, (int)v.h);
      }
    }

    Size val = Size.defVal;
  }

//////////////////////////////////////////////////////////////////////////
// ItemsProp
//////////////////////////////////////////////////////////////////////////

  static abstract class ItemsProp extends Prop
  {
    ItemsProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    List get() { return val; }

    void set(List v)
    {
      val = v.ro();
      Widget w = peer.control;
      if (w != null)
        set(w, val.toStrings());
    }

    public abstract void set(Widget w, String[] v);

    List val = new List(Sys.ObjType).ro();
  }

//////////////////////////////////////////////////////////////////////////
// IntsProp
//////////////////////////////////////////////////////////////////////////

  static abstract class IntsProp extends Prop
  {
    IntsProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    List get()
    {
      Widget w = peer.control;
      if (w == null) return val;
      int[] ints = get(w);
      val = new List(Sys.IntType);
      for (int i=0; i<ints.length; ++i) val.add(Long.valueOf(ints[i]));
      return val;
    }

    void set(List v)
    {
      Widget w = peer.control;
      val = v == null ? null : v.ro();
      if (w != null)
        set(w, val == null ? null : val.toInts());
    }

    public abstract int[] get(Widget w);
    public abstract void set(Widget w, int[] v);

    List val = new List(Sys.IntType).ro();
  }

//////////////////////////////////////////////////////////////////////////
// ColorProp
//////////////////////////////////////////////////////////////////////////

  static abstract class ColorProp extends Prop
  {
    ColorProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    fan.gfx.Color get() { return val; }

    void set(fan.gfx.Color v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().color(val));
    }

    public abstract void set(Widget w, Color v);

    fan.gfx.Color val;
  }

//////////////////////////////////////////////////////////////////////////
// ImageProp
//////////////////////////////////////////////////////////////////////////

  static abstract class ImageProp extends Prop
  {
    ImageProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    fan.gfx.Image get() { return val; }

    void set(fan.gfx.Image v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().image(val));
    }

    public abstract void set(Widget w, Image v);

    fan.gfx.Image val;
  }

//////////////////////////////////////////////////////////////////////////
// FontProp
//////////////////////////////////////////////////////////////////////////

  static abstract class FontProp extends Prop
  {
    FontProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    fan.gfx.Font get() { return val; }

    void set(fan.gfx.Font v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Fwt.get().font(val));
    }

    public abstract void set(Widget w, Font v);

    fan.gfx.Font val;
  }

//////////////////////////////////////////////////////////////////////////
// KeyProp
//////////////////////////////////////////////////////////////////////////

  static abstract class KeyProp extends Prop
  {
    KeyProp(WidgetPeer peer)
    {
      super(peer);
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    fan.fwt.Key get() { return val; }

    void set(fan.fwt.Key v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, WidgetPeer.accelerator(val));
    }

    public abstract void set(Widget w, int v);

    fan.fwt.Key val;
  }

//////////////////////////////////////////////////////////////////////////
// HalignProp
//////////////////////////////////////////////////////////////////////////

  static abstract class HalignProp extends Prop
  {
    HalignProp(WidgetPeer peer, Halign def)
    {
      super(peer);
      this.val = def;
    }

    void syncToControl() { set(val); }

    void syncFromControl() {}

    Halign get() { return val;  }

    void set(Halign v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, WidgetPeer.style(val));
    }

    public abstract void set(Widget w, int v);

    Halign val;
  }

//////////////////////////////////////////////////////////////////////////
// CustomProp
//////////////////////////////////////////////////////////////////////////

  static abstract class Custom extends Prop
  {
    Custom(WidgetPeer peer) { super(peer); }
    abstract Object get();
    abstract void set(Object val);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  final WidgetPeer peer;
}