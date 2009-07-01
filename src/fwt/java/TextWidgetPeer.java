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
  public long caretOffset(TextWidget self) { return caretOffset().get(); }
  public void caretOffset(TextWidget self, long v) { caretOffset().set(v); }
  abstract Prop.IntProp caretOffset();

  // Font font := null
  public fan.gfx.Font font(TextWidget self) { return font().get(); }
  public void font(TextWidget self, fan.gfx.Font v) { font().set(v); }
  abstract Prop.FontProp font();

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  public fan.gfx.Size prefSize(TextWidget self) { return prefSize(self, fan.gfx.Hints.defVal); }
  public fan.gfx.Size prefSize(TextWidget self, fan.gfx.Hints hints)
  {
    // this isn't very exact right now
    int inset  = 10;
    int scroll = 20;
    fan.gfx.Size superPref = super.prefSize(self, hints);
    fan.gfx.Font font = self.font();
    if (font == null) font = Desktop.sysFont();

    if (self.multiLine)
      return fan.gfx.Size.make(
        inset + font.width("m")*self.prefCols + scroll,
        inset + font.height()*self.prefRows + scroll);
    else
      return fan.gfx.Size.make(
        inset + font.width("m")*self.prefCols ,
        superPref.h);
  }

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  public String selectText(TextWidget self)
  {
    if (control == null) return "";
    return selectText(control);
  }

  public long selectStart(TextWidget self)
  {
    if (control == null) return 0L;
    return selectStart(control);
  }

  public long selectSize(TextWidget self)
  {
    if (control == null) return 0L;
    return selectSize(control);
  }

  public void select(TextWidget self, long start, long size)
  {
    if (control == null) return;
    select(control, (int)start, (int)size);
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