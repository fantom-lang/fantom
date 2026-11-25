//
// Copyright (c) 2017, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 May 2017  Andy Frank   Creation
//   24 Nov 2026  Brian Frank  Document, events, timers, history, storage
//

package fan.dom;

import java.util.ArrayList;
import fan.sys.*;

/**
 * WinPeer is the JVM implementation of a window, used for testing
 * without a browser.  It has a document, event listeners, history and
 * storage.  Timers are queued on a virtual clock which only advances
 * when `Win.runTimers` is called.  There is no layout, so the window
 * has no size or scroll position.
 */
public class WinPeer
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  public static WinPeer make(Win fan)
  {
    return DomPeerFactory.factory().makeWin(fan);
  }

  public static Win cur()
  {
    return DomPeerFactory.factory().winCur();
  }

  public static Object eval(String js)
  {
    return DomPeerFactory.factory().winEval(js);
  }

  public static Func evalToFunc(List params, String js)
  {
    return DomPeerFactory.factory().winEvalToFunc(params, js);
  }

  // Get the peer of the current thread's window
  static WinPeer curPeer() { return cur().peer; }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  // userAgent() is required to exist by Win.make()
  public String userAgent(Win self)
  {
    return "Fantom/" + self.typeof().pod().version().toString();
  }

  public Doc doc(Win self)
  {
    if (doc == null)
    {
      doc = Doc.make();
      doc.peer.init(doc, self);
    }
    return doc;
  }

  public Win parent(Win self) { return null; }

  public Win top(Win self) { return self; }

  public double devicePixelRatio(Win self) { return 1.0; }

  public Map diagnostics(Win self) { return Map.make(Sys.StrType, Sys.ObjType); }

  public void log(Win self, Object obj) { System.out.println(obj); }

  public void addStyleRules(Win self, String rules) {}

  public Win scrollTo(Win self, long x, long y) { return self; }

  public Win scrollBy(Win self, long x, long y) { return self; }

  public TextSel textSel(Win self)
  {
    if (textSel == null) textSel = TextSel.make();
    return textSel;
  }

  public Win  open   (Win self, Uri uri, String winName, Map opts) { throw err(); }
  public Win  close  (Win self)                                    { throw err(); }
  public void alert  (Win self, Object obj)                        { throw err(); }
  public boolean confirm(Win self, Object obj)                     { throw err(); }
  public void geoCurPosition  (Win self, Func onSuccess, Func onErr, Map opts) { throw err(); }
  public long geoWatchPosition(Win self, Func onSuccess, Func onErr, Map opts) { throw err(); }
  public void geoClearWatch   (Win self, long id)                              { throw err(); }

// cannot compile against "graphics" pod - see https://fantom.org/forum/topic/2886
// public Size   viewport          (Win self)                                           { throw err(); }
// public Size   screenSize        (Win self)                                           { throw err(); }
// public Point  scrollPos         (Win self)                                           { throw err(); }

//////////////////////////////////////////////////////////////////////////
// Events
//////////////////////////////////////////////////////////////////////////

  public Func onEvent(Win self, String type, boolean useCapture, Func fn)
  {
    listeners.add(new DomNodePeer.Listener(type, useCapture, fn));
    return fn;
  }

  public void removeEvent(Win self, String type, boolean useCapture, Func fn)
  {
    for (int i=0; i<listeners.size(); i++)
      if (((DomNodePeer.Listener)listeners.get(i)).matches(type, useCapture, fn)) { listeners.remove(i); return; }
  }

  // Fire the window's listeners for an event.  The window sits above
  // the document in the event path.  Pass true for the capture phase,
  // false for the bubble phase, or null for both
  void fire(Event event, Boolean capture) { DomNodePeer.fire(listeners, event, capture); }

