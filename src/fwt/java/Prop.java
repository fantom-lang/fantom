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
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Control;

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

    Boolean get()
    {
      Widget w = peer.control;
      return w == null ? val : get(w);
    }

    void set(Boolean v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v);
    }

    public abstract boolean get(Widget w);
    public abstract void set(Widget w, boolean v);

    Boolean val;
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
      this.val = Str.make(def);
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    Str get()
    {
      Widget w = peer.control;
      return w == null ? val : Str.make(get(w));
    }

    void set(Str v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v == null ? null : v.val);
    }

    public abstract String get(Widget w);
    public abstract void set(Widget w, String v);

    Str val;
  }

//////////////////////////////////////////////////////////////////////////
// PosProp
//////////////////////////////////////////////////////////////////////////

  static class PosProp extends Prop
  {
    PosProp(WidgetPeer peer) { super(peer); }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    fan.fwt.Point get()
    {
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        val = WidgetPeer.point(c.getLocation());
      }
      return val;
    }

    void set(fan.fwt.Point v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setLocation(v.x.intValue(), v.y.intValue());
      }
    }

    fan.fwt.Point val = fan.fwt.Point.def;
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
      return val;
    }

    void set(Size v)
    {
      val = v;
      if (peer.control instanceof Control)
      {
        Control c = (Control)peer.control;
        c.setSize(v.w.intValue(), v.h.intValue());
      }
    }

    Size val = Size.def;
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

    fan.fwt.Color get() { return val; }

    void set(fan.fwt.Color v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Env.get().color(val));
    }

    public abstract void set(Widget w, Color v);

    fan.fwt.Color val;
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

    fan.fwt.Image get() { return val; }

    void set(fan.fwt.Image v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Env.get().image(val));
    }

    public abstract void set(Widget w, Image v);

    fan.fwt.Image val;
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

    fan.fwt.Font get() { return val; }

    void set(fan.fwt.Font v)
    {
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, Env.get().font(val));
    }

    public abstract void set(Widget w, Font v);

    fan.fwt.Font val;
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