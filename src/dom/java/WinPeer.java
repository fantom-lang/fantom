//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class WinPeer
{
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

  // userAgent() is required to exist by Win.make()
  public String userAgent(Win self)
  {
    return "Fantom/" + self.typeof().pod().version().toString();
  }

  public Win     open              (Win self, Uri uri, String winName, Map opts)        { throw err(); }
  public Win     close             (Win self)                                           { throw err(); }
  public Doc     doc               (Win self)                                           { throw err(); }
  public TextSel textSel           (Win self)                                           { throw err(); }
  public void    addStyleRules     (Win self, String rules)                             { throw err(); }
  public void    alert             (Win self, Object obj)                               { throw err(); }
  public boolean confirm           (Win self, Object obj)                               { throw err(); }
  public Win     parent            (Win self)                                           { throw err(); }
  public Win     top               (Win self)                                           { throw err(); }
  public Object  log               (Win self, Object obj)                               { throw err(); }
  public Win     scrollTo          (Win self, long x, long y)                           { throw err(); }
  public Win     scrollBy          (Win self, long x, long y)                           { throw err(); }
  public Uri     uri               (Win self)                                           { throw err(); }
  public void    hyperlink         (Win self, Uri uri)                                  { throw err(); }
  public void    reload            (Win self, boolean force)                            { throw err(); }
  public void    clipboardReadText (Win self, Func f)                                   { throw err(); }
  public void    clipboardWriteText(Win self, String text)                              { throw err(); }
  public void    hisBack           (Win self)                                           { throw err(); }
  public void    hisForward        (Win self)                                           { throw err(); }
  public void    hisPushState      (Win self, String title, Uri uri, Map map)           { throw err(); }
  public void    hisReplaceState   (Win self, String title, Uri uri, Map map)           { throw err(); }
  public Func    onEvent           (Win self, String type, boolean useCapture, Func fn) { throw err(); }
  public void    removeEvent       (Win self, String type, boolean useCapture, Func fn) { throw err(); }
  public void    reqAnimationFrame (Win self, Func fn)                                  { throw err(); }
  public long    setTimeout        (Win self, Duration delay, Func fn)                  { throw err(); }
  public void    clearTimeout      (Win self, long timeoutId)                           { throw err(); }
  public long    setInterval       (Win self, Duration delay, Func fn)                  { throw err(); }
  public void    clearInterval     (Win self, long intervalId)                          { throw err(); }
  public void    geoCurPosition    (Win self, Func onSuccess, Func onErr, Map opts)     { throw err(); }
  public long    geoWatchPosition  (Win self, Func onSuccess, Func onErr, Map opts)     { throw err(); }
  public void    geoClearWatch     (Win self, long id)                                  { throw err(); }
  public Storage sessionStorage    (Win self)                                           { throw err(); }
  public Storage localStorage      (Win self)                                           { throw err(); }
  public Map     diagnostics       (Win self)                                           { throw err(); }

// cannot compile against "graphics" pod - see https://fantom.org/forum/topic/2886
// public Size   viewport          (Win self)                                           { throw err(); }
// public Size   screenSize        (Win self)                                           { throw err(); }
// public Point  scrollPos         (Win self)                                           { throw err(); }

  private static Err err() { return UnsupportedErr.make(); }
}
