//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//  01 Sep 2019  Andy Frank  Creation
//  07 Jul 2023  Matthew Giannini Refactor for ES
//

/**
 * SysOutStream
 */
class SysOutStream extends OutStream {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor() { super(); }

  static make(out) {
    const self = new SysOutStream();
    SysOutStream.make$(self, out);
    return self;
  }

  static make$(self, out) {
    OutStream.make$(self, out);
  }

/*
fan.sys.SysOutStream.make = function(out, bufSize)
{
  return new fan.sys.SysOutStream(fan.sys.SysOutStream.toBuffered(out, bufSize));
}

fan.sys.SysOutStream.toBuffered = function(out, bufSize)
{
  if (bufSize == null || bufSize == 0)
    return out;
  else
    return new java.io.BufferedOutputStream(out, bufSize);
}

fan.sys.SysOutStream.prototype.$ctor = function(out)
{
  fan.sys.OutStream.prototype.$ctor.call(this);
  this.out = out;
}
*/

//////////////////////////////////////////////////////////////////////////
// OutStream
//////////////////////////////////////////////////////////////////////////

  // w(v) {
  //   try {
  //     this.__out().write(v);
  //     return this;
  //   }
  //   catch (e) {
  //     throw IOErr.make(e).val;
  //   }
  // }

  // writeBuf(buf, n=buf.remaining()) {
  //   try {
  //     buf.pipeTo(this.__out(), n);
  //     return this;
  //   }
  //   catch (e) {
  //     throw IOErr.make(e);
  //   }
  // }

  // writeChar(c) {
  //   this.charset().__encoder().encodeOut(c, this);
  //   return this;
  // }

  // flush() {
  //   try {
  //     this.__out().flush();
  //     return this;
  //   }
  //   catch (e)
  //   {
  //     throw fan.sys.IOErr.make(e);
  //   }
  // }

  // close() {
  //   try
  //   {
  //     if (this.out != null) this.out.close();
  //     return true;
  //   }
  //   catch (e)
  //   {
  //     return false;
  //   }
  // }
}

/*************************************************************************
 * ConsoleOutStream
 ************************************************************************/

class ConsoleOutStream extends OutStream {
  constructor() { 
    super(); 
  }
  #buf = "";
  writeChar(c) {
    if (c == 10) this.flush();
    else this.#buf += String.fromCharCode(c);
  }
  write(v) {
    if (v == 10) this.flush();
    else this.#buf += String.fromCharCode(v)
  }
  flush() {
    if (this.#buf.length > 0 && console) console.log(this.#buf);
    this.#buf = "";
  }
}

/*************************************************************************
 * LocalFileOutStream
 ************************************************************************/

class LocalFileOutStream extends SysOutStream {
  constructor(fd) { 
    super(); 
    this.#fd = fd;
  }

  #fd;

  static make(fd) {
    const self = new LocalFileOutStream(fd);
    LocalFileOutStream.make$(self);
    return self;
  }

  static make$(self) {
    SysOutStream.make$(self);
  }

  write(v) {
    try {
      node.fs.writeSync(this.#fd, Buffer.from([v]));
      return this;
    }
    catch (e) {
      throw IOErr.make(e);
    }
  }

  writeBuf(buf, n=buf.remaining()) {
    if (buf.pos() + n > buf.size())
      throw IOErr.make("Not enough bytes to write");
    try {
      node.fs.writeSync(this.#fd, Buffer.from(buf.__getBytes(buf.pos(), n)));
      // writing a Buf needs to advance the position
      buf.seek(buf.pos() + n);
      return this;
    }
    catch (e) {
      throw IOErr.make(e);
    }
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