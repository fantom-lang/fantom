//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 09  Brian Frank  Creation
//
package fan.fwt;

import fan.sys.*;
import fan.gfx.Orientation;
import org.eclipse.swt.*;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.events.*;

public class ScrollBarPeer
  extends WidgetPeer
  implements SelectionListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static ScrollBarPeer make(fan.fwt.ScrollBar self)
    throws Exception
  {
    ScrollBarPeer peer = new ScrollBarPeer();
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  void attachToScrollable(Scrollable scrollable, ScrollBar control)
  {
    this.scrollable = scrollable;
    attachTo(control);
  }

  void attachTo(Widget control)
  {
    super.attachTo(control);
    ScrollBar sb = (ScrollBar)control;
    sb.addSelectionListener(this);
    checkModifyListeners((fan.fwt.ScrollBar)self);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  public Orientation orientation(fan.fwt.ScrollBar self)
  {
    return orientation(control.getStyle());
  }

  // Int val := 0
  public long val(fan.fwt.ScrollBar self) { return val.get(); }
  public void val(fan.fwt.ScrollBar self, long v) { val.set(v); }
  public final Prop.IntProp val = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ScrollBar)w).getSelection(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setSelection(v); }
  };

  // Int min := 0
  public long min(fan.fwt.ScrollBar self) { return min.get(); }
  public void min(fan.fwt.ScrollBar self, long v) { min.set(v); }
  public final Prop.IntProp min = new Prop.IntProp(this, 0)
  {
    public int get(Widget w) { return ((ScrollBar)w).getMinimum(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setMinimum(v); }
  };

  // Int max := 100
  public long max(fan.fwt.ScrollBar self) { return max.get(); }
  public void max(fan.fwt.ScrollBar self, long v) { max.set(v); }
  public final Prop.IntProp max = new Prop.IntProp(this, 100)
  {
    public int get(Widget w) { return ((ScrollBar)w).getMaximum(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setMaximum(v); }
  };

  // Int thumb := 10
  public long thumb(fan.fwt.ScrollBar self) { return thumb.get(); }
  public void thumb(fan.fwt.ScrollBar self, long v) { thumb.set(v); }
  public final Prop.IntProp thumb = new Prop.IntProp(this, 10)
  {
    public int get(Widget w) { return ((ScrollBar)w).getThumb(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setThumb(v); }
  };

  // Int page := 10
  public long page(fan.fwt.ScrollBar self) { return page.get(); }
  public void page(fan.fwt.ScrollBar self, long v) { page.set(v); }
  public final Prop.IntProp page = new Prop.IntProp(this, 10)
  {
    public int get(Widget w) { return ((ScrollBar)w).getPageIncrement(); }
    public void set(Widget w, int v) { ((ScrollBar)w).setPageIncrement(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

  public void widgetDefaultSelected(SelectionEvent se) {}

  public void widgetSelected(SelectionEvent se)
  {
    fireModified();
  }

  public void fireModified()
  {
    ScrollBar sb = (ScrollBar)control;
    fan.fwt.Event fe = event(EventId.modified);
    this.lastValue = sb.getSelection();
    fe.data = Long.valueOf(this.lastValue);
    ((fan.fwt.ScrollBar)self).onModify().fire(fe);
  }

  public void checkModifyListeners(fan.fwt.ScrollBar self)
  {
    //
    // What follows is a hackish work-around for the fact that SWT
    // doesn't fire scrolling events if the parent scrollable (StyledText,
    // Tree, or Table) uses a key event like PageUp/PageDn to scroll.
    // What we do is register for key events on the scrollable and
    // use that to check if the scroll position has changed.  Since
    // this is potentially pretty expense, we only add ourselves as a
    // key listener when someone registers with ScrollBar.onModify.
    //
    //   - http://fantom.org/sidewalk/topic/534
    //   - http://dev.eclipse.org/newslists/news.eclipse.platform.swt/msg44740.html
    //

    // if we don't have any onModify listeners, then I
    // shouldn't be actively registered as a key listener
    // on my parent table/tree/richtext
    if (control == null || scrollable == null) return;
    boolean now = self.onModify().isEmpty();
    if (now != activeModifyListener) return;

    // create a key listener on the scrollable (StyledText, Table, or Tree);
    // after it fires a key event, we check if the scroll bar has been
    // modified to see if we need to fire an onModify event
    final Fwt fwt = Fwt.get();
    if (scrollableKeyListener == null) scrollableKeyListener = new Listener()
    {
      public void handleEvent(final Event event)
      {
        // asyncExec ensures that Scrollable handles key first
        fwt.display.asyncExec(new Runnable()
        {
          public void run()
          {
            // we are listening for *all* key events on the
            // scrollable, so we only want to fire an event if the
            // scroll bar has actually changed position
            if (control != null && ((ScrollBar)control).getSelection() != lastValue)
              fireModified();
          }
        });
      }
    };

    // add/remove listener
    if (activeModifyListener)
    {
      scrollable.removeListener(SWT.KeyDown, scrollableKeyListener);
      activeModifyListener  = false;
    }
    else
    {
      scrollable.addListener(SWT.KeyDown, scrollableKeyListener);
      activeModifyListener = true;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  boolean activeModifyListener;     // are we actively registered for events
  Control scrollable;               // associated scrollable
  Listener scrollableKeyListener;   // listener for key down on scrollable
  int lastValue;                    // last selection we fired onModify
}