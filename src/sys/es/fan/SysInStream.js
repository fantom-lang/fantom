//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  01 Sep 2019  Andy Frank  Creation
//  06 Jul 2023  Matthew Giannini Refactor for ES
//

/**
 * SysInStream
 */
class SysInStream extends InStream {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  static make(ins) {
    const self = new SysInStream();
    SysInStream.make$(self, ins);
    return self;
  }

  static make$(self, ins) {
    InStream.make$(self, ins);
  }

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

}

/*************************************************************************
 * LocalFileInStream
 ************************************************************************/

class LocalFileInStream extends SysInStream {
  constructor(fd, bufSize) { 
    super(); 
    this.#fd  = fd;
    this.#buf = Buffer.alloc(bufSize);
    this.#load();
  }

  #fd;
  #pre = [];
  #buf;
  #start = 0;
  #end = 0;

  static make(fd, bufSize) {
    const self = new LocalFileInStream(fd, bufSize);
    LocalFileInStream.make$(self);
    return self;
  }

  static make$(self) {
    SysInStream.make$(self);
  }

  #load() {
    this.#start = 0;
    this.#end = node.fs.readSync(this.#fd, this.#buf);
    return this.#end - this.#start;
  }

  avail() {
    return this.#pre.length + (this.#end - this.#start);
  }

  #r() {
    try {
      if (this.avail() === 0)
        this.#load();
      else if (this.#pre.length > 0)
        return this.#pre.pop();

      if (this.avail() == 0) {
        return -1;
      }
      const x = this.#buf[this.#start++];
      return x
    }
    catch (e) {
      throw IOErr.make(e);
    }
  }

  read() {
    const n = this.#r();
    return n < 0 ? null : n;
  }

  readBuf(buf, n) {
    const out = buf.out();
    let read = 0;
    let r;
    while (n > 0) {
      r = this.read();
      if (r === null) break;
      out.write(r);
      n--;
      read++;
    }
    return read == 0 ? null : read;
  }

  unread(n) { 
    this.#pre.push(n); 
    return this;
  }

  skip(n) {
    let skipped = 0;

    if (this.#pre.length > 0) {
      const len = Math.min(this.#pre.length, n);
      this.#pre = this.#pre.slice(0, -len);
      skipped += len;
    }
    if (skipped == n) return skipped;

    if (this.avail() === 0) this.#load();

    while (true) {
      const a = this.avail();
      if (a === 0 || skipped == n) break;
      const rem = n - skipped;
      if (rem < a) {
        skipped += rem;
        this.#start += rem;
        break;
      }
      skipped += a;
      this.#load();
    }
    return skipped;
  }

  close() {
    try {
      node.fs.closeSync(this.#fd);
      return true;
    }
    catch (e) {
      return false;
    }
  }
}