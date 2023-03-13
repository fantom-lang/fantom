//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Mar 2023  Matthew Giannini  Creation
//

/**
 * MemFile
 */

fan.sys.MemFile = fan.sys.Obj.$extend(fan.sys.File);
fan.sys.MemFile.prototype.$ctor = function()
{
  fan.sys.File.prototype.$ctor.call();
}
fan.sys.MemFile.prototype.$typeof = function() { return fan.sys.MemFile.$type; }

fan.sys.MemFile.make = function(buf, uri)
{
  var instance = new fan.sys.MemFile();
  instance.m_buf = buf;
  instance.m_uri = uri;
  instance.m_ts  = fan.sys.DateTime.now();
  return instance;
}

fan.sys.MemFile.prototype.exists = function() { return true; }
fan.sys.MemFile.prototype.size = function() { return this.m_buf.size(); }
fan.sys.MemFile.prototype.modified = function() { throw this.err(); }
fan.sys.MemFile.prototype.modified$ = function() { throw this.err(); }
fan.sys.MemFile.prototype.osPath = function() { return null; }
fan.sys.MemFile.prototype.parent = function() { return null; }
fan.sys.MemFile.prototype.list = function(regex)
{
  return fan.sys.List.make(fan.sys.File.$type, []);
}
fan.sys.MemFile.prototype.normalize = function() { return this; }
fan.sys.MemFile.prototype.plus = function(uri, checkSlash) { throw this.err(); }
fan.sys.MemFile.prototype.create = function() { throw this.err(); }
fan.sys.MemFile.prototype.moveTo = function(to) { throw this.err(); }
fan.sys.MemFile.prototype.delete = function() { throw this.err(); }
fan.sys.MemFile.prototype.deleteOnExit = function() { throw this.err(); }
fan.sys.MemFile.prototype.open = function(mode) { throw this.err(); }
fan.sys.MemFile.prototype.mmap = function(mode, pos, size) { throw this.err(); }
fan.sys.MemFile.prototype.$in = function(bufSize) { return this.m_buf.$in(); }
fan.sys.MemFile.prototype.out = function(append, bufSize) { throw this.err(); }
fan.sys.MemFile.prototype.toStr = function() { return this.m_uri.toStr(); }
fan.sys.MemFile.prototype.err = function()
{
  return fan.sys.UnsupportedErr.make("MemFile");
}