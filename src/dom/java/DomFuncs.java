//
// Copyright (c) 2026, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Nov 2026  Brian Frank  Creation
//

package fan.dom;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import fan.sys.*;

/**
 * DomFuncs is the functions of a DOM element which `Elem.invoke`
 * calls by name: each is a method marked as a DomFunc, and a name
 * with none is an error.  It also has the focus they share with
 * `Elem.focus`.  Each does what a browser does to the tree and fires
 * its events; what a browser fires as a task of its own is queued for
 * `Win.runTimers`.
 */
class DomFuncs
{

//////////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////////

  // Marks a method as a function `Elem.invoke` calls by its name.
  // It takes the element and the arguments:
  //   static Object name(Elem self, List args)
  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.METHOD)
  @interface DomFunc {}

  // Call the method of this class with the name which is marked
  // as a DomFunc
  static Object invoke(Elem self, String name, List args)
  {
    Method m;
    try { m = DomFuncs.class.getDeclaredMethod(name, Elem.class, List.class); }
    catch (NoSuchMethodException e) { m = null; }
    if (m == null || !m.isAnnotationPresent(DomFunc.class)) throw UnsupportedErr.make("Elem.invoke: " + name);

    try { return m.invoke(null, self, args); }
    catch (InvocationTargetException e) { throw Err.make(e.getCause()); }
    catch (IllegalAccessException e) { throw Err.make(e); }
  }

  private static Object arg(List args, int i)
  {
    if (args == null || args.sz() <= i) throw ArgErr.make("Elem.invoke: needs " + (i+1) + " args");
    return args.get(i);
  }

  private static Object opt(List args, int i) { return args == null || args.sz() <= i ? null : args.get(i); }

//////////////////////////////////////////////////////////////////////////
// Element
//////////////////////////////////////////////////////////////////////////

  @DomFunc static Object focus(Elem self, List args) { self.focus(); return null; }

  @DomFunc static Object blur(Elem self, List args) { self.blur(); return null; }

  // A click bubbles and may be refused; it has no default action
  @DomFunc static Object click(Elem self, List args) { fire(self, "click", true, true, null); return null; }

  @DomFunc static Object remove(Elem self, List args)
  {
    if (self.peer.parentNode != null) self.peer.parentNode.removeChild(self);
    return null;
  }

  @DomFunc static Object contains(Elem self, List args) { return Boolean.valueOf(self.containsChild((DomNode)arg(args, 0))); }

  @DomFunc static Object matches(Elem self, List args)
  {
    return Boolean.valueOf(QuerySelector.parse((String)arg(args, 0)).matches(self, self));
  }

  @DomFunc static Object closest(Elem self, List args) { return self.closest((String)arg(args, 0)); }

  @DomFunc static Object hasAttribute(Elem self, List args) { return Boolean.valueOf(self.attr((String)arg(args, 0)) != null); }

  @DomFunc static Object getAttribute(Elem self, List args) { return self.attr((String)arg(args, 0)); }

  @DomFunc static Object setAttribute(Elem self, List args)
  {
    self.setAttr((String)arg(args, 0), String.valueOf(arg(args, 1)));
    return null;
  }

  @DomFunc static Object removeAttribute(Elem self, List args) { self.removeAttr((String)arg(args, 0)); return null; }

  // Add the attribute if it is not there, else remove it, or do as
  // the second argument says
  @DomFunc static Object toggleAttribute(Elem self, List args)
  {
    String name = (String)arg(args, 0);
    Object force = opt(args, 1);
    boolean on = force == null ? self.attr(name) == null : Boolean.TRUE.equals(force);
    if (!on) self.removeAttr(name);
    else if (self.attr(name) == null) self.setAttr(name, "");
    return Boolean.valueOf(on);
  }

  @DomFunc static Object checkVisibility(Elem self, List args) { return Boolean.valueOf(isRendered(self)); }

  // Nothing is laid out, so there is nothing to scroll or select
  @DomFunc static Object scrollIntoView(Elem self, List args) { return null; }
  @DomFunc static Object scrollTo(Elem self, List args) { return null; }
  @DomFunc static Object scrollBy(Elem self, List args) { return null; }
  @DomFunc static Object select(Elem self, List args) { return null; }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  // Dispatch an event with the attributes given as name and value
  // pairs; return false if it was cancelable and a handler refused it
  static boolean fire(DomNode target, String type, boolean bubbles, boolean cancelable, Object[] attrs)
  {
    Map init = Map.make(Sys.StrType, Sys.ObjType.toNullable());
    init.set("bubbles", Boolean.valueOf(bubbles));
    init.set("cancelable", Boolean.valueOf(cancelable));
    if (attrs != null)
      for (int i=0; i<attrs.length; i+=2) if (attrs[i+1] != null) init.set(attrs[i], attrs[i+1]);
    return target.dispatchEvent(Event.makeCustom(type, init));
  }

  private static void fireLater(final Elem target, final String type, final Object[] attrs)
  {
    WinPeer.curPeer().queueTask(new Runnable() { public void run() { fire(target, type, false, false, attrs); } });
  }

