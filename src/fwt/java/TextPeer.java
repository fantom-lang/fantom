//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class TextPeer
  extends TextWidgetPeer
  implements ModifyListener, SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static TextPeer make(fan.fwt.Text self)
    throws Exception
  {
    TextPeer peer = new TextPeer();
    ((fan.fwt.TextWidget)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public Widget create(Widget parent)
  {
    fan.fwt.Text self = (fan.fwt.Text)this.self;

    int style = self.multiLine.val ? SWT.MULTI: SWT.SINGLE;
    if (!self.editable.val) style |= SWT.READ_ONLY;
    if (self.border.val)    style |= SWT.BORDER;
    if (self.wrap.val)      style |= SWT.WRAP;
    if (self.password.val)  style |= SWT.PASSWORD;
    if (self.hscroll.val)   style |= SWT.H_SCROLL;
    if (self.vscroll.val)   style |= SWT.V_SCROLL;

    Text t = new Text((Composite)parent, style);
    control = t;
    t.addModifyListener(this);
    t.addSelectionListener(this);

    // auto selectAll on focus for single line text fields
    if (!self.multiLine.val)
    {
      t.addFocusListener(new FocusAdapter()
      {
        public void focusGained(FocusEvent e)
        {
          ((fan.fwt.Text)TextPeer.this.self).selectAll();
        }
      });
    }

    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Prop.IntProp caretOffset() { return caretOffset; }
  public final Prop.IntProp caretOffset = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((Text)w).getCaretPosition(); }
    public void set(Widget w, int v) { /* not supported */ }
  };

  Prop.FontProp font() { return font; }
  public final Prop.FontProp font = new Prop.FontProp(this)
  {
    public void set(Widget w, Font v) { ((Text)w).setFont(v); }
  };

  // Str text := ""
  public Str text(fan.fwt.Text self) { return text.get(); }
  public void text(fan.fwt.Text self, Str v) { text.set(v); }
  public final Prop.StrProp text = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return ((Text)w).getText(); }
    public void set(Widget w, String v) { ((Text)w).setText(v);  }
  };

//////////////////////////////////////////////////////////////////////////
// Selection
//////////////////////////////////////////////////////////////////////////

  String selectText(Widget w) { return ((Text)w).getSelectionText(); }

  int selectStart(Widget w) { return ((Text)w).getSelection().x; }

  int selectSize(Widget w) { Point sel = ((Text)w).getSelection(); return sel.y - sel.x; }

  void select(Widget w, int start, int size) { ((Text)w).setSelection(start, start+size); }

  void selectAll(Widget w) { ((Text)w).selectAll(); }

  void selectClear(Widget w) { ((Text)w).clearSelection(); }

//////////////////////////////////////////////////////////////////////////
// Clipboard
//////////////////////////////////////////////////////////////////////////

  void cut(Widget w)   { ((Text)w).cut(); }
  void copy(Widget w)  { ((Text)w).copy(); }
  void paste(Widget w) { ((Text)w).paste(); }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void widgetDefaultSelected(SelectionEvent se)
  {
    ((fan.fwt.Text)self).onAction().fire(event(EventId.action));
  }

  public void widgetSelected(SelectionEvent se)
  {
    /* not supported by SWT */
  }

  public void modifyText(ModifyEvent event)
  {
    fan.fwt.Text self = (fan.fwt.Text)this.self;
    self.onModify().fire(event(EventId.modified));
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  private Text text() { return (Text)this.control; }

}