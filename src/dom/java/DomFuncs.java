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
 * DomFuncs implements the DOM element functions which can be called
 * by name using `Elem.invoke`.  Each one is a method annotated with
 * @DomFunc; invoking any other name raises UnsupportedErr.  This class
 * also implements focus, which `Elem.focus` shares with these functions.
 *
 * The functions behave like a browser: they update the tree and fire
 * the same events.  Events which a browser fires asynchronously are
 * queued and fired by `Win.runTimers`.
 */
class DomFuncs
{

//////////////////////////////////////////////////////////////////////////
// Invoke
//////////////////////////////////////////////////////////////////////////

  // Annotation for a method which `Elem.invoke` can call by name.
  // The method must have this signature:
  //   static Object name(Elem self, List args)
  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.METHOD)
  @interface DomFunc {}

  // Find the @DomFunc method with the given name and call it
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

  // Fire a click event which bubbles and can be canceled.  Unlike a
  // browser, there is no default action such as checking a checkbox
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

  // Toggle an attribute on or off.  An optional second argument
  // forces it on (true) or off (false).  Return if it is now on
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

  // These are no-ops because there is no layout to scroll or select
  @DomFunc static Object scrollIntoView(Elem self, List args) { return null; }
  @DomFunc static Object scrollTo(Elem self, List args) { return null; }
  @DomFunc static Object scrollBy(Elem self, List args) { return null; }
  @DomFunc static Object select(Elem self, List args) { return null; }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  // Dispatch an event.  The attrs array is name/value pairs to set
  // on the event.  Return false if a handler canceled the event
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

  // Move focus to an element.  This does nothing if the element is
  // not focusable.  Events fire in browser order: blur and focusout
  // on the old element, then focus and focusin on the new one
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

  // Return if an element can take focus.  It must be a form control,
  // a link, or have a tabindex, and it must be rendered and enabled
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

  // Return if an element is rendered.  It must be in a document, and
  // neither it nor any ancestor can be hidden, a closed popover or a
  // closed dialog
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

  // When a popover or dialog is shown, focus the element with the
  // autofocus attribute: either the element itself or the first
  // descendant
  private static void autofocus(Elem self)
  {
    Elem control = self.attr("autofocus") != null ? self : self.querySelector("[autofocus]");
    if (control != null) control.focus();
  }

  // When a popover or dialog is hidden, return focus to the element
  // which had it before, but only if focus is still inside the
  // element being hidden
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

  // Get the document of a popover.  Raise an error if the element
  // has no popover attribute or is not in a document
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

  // Show a popover.  Showing an auto popover hides every other auto
  // popover except its ancestors.  A handler can cancel the show via
  // the beforetoggle event.  The toggle event fires asynchronously
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

  // Hide a popover and any auto popovers nested inside it
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

  // Queue the toggle event to fire asynchronously.  If the popover is
  // shown and hidden again before the event fires, only one event is
  // fired with the original old state and the final new state
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

  // Toggle a popover open or closed.  An optional argument forces
  // it open (true) or closed (false).  Return if it is now open
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

  // Close a dialog with an optional return value.  The close event
  // fires asynchronously
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

  // Request that a dialog close.  A handler can prevent the close
  // by canceling the cancel event
  @DomFunc static Object requestClose(Elem self, List args)
  {
    checkDialog(self);
    if (fire(self, "cancel", false, true, null)) close(self, args);
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Pointer Capture
//////////////////////////////////////////////////////////////////////////

  // Get the map of pointer id to capturing element for this thread's
  // document.  Any pointer id is accepted, and the element does not
  // need to be in the document
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
