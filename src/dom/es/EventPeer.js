//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Feb 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//    8 Jul 2009  Andy Frank  Split webappClient into sys/dom
//   26 Aug 2015  Andy Frank  Rename back to Event
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class EventPeer extends sys.Obj {

  constructor(self) { super(); }

  event;
  static lastDataTx;

  static makeMock()
  {
    return EventPeer.make(new js.Event("mock"));
  }

  static fromNative(obj)
  {
    return EventPeer.make(obj);
  }

  type(self) { return this.event.type; }

  #target;
  target(self)
  {
    if (this.#target == null)
    {
      // 8 May 2019 - Andy Frank:
      // Firefox 66.0.5 is firing events with TEXT_NODE as targets; I'm not
      // sure if this is new behavior (or correct behavoir) -- but since the
      // Fantom DOM pod only handles ELEMENT_NODE; walk up to the parent
      let t = this.event.target;
      if (t.nodeType == 3) t = t.parentNode;
      this.#target = ElemPeer.wrap(t);
    }
    return this.#target;
  }

  #pagePos;
  pagePos(self)
  {
    if (this.#pagePos == null)
      this.#pagePos = graphics.Point.makeInt(this.event.pageX || 0, this.event.pageY || 0);
    return this.#pagePos;
  }

  alt(self)   { return this.event.altKey; }
  ctrl(self)  { return this.event.ctrlKey; }
  shift(self) { return this.event.shiftKey; }
  meta (self) { return this.event.metaKey; }
  button(self) { return this.event.button; }

  $key;
  key(self)   { return this.$key }

  #delta;
  delta(self)
  {
    if (this.#delta == null)
    {
      this.#delta = this.event.deltaX != null && this.event.deltaY != null
        ? graphics.Point.makeInt(this.event.deltaX, this.event.deltaY)
        : graphics.Point.defVal();
    }
    return this.#delta;
  }

  #err;
  err(self)
  {
    if (this.event.error == null) return null;
    if (this.#err == null) this.#err = sys.Err.make(this.event.error);
    return this.#err;
  }

  stop(self)
  {
    this.event.preventDefault();
    this.event.stopPropagation();
    this.event.cancelBubble = true;
    this.event.returnValue = false;
  }

  get(self, name, def)
  {
    const val = this.event[name];
    if (val != null) return val;
    if (def != null) return def;
    return null;
  }

  set(self, name, val)
  {
    this.event[name] = val;
  }

  dataTransfer(self)
  {
    // Andy Frank 19-Jun-2015: Chrome/WebKit do not allow reading
    // getData during the dragover event - which makes it impossible
    // to check drop targets during drag. To workaround for now we
    // just cache in a static field
    //
    // 12-Aug-2019: this logic needed to be tweaked a bit to add
    // support for dragging files into the browser - the lastDataTx
    // temp copy should be cleared during EventPeer.make when we
    // detect either a 'drop' or 'dragend' event

    if (EventPeer.lastDataTx)
      return EventPeer.lastDataTx;

    if (!this.dataTx)
      this.dataTx = EventPeer.lastDataTx = DataTransferPeer.make(this.event.dataTransfer);

    return this.dataTx;
  }

  static make(event)
  {
    // map native to Fan
    const x = Event.make();
    x.peer.event = event;
    if (event.keyCode) x.peer.$key = Key.fromCode(event.keyCode);

    // we need to flush our working copy when we see a dragend
    // event; this allows us to request the real drop contents
    // which are hidden in alot of cases during ondrag
    if (event.type.charAt(0) == 'd' && (event.type == "drop" || event.type == "dragend"))
      EventPeer.lastDataTx = null

    return x;
  }
}