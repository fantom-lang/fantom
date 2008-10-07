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
  public Long caretOffset(TextWidget self) { return caretOffset().get(); }
  public void caretOffset(TextWidget self, Long v) { caretOffset().set(v); }
  abstract Prop.IntProp caretOffset();

  // Font font := null
  public fan.fwt.Font font(TextWidget self) { return font().get(); }
  public void font(TextWidget self, fan.fwt.Font v) { font().set(v); }
  abstract Prop.FontProp font();

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  public String selectText(TextWidget self)
  {
    if (control == null) return "";
    return selectText(control);
  }

  public Long selectStart(TextWidget self)
  {
    if (control == null) return 0L;
    return Long.valueOf(selectStart(control));
  }

  public Long selectSize(TextWidget self)
  {
    if (control == null) return 0L;
    return Long.valueOf(selectSize(control));
  }

  public void select(TextWidget self, Long start, Long size)
  {
    if (control == null) return;
    select(control, start.intValue(), size.intValue());
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