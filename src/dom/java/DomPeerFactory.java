//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Feb 2023  Brian Frank  Creation
//

package fan.dom;

import fan.sys.*;

public class DomPeerFactory
{
  public static DomPeerFactory factory() { return factory; }

  public static void install(DomPeerFactory f) { factory = f; }

  private static DomPeerFactory factory = new DomPeerFactory();

  public DataTransferPeer makeDataTransfer(DataTransfer fan)
  {
    return new DataTransferPeer();
  }

  public DocPeer makeDoc(Doc fan)
  {
    return new DocPeer();
  }

  public DomFilePeer makeDomFile(DomFile fan)
  {
    return new DomFilePeer();
  }

  public ElemPeer makeElem(Elem fan)
  {
    return new ElemPeer();
  }

  public EventPeer makeEvent(Event fan)
  {
    return new EventPeer();
  }

  public HttpReqPeer makeHttpReq(HttpReq fan)
  {
    return new HttpReqPeer();
  }

  public StoragePeer makeStorage(Storage fan)
  {
    return new StoragePeer();
  }

  public StylePeer makeStyle(Style fan)
  {
    return new StylePeer();
  }

  public WinPeer makeWin(Win win)
  {
    return new WinPeer();
  }

  public Win winCur()
  {
    throw UnsupportedErr.make("Win.cur");
  }

  public Object winEval(String js)
  {
    throw UnsupportedErr.make("Win.eval");
  }

  public Elem elemFromNative(Object elem, Type type)
  {
    throw UnsupportedErr.make("elem.fromNative");
  }

  public Event eventFromNative(Object event)
  {
    throw UnsupportedErr.make("event.fromNative");
  }
}