//////////////////////////////////////////////////////////////////////////
// Focus
//////////////////////////////////////////////////////////////////////////

  static boolean hasFocus(Elem self)
  {
    DocPeer doc = DocPeer.of(self);
    return doc != null && doc.active == self;
  }

  // Give the focus to an element which may take it: it loses it
  // from the one which has it, with the events of each in the order
  // a browser fires them.  Any other element is left alone
  static void focus(Elem self)
  {
    DocPeer doc = DocPeer.of(self);
    if (doc == null || !isFocusable(self)) return;
    Elem old = doc.activeElem(null);
    if (old == self) return;
    if (old != doc.body) fireBlur(old, self);
    doc.active = self;
    fire(self, "focus",   false, false, new Object[] { "relatedTarget", old == doc.body ? null : old });
    fire(self, "focusin", true,  false, new Object[] { "relatedTarget", old == doc.body ? null : old });
  }

  static void blur(Elem self)
  {
    DocPeer doc = DocPeer.of(self);
    if (doc == null || doc.active != self) return;
    doc.active = null;
    fireBlur(self, null);
  }

  private static void fireBlur(Elem old, Elem to)
  {
    fire(old, "blur",     false, false, new Object[] { "relatedTarget", to });
    fire(old, "focusout", true,  false, new Object[] { "relatedTarget", to });
  }

  // An element takes the focus if it is a control or has a tabindex,
  // and it is drawn and not disabled
  static boolean isFocusable(Elem e)
  {
    if (e.attr("disabled") != null || !isRendered(e)) return false;
    if (e.attr("tabindex") != null) return true;
    String editable = e.attr("contenteditable");
    if (editable != null && !editable.equals("false")) return true;
    switch (e.tagName().toLowerCase())
    {
      case "input":    return !"hidden".equals(e.attr("type"));
      case "select":
      case "textarea":
      case "button":
      case "summary":  return true;
      case "a":
      case "area":     return e.attr("href") != null;
    }
    return false;
  }

  // An element is drawn if it is in a document and neither it nor
  // one above it is hidden, a closed popover or a closed dialog
  static boolean isRendered(Elem e)
  {
    if (DocPeer.of(e) == null) return false;
    for (Elem x = e; x != null; x = x.parent())
    {
      if (x.attr("hidden") != null) return false;
      if (x.attr("popover") != null && !x.peer.popoverOpen) return false;
      if (x.tagName().equalsIgnoreCase("dialog") && x.attr("open") == null) return false;
    }
    return true;
  }

  // Give the focus to what asks for it as a popover or dialog is
  // shown: the element itself if it has autofocus, else the first
  // inside it which has
  private static void autofocus(Elem self)
  {
    Elem control = self.attr("autofocus") != null ? self : self.querySelector("[autofocus]");
    if (control != null) control.focus();
  }

  // Give the focus back to what had it when a popover or dialog was
  // shown, if the focus is still inside what is now hidden
  private static void restoreFocus(Elem self, DocPeer doc)
  {
    Elem prev = self.peer.prevFocus;
    self.peer.prevFocus = null;
    Elem active = doc.active;
    if (active == null || !self.containsChild(active)) return;
    doc.active = null;
    fireBlur(active, prev);
    if (prev != null) prev.focus();
  }

