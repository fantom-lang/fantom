//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jun 08  Brian Frank  Creation
//
package fan.fwt;

import java.lang.reflect.Field;
import java.util.HashMap;
import fan.sys.*;
import fan.sys.List;
import org.eclipse.swt.*;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.swt.events.*;

/**
 * Native methods for Widget
 */
public class WidgetPeer
  implements PaintListener, KeyListener, FocusListener, MouseListener
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  public static WidgetPeer make(fan.fwt.Widget self)
    throws Exception
  {
    WidgetPeer peer = new WidgetPeer();
    peer.self = self;
    return peer;
  }

//////////////////////////////////////////////////////////////////////////
// Accessors
//////////////////////////////////////////////////////////////////////////

  public fan.fwt.Widget parent()
  {
    return self.parent();
  }

  public Widget parentControl()
  {
    fan.fwt.Widget p = self.parent();
    return p == null ? null : p.peer.control;
  }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  public final Bool enabled(fan.fwt.Widget self)
  {
    // pain in the ass due to SWT's class hierarchy
    if (control instanceof Control)  return enabled = Bool.make(((Control)control).getEnabled());
    if (control instanceof MenuItem) return enabled = Bool.make(((MenuItem)control).getEnabled());
    if (control instanceof ToolItem) return enabled = Bool.make(((ToolItem)control).getEnabled());
    return enabled;
  }

  public final void enabled(fan.fwt.Widget self, Bool b)
  {
    // pain in the ass due to SWT's class hierarchy
    enabled = b;
    if (control instanceof Control)  ((Control)control).setEnabled(b.val);
    if (control instanceof MenuItem) ((MenuItem)control).setEnabled(b.val);
    if (control instanceof ToolItem) ((ToolItem)control).setEnabled(b.val);
  }

  public final Bool visible(fan.fwt.Widget self)
  {
    if (!(control instanceof Control)) { return visible; }
    return visible = Bool.make(((Control)control).getVisible());
  }

  public final void visible(fan.fwt.Widget self, Bool b)
  {
    visible = b;
    if (control instanceof Control)
      ((Control)control).setVisible(b.val);
  }

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

  public final fan.fwt.Point pos(fan.fwt.Widget self)
  {
    if (!(control instanceof Control)) return pos;
    return point( ((Control)control).getLocation() );
  }

  public final void pos(fan.fwt.Widget self, fan.fwt.Point pos)
  {
    if (!(control instanceof Control)) { this.pos = pos; return; }
    ((Control)control).setLocation((int)pos.x.val, (int)pos.y.val);
  }

  public final Size size(fan.fwt.Widget self)
  {
    if (!(control instanceof Control)) return size;
    return size( ((Control)control).getSize() );
  }

  public final void size(fan.fwt.Widget self, Size size)
  {
    if (!(control instanceof Control)) { this.size = size; return; }
    ((Control)control).setSize((int)size.w.val, (int)size.h.val);
  }

  public final Rect bounds(fan.fwt.Widget self)
  {
    if (!(control instanceof Control)) return Rect.make(pos.x, pos.y, size.w, size.h);
    return rect( ((Control)control).getBounds() );
  }

  public final void bounds(fan.fwt.Widget self, Rect b)
  {
    if (!(control instanceof Control)) { pos = b.pos(); size = b.size(); return; }
    ((Control)control).setBounds((int)b.x.val, (int)b.y.val, (int)b.w.val, (int)b.h.val);
  }

  public Size prefSize(fan.fwt.Widget self, Hints hints)
  {
    if (!(control instanceof Control)) return Size.def;
    int w = (hints.w == null) ? SWT.DEFAULT : (int)hints.w.val;
    int h = (hints.h == null) ? SWT.DEFAULT : (int)hints.h.val;
    Point s = ((Control)control).computeSize(w, h, true);
    return size(s);
  }

  public fan.fwt.Point posOnDisplay(fan.fwt.Widget self)
  {
    if (!(control instanceof Control)) return null;
    Point pt = Env.get().display.map((Control)control, null, 0, 0);
    return point(pt);
  }

  public void relayout(fan.fwt.Widget self)
  {
    if (control instanceof Composite)
      ((Composite)control).layout(true);
  }

  public void repaint(fan.fwt.Widget self, Rect r)
  {
    if (control instanceof Control)
    {
      Control c = (Control)control;
      if (r == null)
        c.redraw();
      else
        c.redraw((int)r.x.val, (int)r.y.val, (int)r.w.val, (int)r.h.val, true);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Focus Eventing
//////////////////////////////////////////////////////////////////////////

  public Bool hasFocus(fan.fwt.Widget self)
  {
    if (control instanceof Control)
      return Bool.make(((Control)control).isFocusControl());
    else
      return Bool.False;
  }

  public void focus(fan.fwt.Widget self)
  {
    if (control instanceof Control)
      ((Control)control).setFocus();
  }

  public void checkFocusListeners(fan.fwt.Widget self)
  {
    // if we don't have any onFocus listeners, then I
    // shouldn't be actively registered as a focus listener
    if (!(control instanceof Control)) return;
    if (self.onFocus().isEmpty().val != activeFocusListener) return;
    if (activeFocusListener)
    {
      ((Control)control).removeFocusListener(this);
      activeFocusListener  = false;
    }
    else
    {
      ((Control)control).addFocusListener(this);
      activeFocusListener = true;
    }
  }

  public void focusGained(FocusEvent se)
  {
    self.onFocus().fire(event(EventId.focusGained));
  }

  public void focusLost(FocusEvent se)
  {
    self.onFocus().fire(event(EventId.focusLost));
  }

//////////////////////////////////////////////////////////////////////////
// Key Eventing
//////////////////////////////////////////////////////////////////////////

  public void checkKeyListeners(fan.fwt.Widget self)
  {
    // if we don't have any onKey listeners, then I
    // shouldn't be actively registered as a key listener
    if (!(control instanceof Control)) return;
    if (self.onKey().isEmpty().val != activeKeyListener) return;
    if (activeKeyListener)
    {
      ((Control)control).removeKeyListener(this);
      activeKeyListener  = false;
    }
    else
    {
      ((Control)control).addKeyListener(this);
      activeKeyListener = true;
    }
  }

  public void keyPressed(KeyEvent se)
  {
    fireKeyEvent(self.onKey(), EventId.keyDown, se);
  }

  public void keyReleased(KeyEvent se)
  {
    fireKeyEvent(self.onKey(), EventId.keyUp, se);
  }

  void fireKeyEvent(EventListeners listeners, EventId id, KeyEvent se)
  {
    fan.fwt.Event fe = event(id);
    fe.keyChar = Int.make(se.character);
    fe.key     = toKey(se.keyCode, se.stateMask);
    listeners.fire(fe);
    if (fe.consumed.val) se.doit = false;
  }

  static Key toKey(int keyCode, int stateMask)
  {
    Key key = Key.fromMask(Int.make(keyCode));
    if ((stateMask & SWT.SHIFT) != 0)   key = key.plus(Key.shift);
    if ((stateMask & SWT.ALT) != 0)     key = key.plus(Key.alt);
    if ((stateMask & SWT.CTRL) != 0)    key = key.plus(Key.ctrl);
    if ((stateMask & SWT.COMMAND) != 0) key = key.plus(Key.command);
    return key;
  }

//////////////////////////////////////////////////////////////////////////
// Mouse Eventing
//////////////////////////////////////////////////////////////////////////

  public void checkMouseListeners(fan.fwt.Widget self)
  {
    // if we don't have any onMouse listeners, then I
    // shouldn't be actively registered as a mouse listener
    if (!(control instanceof Control)) return;
    if (self.onMouse().isEmpty().val != activeMouseListener) return;
    if (activeMouseListener)
    {
      ((Control)control).removeMouseListener(this);
      activeMouseListener  = false;
    }
    else
    {
      ((Control)control).addMouseListener(this);
      activeMouseListener = true;
    }
  }

  public void mouseDoubleClick(MouseEvent se) {}

  public void mouseDown(MouseEvent se) { fireOnMouse(EventId.mouseDown, se); }

  public void mouseUp(MouseEvent se)  { fireOnMouse(EventId.mouseUp, se); }

  private void fireOnMouse(EventId id, MouseEvent se)
  {
    fan.fwt.Event fe = event(id);
    fe.pos    = point(se.x, se.y);
    fe.count  = Int.make(se.count);
    fe.button = Int.make(se.button);
    fe.key    = toKey(0, se.stateMask);
    self.onMouse().fire(fe);
  }

//////////////////////////////////////////////////////////////////////////
// Attachment
//////////////////////////////////////////////////////////////////////////

  public final Bool attached(fan.fwt.Widget self)
  {
    return control != null ? Bool.True : Bool.False;
  }

  public final void attach(fan.fwt.Widget self)
  {
    // short circuit if I'm already attached
    if (control != null) return;

    // short circuit if my parent isn't attached
    fan.fwt.Widget parentWidget = self.parent();
    if (parentWidget == null || parentWidget.peer.control == null) return;

    // create control and initialize
    // TODO: need to rework this cluster f**k
    Widget parentControl = parentWidget.peer.control;
    if (parentControl instanceof TabItem)
    {
      TabItem item = (TabItem)parentControl;
      attachTo(create(item.getParent()));
      item.setControl((Control)this.control);
    }
    else
    {
      attachTo(create(parentControl));
      if (parentControl instanceof ScrolledComposite)
        ((ScrolledComposite)parentControl).setContent((Control)control);
    }

    // callback on parent
    parentWidget.peer.childAdded(self);
  }

  void childAdded(fan.fwt.Widget child) {}

  void attachTo(Widget control)
  {
    // sync with native control
    this.control = control;
    if (pos != fan.fwt.Point.def) pos(self, pos);
    if (size != fan.fwt.Size.def) size(self, size);
    if (!enabled.val) enabled(self, enabled);
    if (!visible.val) visible(self, visible);
    checkFocusListeners(self);
    checkKeyListeners(self);
    checkMouseListeners(self);
    syncProps();

    // stick myself in data field
    control.setData(self);

    // recursively attach my children
    List kids = self.kids;
    for (int i=0; i<kids.sz(); ++i)
    {
      fan.fwt.Widget kid = (fan.fwt.Widget)kids.get(i);
      kid.peer.attach(kid);
    }
  }

  public Widget create(Widget parent)
  {
    Canvas c = new Canvas((Composite)parent, 0)
    {
      public void drawBackground(GC gc, int x, int y, int w, int h) {}
    };
    c.addPaintListener(this);
    return c;
  }

  public void detach(fan.fwt.Widget self)
  {
    if (control == null) return;
    control.dispose();
    control = null;
  }


//////////////////////////////////////////////////////////////////////////
// Widget/Control synchronization
//////////////////////////////////////////////////////////////////////////

  public void syncProps()
  {
    try
    {
      Field[] fields = getClass().getFields();
      for (int i=0; i<fields.length; ++i)
      {
        Field f = fields[i];
        try
        {
          if (Prop.class.isAssignableFrom(f.getType()))
            ((Prop)f.get(this)).init();
        }
        catch (Exception e)
        {
          System.out.println("ERROR: setting " + f);
          e.printStackTrace();
        }
      }
    }
    catch (Exception e)
    {
      e.printStackTrace();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Callbacks
//////////////////////////////////////////////////////////////////////////

  public void paintControl(PaintEvent e)
  {
    Graphics g = new Graphics();
    g.peer.gc = e.gc;
    self.onPaint(g);
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static fan.fwt.Widget toFanWidget(Widget w)
  {
    if (w != null)
    {
      Object data = w.getData();
      if (data instanceof fan.fwt.Widget)
        return (fan.fwt.Widget)data;
    }
    return null;
  }

  static fan.fwt.Point point(int x, int y)
  {
    return fan.fwt.Point.make(Int.make(x), Int.make(y));
  }

  static fan.fwt.Point point(Point pt)
  {
    return fan.fwt.Point.make(Int.make(pt.x), Int.make(pt.y));
  }

  static fan.fwt.Size size(Point pt)
  {
    return fan.fwt.Size.make(Int.make(pt.x), Int.make(pt.y));
  }

  static fan.fwt.Rect rect(Rectangle r)
  {
    return fan.fwt.Rect.make(Int.make(r.x), Int.make(r.y), Int.make(r.width), Int.make(r.height));
  }

  static Rectangle rect(fan.fwt.Rect r)
  {
    return new Rectangle((int)r.x.val, (int)r.y.val, (int)r.w.val, (int)r.h.val);
  }

  static int style(Halign halign)
  {
    if (halign == Halign.left) return SWT.LEFT;
    if (halign == Halign.center) return SWT.CENTER;
    if (halign == Halign.right) return SWT.RIGHT;
    throw new IllegalStateException(halign.toString());
  }

  static int orientation(Orientation orientation)
  {
    if (orientation == Orientation.horizontal) return SWT.HORIZONTAL;
    if (orientation == Orientation.vertical) return SWT.VERTICAL;
    throw new IllegalStateException(orientation.toString());
  }

  static int accelerator(Key key)
  {
    if (key == null) return 0;
    return (int)key.mask.val;
  }

//////////////////////////////////////////////////////////////////////////
// Event Utils
//////////////////////////////////////////////////////////////////////////

  fan.fwt.Event event(EventId id) { return event(id, null); }
  fan.fwt.Event event(EventId id, Obj data)
  {
    fan.fwt.Event f = fan.fwt.Event.make();
    f.id(id);
    f.widget(self);
    f.data(data);
    return f;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  fan.fwt.Widget self;
  Widget control;
  Bool enabled = Bool.True;
  Bool visible = Bool.True;
  fan.fwt.Point pos = fan.fwt.Point.def;
  fan.fwt.Size size = fan.fwt.Size.def;
  boolean activeKeyListener   = false;
  boolean activeFocusListener = false;
  boolean activeMouseListener = false;

}
