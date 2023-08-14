//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Mar 2023  Matthew Giannini  Creation
//   30 Jun 2023  Matthew Giannini  Refactor for ES
//

/**
 * MemFile
 */
class MemFile extends File {

  constructor(buf, uri) { 
    super(uri); 
    this.#buf = buf;
    this.#ts  = DateTime.now();
  }

  #buf;
  #ts;

  static make(buf, uri) {
    const instance = new MemFile(buf, uri);
    return instance;
  }

  exists() { return true; }
  size() { return this.#buf.size(); }
  modified(it) { 
    if (it === undefined) return this.#ts;
    throw this.err(); 
  }
  osPath() { return null; }
  parent() { return null; }
  list(regex) { return List.make(File.type$, []); }
  normalize() { return this; }
  plus(uri, checkSlash) { throw this.err(); }
  create() { throw this.err(); }
  moveTo(to) { throw this.err(); }
  delete() { throw this.err(); }
  deleteOnExit() { throw this.err(); }
  open(mode) { throw this.err(); }
  mmap(mode, pos, size) { throw this.err(); }
  in$(bufSize) { return this.#buf.in$(); }
  out(append, bufSize) { throw this.err(); }
  toStr() { return this.uri().toStr(); }
  err() { return UnsupportedErr.make("MemFile"); }
}