//////////////////////////////////////////////////////////////////////////
// Timers
//////////////////////////////////////////////////////////////////////////

  public long setTimeout(Win self, Duration delay, Func fn)
  {
    return add(new Task(self, fn, null, delay.ticks(), 0));
  }

  public long setInterval(Win self, Duration delay, Func fn)
  {
    return add(new Task(self, fn, null, delay.ticks(), Math.max(delay.ticks(), minInterval)));
  }

  public void clearTimeout(Win self, long id) { clear(id); }

  public void clearInterval(Win self, long id) { clear(id); }

  public void reqAnimationFrame(Win self, Func fn)
  {
    Task t = new Task(self, fn, null, 0, 0);
    t.frame = true;
    add(t);
  }

  // Queue a task to run on the next call to runTimers.  Used for
  // events which a browser fires asynchronously, such as the toggle
  // event of a popover
  void queueTask(Runnable r) { add(new Task(null, null, r, 0, 0)); }

  private long add(Task t)
  {
    t.id = ++lastId;
    t.due += now;
    tasks.add(t);
    return t.id;
  }

  private void clear(long id)
  {
    for (int i=0; i<tasks.size(); i++)
      if (((Task)tasks.get(i)).id == id) { tasks.remove(i); return; }
  }

  // Advance the clock by the given time and run everything which
  // comes due.  The order matches a browser:
  //   1. deliver pending mutation records
  //   2. run animation frames requested before this call
  //   3. run timers in order of their due time
  // Timers queued by a task also run if they come due within the
  // elapsed time
  public void runTimers(Win self, Duration elapsed)
  {
    long end = now + elapsed.ticks();
    MutationObserverPeer.deliver(this);

    Object[] frames = tasks.toArray();
    for (int i=0; i<frames.length; i++)
    {
      Task t = (Task)frames[i];
      if (t.frame && tasks.remove(t)) run(t);
    }

    for (int n=0; true; n++)
    {
      Task t = nextDue(end);
      if (t == null) break;
      if (n > maxTasks) throw Err.make("Win.runTimers: timers queue timers without end");
      now = Math.max(now, t.due);
      if (t.interval > 0) t.due += t.interval; else tasks.remove(t);
      run(t);
    }
    now = end;
  }

  private void run(Task t)
  {
    if (t.run != null) t.run.run(); else t.fn.call(t.win);
    MutationObserverPeer.deliver(this);
  }

  // Find the next timer due at or before the end time.  If two are
  // due at the same time, the one queued first wins
  private Task nextDue(long end)
  {
    Task best = null;
    for (int i=0; i<tasks.size(); i++)
    {
      Task t = (Task)tasks.get(i);
      if (t.frame || t.due > end) continue;
      if (best == null || t.due < best.due) best = t;
    }
    return best;
  }

  static class Task
  {
    Task(Win win, Func fn, Runnable run, long due, long interval)
    {
      this.win = win; this.fn = fn; this.run = run; this.due = due; this.interval = interval;
    }
    final Win win;
    final Func fn;         // callback of a timer or frame
    final Runnable run;    // or a task of the dom itself
    final long interval;   // nanos between calls, or zero to call once
    long id;
    long due;              // nanos on the clock of the window
    boolean frame;         // animation frame
  }

//////////////////////////////////////////////////////////////////////////
// History
//////////////////////////////////////////////////////////////////////////

  public Uri uri(Win self) { return entry().uri; }

  // A browser would load a new page.  Here we only update the uri
  public void hyperlink(Win self, Uri uri) { push(uri, emptyState()); }

  public void reload(Win self, boolean force) {}

  public Map hisState(Win self) { return entry().state; }

  public void hisPushState(Win self, String title, Uri uri, Map map) { push(uri, map); }

  public void hisReplaceState(Win self, String title, Uri uri, Map map)
  {
    history.set(hisIndex, new HisEntry(uri, map));
  }

  public void hisBack(Win self) { go(self, -1); }

  public void hisForward(Win self) { go(self, 1); }

  private void push(Uri uri, Map state)
  {
    while (history.size() > hisIndex + 1) history.remove(history.size() - 1);
    history.add(new HisEntry(uri, state));
    hisIndex++;
  }

  // Move back or forward in the history, then fire popstate
  // asynchronously with the state copied into the event's stash
  private void go(final Win self, int delta)
  {
    int i = hisIndex + delta;
    if (i < 0 || i >= history.size()) return;
    hisIndex = i;
    final Map state = entry().state;
    queueTask(new Runnable() { public void run()
    {
      Event e = Event.makeCustom("popstate", null);
      e.stash().setAll(state);
      fire(e, null);
    }});
  }

  private HisEntry entry() { return (HisEntry)history.get(hisIndex); }

  private static Map emptyState() { return Map.make(Sys.StrType, Sys.ObjType); }

  static class HisEntry
  {
    HisEntry(Uri uri, Map state) { this.uri = uri; this.state = state; }
    final Uri uri;
    final Map state;
  }

//////////////////////////////////////////////////////////////////////////
// Clipboard and Storage
//////////////////////////////////////////////////////////////////////////

  public void clipboardReadText(final Win self, final Func f)
  {
    final String text = clipboard;
    queueTask(new Runnable() { public void run() { f.call(text); } });
  }

  public void clipboardWriteText(Win self, String text) { clipboard = text; }

  public Storage sessionStorage(Win self)
  {
    if (sessionStorage == null) sessionStorage = Storage.make();
    return sessionStorage;
  }

  public Storage localStorage(Win self)
  {
    if (localStorage == null) localStorage = Storage.make();
    return localStorage;
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private static Err err() { return UnsupportedErr.make(); }

  private static final long minInterval = 1000000L;   // 1ms
  private static final int maxTasks = 100000;

  private Doc doc;
  private TextSel textSel;
  private Storage sessionStorage;
  private Storage localStorage;
  private String clipboard = "";
  private final ArrayList listeners = new ArrayList();   // DomNodePeer.Listener
  private final ArrayList tasks = new ArrayList();       // Task
  private long now;                                      // nanos
  private long lastId;
  private final ArrayList history = new ArrayList();     // HisEntry
  private int hisIndex = 0;
  { history.add(new HisEntry(Uri.fromStr("about:blank"), emptyState())); }

  final ArrayList pendingObservers = new ArrayList();    // MutationObserver
}
