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
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.custom.CLabel;

public abstract class TextWidgetPeer extends WidgetPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TextWidgetPeer make(TextWidget self)
    throws Exception
  {
    // just return null, we rely on subclasses to
    // set the Widget and TextWidget peer fields
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Int caretOffset := 0
  public Int caretOffset(TextWidget self) { return caretOffset().get(); }
  public void caretOffset(TextWidget self, Int v) { caretOffset().set(v); }
  abstract Prop.IntProp caretOffset();

  // Font font := null
  public fan.fwt.Font font(TextWidget self) { return font().get(); }
  public void font(TextWidget self, fan.fwt.Font v) { font().set(v); }
  abstract Prop.FontProp font();

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  public Str selectText(TextWidget self)
  {
    if (control == null) return Str.Empty;
    return Str.make(selectText(control));
  }

  public Int selectStart(TextWidget self)
  {
    if (control == null) return Int.Zero;
    return Int.make(selectStart(control));
  }

  public Int selectSize(TextWidget self)
  {
    if (control == null) return Int.Zero;
    return Int.make(selectSize(control));
  }

  public void select(TextWidget self, Int start, Int size)
  {
    if (control == null) return;
    select(control, (int)start.val, (int)size.val);
  }

  public void selectAll(TextWidget self)
  {
    if (control == null) return;
    selectAll(control);
  }

  public void selectClear(TextWidget self)
  {
    if (control == null) return;
    selectClear(control);
  }

  abstract String selectText(Widget w);
  abstract int selectStart(Widget w);
  abstract int selectSize(Widget w);
  abstract void select(Widget w, int start, int size);
  abstract void selectAll(Widget w);
  abstract void selectClear(Widget w);

//////////////////////////////////////////////////////////////////////////
// Clipboard
//////////////////////////////////////////////////////////////////////////

  public void cut(TextWidget self)   { if (control != null) cut(control); }
  public void copy(TextWidget self)  { if (control != null) copy(control); }
  public void paste(TextWidget self) { if (control != null) paste(control); }

  abstract void cut(Widget w);
  abstract void copy(Widget w);
  abstract void paste(Widget w);

}