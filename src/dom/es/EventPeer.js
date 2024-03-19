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
    // short-circut if peer already exists
    if (obj.peer && obj.peer.event) return obj;
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

  #relatedTarget;
  relatedTarget(self)
  {
    if (this.#relatedTarget === undefined)
    {
      const rt = this.event.relatedTarget;
      this.#relatedTarget = rt == null ? null : ElemPeer.wrap(rt);
    }
    return this.#relatedTarget;
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
  key(self) { return this.$key }

  $keyChar;
  keyChar(self) { return this.$keyChar }

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

  data(self)
  {
    if (this.event.data == null) return null;
    if (this.#data == null)
    {
      var data = this.event.data;
      if (data instanceof ArrayBuffer)
      {
        data = sys.MemBuf.__makeBytes(data);
      }
      this.#data = data;
    }
    return this.#data;
  }
  #data;

  dataTransfer(self)
  {
    if (!this.dataTx) this.dataTx = DataTransferPeer.make(this.event.dataTransfer);
    return this.dataTx;
  }

  static make(event)
  {
    // map native to Fan
    const x = Event.make();
    x.peer.event = event;
    if (event.keyCode) x.peer.$key = Key.fromCode(event.keyCode);
    if (event.key) x.peer.$keyChar = event.key;
    return x;
  }
}