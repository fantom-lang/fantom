//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Jan 09   Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//   8 Jul 09   Andy Frank  Split webappClient into sys/dom
//   10 Jun 2023  Kiera O'Flynn  Refactor to ES
//

class DocPeer extends sys.Obj {

  constructor(self) { super(); }

  doc;

  title(self, it)
  {
    if (it===undefined) return this.doc.title;
    else this.doc.title = it;
  }

  head(self)
  {
    return ElemPeer.wrap(this.doc.head);
  }

  body(self)
  {
    return ElemPeer.wrap(this.doc.body);
  }

  activeElem(self)
  {
    const elem = this.doc.activeElement;
    if (elem == null) return null;
    return ElemPeer.wrap(elem);
  }

  elemById(self, id)
  {
    const elem = this.doc.getElementById(id);
    if (elem == null) return null;
    return ElemPeer.wrap(elem);
  }

  createElem(self, tagName, attribs, ns)
  {
    const elem = ns
      ? this.doc.createElementNS(ns.toStr, tagName)
      : this.doc.createElement(tagName);
    const wrap = ElemPeer.wrap(elem);
    if (attribs != null)
    {
      const k = attribs.keys();
      for (let i=0; i<k.size(); i++)
        wrap.set(k.get(i), attribs.get(k.get(i)));
    }
    return wrap;
  }

  createFrag(self)
  {
    const frag = this.doc.createDocumentFragment();
    return ElemPeer.wrap(frag);
  }

  querySelector(self, selectors)
  {
    const elem = this.doc.querySelector(selectors);
    if (elem == null) return null;
    return ElemPeer.wrap(elem);
  }

  querySelectorAll(self, selectors)
  {
    const list  = sys.List.make(Elem.type$);
    const elems = this.doc.querySelectorAll(selectors);
    for (let i=0; i<elems.length; i++)
      list.add(ElemPeer.wrap(elems[i]));
    return list;
  }

  querySelectorAllType(self, selectors, type)
  {
    const list  = sys.List.make(Elem.type$);
    const elems = this.doc.querySelectorAll(selectors);
    for (let i=0; i<elems.length; i++)
      list.add(ElemPeer.wrap(elems[i], type.make()));
    return list;
  }

  exportPng(self, img)
  {
    return this.#export(img, "image/png");
  }

  exportJpg(self, img, quality)
  {
    return this.#export(img, "image/jpeg", quality);
  }

  #export(img, mimeType, quality)
  {
    const elem = img.peer.elem;

    // set phy canvas size to img
    const canvas = this.doc.createElement("canvas");
    canvas.style.width  = elem.width  + "px";
    canvas.style.height = elem.height + "px";

    // scale up working space if retina
    const ratio   = window.devicePixelRatio || 1;
    canvas.width  = ratio * elem.width;
    canvas.height = ratio * elem.height;

    // render with scale factor
    const cx = canvas.getContext("2d");
    cx.scale(ratio, ratio);
    cx.drawImage(elem, 0, 0);
    return canvas.toDataURL(mimeType, quality);
  }

  onEvent(self, type, useCapture, handler)
  {
    handler.$func = function(e) { handler(EventPeer.make(e)); }
    this.doc.addEventListener(type, handler.$func, useCapture);
    return handler;
  }

  removeEvent(self, type, useCapture, handler)
  {
    if (handler.$func)
      this.doc.removeEventListener(type, handler.$func, useCapture);
  }

  exec(self, name, defUi, val)
  {
    return this.doc.execCommand(name, defUi, val);
  }

  out(self)
  {
    return web.WebOutStream.make(new DocOutStream(this.doc));
  }

  getCookiesStr(self) { return this.doc.cookie; }

  addCookie(self,c)
  {
    // always force HttpOnly otherwise this is a no-op for browsers
    c.__httpOnly(false)
    this.doc.cookie = c.toStr();
  }
}

/*************************************************************************
 * DocOutStream
 ************************************************************************/

class DocOutStream extends sys.OutStream {

  constructor(doc)
  {
    super();
    this.#doc = doc;
  }

  #doc;

  w(v)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  write(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeBuf(buf, n)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeI2(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeI4(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeI8(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeF4(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeF8(x)
  {
    throw sys.UnsupportedErr.make("binary write on Doc output");
  }

  writeUtf(x)
  {
    throw sys.UnsupportedErr.make("modified UTF-8 format write on StrBuf output");
  }

  writeChar(c)
  {
    this.#doc.write(String.fromCharCode(c));
  }

  writeChars(s, off, len)
  {
    if (off === undefined) off = 0;
    if (len === undefined) len = s.length-off;
    this.#doc.write(s.slice(off, off+len));
    return this;
  }

  flush() { return this; }

  close()
  {
    this.#doc.close();
    return true;
  }
}