//////////////////////////////////////////////////////////////////////////
// Popover
//////////////////////////////////////////////////////////////////////////

  // Document of a popover, which is an element with the popover
  // attribute that is in a document
  private static DocPeer popoverDoc(Elem self)
  {
    if (self.attr("popover") == null) throw Err.make("NotSupportedError: element is not a popover: " + self);
    DocPeer doc = DocPeer.of(self);
    if (doc == null) throw Err.make("InvalidStateError: popover is not in a document: " + self);
    return doc;
  }

  private static boolean isAuto(Elem self)
  {
    String kind = self.attr("popover");
    return kind.equals("") || kind.equals("auto");
  }

  // Show a popover.  An auto popover hides every other auto popover
  // but those it is inside.  The beforetoggle event may refuse it,
  // and the toggle event follows as a task of its own
  @DomFunc static Object showPopover(Elem self, List args)
  {
    DocPeer doc = popoverDoc(self);
    if (self.peer.popoverOpen) return null;
    Object[] states = new Object[] { "oldState", "closed", "newState", "open" };
    if (!fire(self, "beforetoggle", false, true, states)) return null;

    if (isAuto(self))
    {
      Object[] open = doc.popovers.toArray();
      for (int i=open.length-1; i>=0; i--)
      {
        Elem x = (Elem)open[i];
        if (isAuto(x) && !x.containsChild(self)) hidePopover(x, null);
      }
    }

    self.peer.popoverOpen = true;
    self.peer.prevFocus = doc.active;
    doc.popovers.add(self);
    autofocus(self);
    toggleLater(self, "closed", "open");
    return null;
  }

  // Hide a popover and the auto popovers which are inside it
  @DomFunc static Object hidePopover(Elem self, List args)
  {
    DocPeer doc = popoverDoc(self);
    if (!self.peer.popoverOpen) return null;

    Object[] open = doc.popovers.toArray();
    for (int i=open.length-1; i>=0; i--)
    {
      Elem x = (Elem)open[i];
      if (x != self && isAuto(x) && self.containsChild(x)) hidePopover(x, null);
    }

    Object[] states = new Object[] { "oldState", "open", "newState", "closed" };
    fire(self, "beforetoggle", false, false, states);
    self.peer.popoverOpen = false;
    doc.popovers.remove(self);
    restoreFocus(self, doc);
    toggleLater(self, "open", "closed");
    return null;
  }

  // Fire the toggle event as a task of its own.  A popover which is
  // shown and hidden again before the task runs fires one event, from
  // the state it was first in to the state it is last in
  private static void toggleLater(final Elem self, String oldState, String newState)
  {
    if (self.peer.toggle != null) { self.peer.toggle[3] = newState; return; }
    self.peer.toggle = new Object[] { "oldState", oldState, "newState", newState };
    WinPeer.curPeer().queueTask(new Runnable() { public void run()
    {
      Object[] states = self.peer.toggle;
      self.peer.toggle = null;
      fire(self, "toggle", false, false, states);
    }});
  }

  // Show the popover if it is hidden, else hide it, or do as the
  // argument says; return if it is now shown
  @DomFunc static Object togglePopover(Elem self, List args)
  {
    popoverDoc(self);
    Object force = opt(args, 0);
    boolean show = force == null ? !self.peer.popoverOpen : Boolean.TRUE.equals(force);
    if (show) showPopover(self, null); else hidePopover(self, null);
    return Boolean.valueOf(self.peer.popoverOpen);
  }

//////////////////////////////////////////////////////////////////////////
// Dialog
//////////////////////////////////////////////////////////////////////////

  @DomFunc static Object show(Elem self, List args) { showDialog(self, false); return null; }

  @DomFunc static Object showModal(Elem self, List args) { showDialog(self, true); return null; }

  private static void checkDialog(Elem self)
  {
    if (!self.tagName().equalsIgnoreCase("dialog")) throw UnsupportedErr.make("Elem.invoke: not a dialog: " + self);
  }

  private static void showDialog(Elem self, boolean modal)
  {
    checkDialog(self);
    DocPeer doc = DocPeer.of(self);
    if (modal && doc == null) throw Err.make("InvalidStateError: dialog is not in a document: " + self);
    if (self.attr("open") != null)
    {
      if (modal != self.peer.modal) throw Err.make("InvalidStateError: dialog is already open: " + self);
      return;
    }
    self.setAttr("open", "");
    self.peer.modal = modal;
    if (doc == null) return;
    self.peer.prevFocus = doc.active;
    autofocus(self);
  }

  // Close a dialog with an optional return value; the close event
  // follows as a task of its own
  @DomFunc static Object close(Elem self, List args)
  {
    checkDialog(self);
    if (self.attr("open") == null) return null;
    self.removeAttr("open");
    self.peer.modal = false;
    if (opt(args, 0) != null) self.setProp("returnValue", opt(args, 0));
    DocPeer doc = DocPeer.of(self);
    if (doc != null) restoreFocus(self, doc);
    fireLater(self, "close", null);
    return null;
  }

  // Ask a dialog to close, which a handler of its cancel event may refuse
  @DomFunc static Object requestClose(Elem self, List args)
  {
    checkDialog(self);
    if (fire(self, "cancel", false, true, null)) close(self, args);
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Pointer Capture
//////////////////////////////////////////////////////////////////////////

  // Captures by pointer id of the document of this thread, which an
  // element need not be in: any id is taken as a pointer which is down
  private static java.util.HashMap captures(Elem self)
  {
    Win win = WinPeer.cur();
    return win.doc().peer.captures;
  }

  @DomFunc static Object setPointerCapture(Elem self, List args)
  {
    Object id = arg(args, 0);
    Elem old = (Elem)captures(self).put(id, self);
    if (old == self) return null;
    if (old != null) fire(old, "lostpointercapture", true, false, new Object[] { "pointerId", id });
    fire(self, "gotpointercapture", true, false, new Object[] { "pointerId", id });
    return null;
  }

  @DomFunc static Object releasePointerCapture(Elem self, List args)
  {
    Object id = arg(args, 0);
    if (captures(self).get(id) != self) return null;
    captures(self).remove(id);
    fire(self, "lostpointercapture", true, false, new Object[] { "pointerId", id });
    return null;
  }

  @DomFunc static Object hasPointerCapture(Elem self, List args)
  {
    return Boolean.valueOf(captures(self).get(arg(args, 0)) == self);
  }
}
