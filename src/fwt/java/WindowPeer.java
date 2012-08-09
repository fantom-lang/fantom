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
import org.eclipse.swt.events.*;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.*;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.layout.*;
import org.eclipse.swt.dnd.*;

public class WindowPeer
  extends PanePeer
  implements ShellListener
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static WindowPeer make(fan.fwt.Window self)
    throws Exception
  {
    WindowPeer peer = new WindowPeer();
    ((fan.fwt.Pane)self).peer = peer;
    ((fan.fwt.Widget)self).peer = peer;
    peer.self = self;
    return peer;
  }

  public final Widget create(Widget parent)
  {
    // window uses open, not normal attach process
    throw new IllegalStateException();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  // Str title := ""
  public String title(Window self) { return title.get(); }
  public void title(Window self, String v) { title.set(v); }
  public final Prop.StrProp title = new Prop.StrProp(this, "")
  {
    public String get(Widget w) { return ((Shell)w).getText(); }
    public void set(Widget w, String v) { ((Shell)w).setText(v);  }
  };

  // Image icon := null
  public fan.gfx.Image icon(Window self) { return icon.get(); }
  public void icon(Window self, fan.gfx.Image v) { icon.set(v); }
  public final Prop.ImageProp icon = new Prop.ImageProp(this)
  {
    public void set(Widget w, Image v) { ((Shell)w).setImage(v); }
  };

//////////////////////////////////////////////////////////////////////////
// Sizing
//////////////////////////////////////////////////////////////////////////

  void onPosChange()  { explicitPos = true;  }
  void onSizeChange() { explicitSize = true; }

  void layout()
  {
    try { ((Window)self).onLayout(); }
    catch (Exception e) { e.printStackTrace(); }
  }

//////////////////////////////////////////////////////////////////////////
// Eventing
//////////////////////////////////////////////////////////////////////////

 public void shellClosed(ShellEvent se)
 {
   Window self = (Window)this.self;
   fan.fwt.Event fe = event(EventId.close);
   self.onClose().fire(fe);
   if (fe.consumed) se.doit = false;
 }

 public void shellActivated(ShellEvent se)
 {
   Window self = (Window)this.self;
   self.onActive().fire(event(EventId.active));
 }

 public void shellDeactivated(ShellEvent se)
 {
   Window self = (Window)this.self;
   self.onInactive().fire(event(EventId.inactive));
 }

 public void shellDeiconified(ShellEvent se)
 {
   Window self = (Window)this.self;
   self.onDeiconified().fire(event(EventId.deiconified));
 }

 public void shellIconified(ShellEvent se)
 {
   Window self = (Window)this.self;
   self.onIconified().fire(event(EventId.iconified));
 }

//////////////////////////////////////////////////////////////////////////
// Lifecycle
//////////////////////////////////////////////////////////////////////////

  int style(Window self)
  {
    int style = defaultStyle();

    if (self.mode == WindowMode.modeless)         style |= SWT.MODELESS;
    else if (self.mode == WindowMode.windowModal) style |= SWT.PRIMARY_MODAL;
    else if (self.mode == WindowMode.appModal)    style |= SWT.APPLICATION_MODAL;
    else if (self.mode == WindowMode.sysModal)    style |= SWT.SYSTEM_MODAL;

    if (self.alwaysOnTop) style |= SWT.ON_TOP;

    if (self.resizable) style |= SWT.RESIZE;

    if (!self.showTrim) style |= SWT.NO_TRIM;

    return style;
  }

  int defaultStyle() { return SWT.CLOSE | SWT.TITLE | SWT.MIN | SWT.MAX; }

  public Object open(Window self)
  {
    // if already open
    if (control != null) throw Err.make("Window already open");

    // initialize with clean slate
    result = null;

    // create SWT shell
    Fwt fwt = Fwt.get();
    Shell shell;
    fan.fwt.Widget parent = self.parent();
    Shell parentShell = parent == null ? null : (Shell)parent.peer.control;
    if (parentShell == null)
    {
      shell = new Shell(fwt.display, style(self));
    }
    else
    {
      shell = new Shell(parentShell, style(self));
    }
    shell.setLayout(new FillLayout());
    shell.addShellListener(this);
    attachTo(shell);

    // setup drag and drop
    initDrop(shell);

    // if not explicitly sized, then use prefSize - but
    // make sure not bigger than monitor (at this point we
    // don't know which monitor so assume primary monitor)
    if (!explicitSize)
    {
      shell.pack();
      Rectangle mb = shell.getBounds();
      Rectangle pb = fwt.display.getPrimaryMonitor().getClientArea();
      int pw = Math.min(mb.width, pb.width-50);
      int ph = Math.min(mb.height, pb.height-50);
      self.size(size(pw, ph));
    }

    // if not explicitly positioned, then center on
    // parent shell (or primary monitor)
    if (!explicitPos)
    {
      Rectangle pb = parentShell == null ?
        fwt.display.getPrimaryMonitor().getClientArea() :
        parentShell.getBounds();
      Rectangle mb = shell.getBounds();
      int cx = pb.x + (pb.width - mb.width)/2;
      int cy = pb.y + (pb.height - mb.height)/2;
      self.pos(point(cx, cy));
    }

    // ensure that window isn't off the display; this
    // still might cover multiple monitors though, but
    // provides a safe sanity check
    Rectangle mb = shell.getBounds();
    Rectangle db = fwt.display.getClientArea();
    if (mb.width > db.width) mb.width = db.width;
    if (mb.height > db.height) mb.height = db.height;
    if (mb.x + mb.width > db.x + db.width) mb.x = db.x + db.width - mb.width;
    if (mb.x < db.x) mb.x = db.x;
    if (mb.y + mb.height > db.y + db.height) mb.y = db.y + db.height - mb.height;
    if (mb.y < db.y) mb.y = db.y;
    self.bounds(rect(mb));

    // set default button
    if (defButton != null)
      shell.setDefaultButton((org.eclipse.swt.widgets.Button)defButton.peer.control);

    // open
    shell.open();

    // TODO FIXIT: we actually want to fire this after the event
    // loop is entered, so SWT is "active" - for now we can use
    // Desktop.callLater(~10ms) as a workaround
    self.onOpen().fire(event(EventId.open));

    // block until dialog is closed
    fwt.eventLoop(shell);

    // cleanup
    detach(self);
    explicitPos = explicitSize = false;
    return result;
  }

  public void activate(Window self)
  {
    if (control == null) return;
    Shell shell = (Shell)control;
    shell.setActive();
  }

  public void close(Window self, Object result)
  {
    if (control == null) return;
    this.result = result;
    Shell shell = (Shell)control;
    shell.close();
    detach(self);
  }

//////////////////////////////////////////////////////////////////////////
// Drag and Drop
//////////////////////////////////////////////////////////////////////////

  /**
   * The FWT doesn't officially support drag and drop.  However as a
   * temp solution we provide a back-door hook to drop files onto a
   * Window for flux.
   */
  void initDrop(Shell shell)
  {
    DropTarget t = new DropTarget(shell, DND.DROP_MOVE | DND.DROP_COPY | DND.DROP_DEFAULT);
    t.setTransfer(new Transfer[] { FileTransfer.getInstance() });
    t.addDropListener(new DropTargetAdapter()
    {
      public void dragEnter(DropTargetEvent event)
      {
      }

      public void dragOver(DropTargetEvent event)
      {
       event.feedback = DND.FEEDBACK_SELECT | DND.FEEDBACK_SCROLL;
      }

      public void drop(DropTargetEvent event)
      {
        Window window = (Window)self;
        if (window.onDrop == null) return;

        FileTransfer ft = FileTransfer.getInstance();
        if (!ft.isSupportedType(event.currentDataType)) return;

        fan.sys.List data = new fan.sys.List(Sys.FileType, 0);
        String[] paths = (String[])ft.nativeToJava(event.currentDataType);
        for (int i=0; i<paths.length; ++i)
          data.add(File.os(paths[i]));

        window.onDrop().call(data);
      }
    });
  }

//////////////////////////////////////////////////////////////////////////
// NoDoc
//////////////////////////////////////////////////////////////////////////

  public void setOverlayText(Window self, String text)
  {
    Fwt.get().display.getSystemTaskBar().getItem(0).setOverlayText(text);
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  boolean explicitPos;    // has pos been explicitly configured?
  boolean explicitSize;   // has size been explicitly configured?
  Button defButton;
  Object result;
}