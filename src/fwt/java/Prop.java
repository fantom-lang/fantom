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
import org.eclipse.swt.widgets.Widget;

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
      this.val = Bool.make(def);
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    Bool get()
    {
      Widget w = peer.control;
      return w == null ? val : Bool.make(get(w));
    }

    void set(Bool v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, v.val);
    }

    public abstract boolean get(Widget w);
    public abstract void set(Widget w, boolean v);

    Bool val;
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
      this.val = Int.make(def);
    }

    void syncToControl() { set(val); }

    void syncFromControl() { val = get(); }

    Int get()
    {
      Widget w = peer.control;
      if (w == null) return val;
      int i = get(w);
      if (negIsNull && i < 0) return null;
      return Int.make(i);
    }

    void set(Int v)
    {
      Widget w = peer.control;
      if (w == null)
        val = v;
      else
        set(w, (int)v.val);
    }

    public abstract int get(Widget w);
    public abstract void set(Widget w, int v);

    Int val;
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
      val = v;
      Widget w = peer.control;
      if (w != null)
        set(w, val.toStrings());
    }

    public abstract void set(Widget w, String[] v);

    List val = new List(Sys.ObjType);
  }

//////////////////////////////////////////////////////////////////////////
// WeightsProp
//////////////////////////////////////////////////////////////////////////

  static abstract class WeightsProp extends Prop
  {
    WeightsProp(WidgetPeer peer)
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
      for (int i=0; i<ints.length; ++i) val.add(Int.make(ints[i]));
      return val;
    }

    void set(List v)
    {
      Widget w = peer.control;
      val = v;
      if (w != null)
        set(w, val == null ? null : val.toInts());
    }

    public abstract int[] get(Widget w);
    public abstract void set(Widget w, int[] v);

    List val = new List(Sys.IntType);
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
// Fields
//////////////////////////////////////////////////////////////////////////

  final WidgetPeer peer;
}