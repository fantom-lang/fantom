//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 09  Andy Frank     Creation
//    7 Jan 23  Kiera O'Flynn  Integration w/ Node JS
//

/**
 * File.
 */
fan.sys.File = fan.sys.Obj.$extend(fan.sys.Obj);

fan.sys.File.prototype.$ctor = function() {}
fan.sys.File.prototype.$typeof = function() { return fan.sys.File.$type; }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

fan.sys.File.make = function(uri, checkSlash)
{
  if (typeof uri == "string") uri = fan.sys.Uri.fromStr(uri);
  if (checkSlash === undefined) checkSlash = true;

  var f;

  if (fan.sys.Env.$nodejs)
  {
    // Create nodejs instance
    f = fan.sys.LocalFile.make(uri);
  }
  else
  {
    // Create "empty" instance as backup
    console.log("Warning: not running on Node JS, dummy file object returned");
    var f = new fan.sys.File();
    f.m_uri = uri;
    return f;
  }

  // Check slash
  if (f.exists())
  {
    if (f.isDirectory() && !checkSlash && !uri.isDir())
      f.m_uri = uri.plusSlash();
    else if (f.isDirectory() && !uri.isDir())
      throw fan.sys.IOErr.make("Must use trailing slash for dir: " + uri.toStr());
    else if (!f.isDirectory() && uri.isDir())
      throw fan.sys.IOErr.make("Cannot use trailing slash for file: " + uri.toStr());
  }
  else if (f.isDir() && fan.sys.Str.size(f.m_uri.toStr()) > 1)
  {
    var altStr = fan.sys.Str.getRange(f.m_uri.toStr(), new fan.sys.Range(0, -2));
    var fAlt = fan.sys.File.make(fan.sys.Uri.fromStr(altStr));
    if (fAlt.exists() && !fAlt.isDirectory())
      throw fan.sys.IOErr.make("Cannot use trailing slash for file: " + uri.toStr());
  }

  f.m_uri_str = f.m_uri.toStr();

  return f;
}

// TODO : what would the difference be?
fan.sys.File.os = function(osPath)
{
  if (!fan.sys.Env.$nodejs)
    throw fan.sys.Err.make("Must be running on Node JS to create a local file.");
  var path = require('path');
  var url  = require('url');
  var os   = require('os');
  if (os.platform() == "win32") {
    if (osPath.startsWith("/")) {
      osPath = "file://" + osPath;
    } else if (/^.+:/.test(osPath)) {
      osPath = "file:///" + osPath;
    }
  }
  return fan.sys.File.make(fan.sys.Uri.fromStr(osPath), false);
}

// TODO : only gets the root for the cwd
fan.sys.File.osRoots = function()
{
  if (!fan.sys.Env.$nodejs)
    throw fan.sys.Err.make("Must be running on Node JS to access the OS roots.");
  var path = require('path');
  var os   = require('os');
  var r = os.platform() == "win32"
    ? "/" + fan.sys.File._win32Drive() + "/"
    : path.parse(process.cwd()).root;
  return fan.sys.List.make(
           fan.sys.File.$type,
           [fan.sys.File.make(r, false)]
         );
}

fan.sys.File._win32Drive = function()
{
  var path = require('path');
  return process.cwd().split(path.sep)[0]
}

fan.sys.File._tempCt = 0;

fan.sys.File.createTemp = function(prefix, suffix, dir)
{
  if (prefix === undefined) prefix = "fan";
  if (suffix === undefined) suffix = ".tmp";
  if (dir === undefined)    dir = null;

  if (dir == null)
    dir = fan.sys.Env.cur().tempDir();
  else if (!dir.isDir())
    throw fan.sys.IOErr.make("Not a directory: " + dir.toStr());
  else if (!(dir instanceof fan.sys.LocalFile))
    throw fan.sys.IOErr.make("Dir is not on local file system: " + dir.toStr());
  
  var f;
  do
  {
    f = fan.sys.LocalFile.make(
          fan.sys.Uri.fromStr(
              dir.toStr() + prefix + fan.sys.File._tempCt + suffix
          ));
    fan.sys.File._tempCt++;
  }
  while (f.exists());
  return f.create();
}

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.equals = function(that)
{
  if (that && that instanceof fan.sys.File)
    return this.m_uri.equals(that.m_uri);
  return false;
}

fan.sys.File.prototype.hash     = function() { return this.m_uri.hash(); }
fan.sys.File.prototype.toStr    = function() { return this.m_uri_str; }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.uri      = function() { return this.m_uri; }
fan.sys.File.prototype.isDir    = function() { return this.m_uri.isDir(); }
fan.sys.File.prototype.path     = function() { return this.m_uri.path(); }
fan.sys.File.prototype.pathStr  = function() { return this.m_uri.pathStr(); }
fan.sys.File.prototype.$name    = function() { return this.m_uri.$name(); }
fan.sys.File.prototype.basename = function() { return this.m_uri.basename(); }
fan.sys.File.prototype.ext      = function() { return this.m_uri.ext(); }
fan.sys.File.prototype.mimeType = function() { return this.m_uri.mimeType(); }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

// Returns whether the file is *internally* a directory, rather than just using the uri
fan.sys.File.prototype.isDirectory = function() { this._throwNotSupported("isDirectory"); }

fan.sys.File.prototype.exists   = function() { return true; }
fan.sys.File.prototype.size     = function() { this._throwNotSupported("size"); }

fan.sys.File.prototype.isEmpty  = function()
{
  if (this.isDir()) return this.list().isEmpty();
  var size = this.size();
  return size == null || size <= 0;
}

fan.sys.File.prototype.modified = function() { this._throwNotSupported("modified"); }
fan.sys.File.prototype.modified$ = function(val) { this._throwNotSupported("modified"); }

fan.sys.File.prototype.isHidden     = function() { this._throwNotSupported("isHidden"); }
fan.sys.File.prototype.isReadable   = function() { return false; }
fan.sys.File.prototype.isWritable   = function() { return false; }
fan.sys.File.prototype.isExecutable = function() { return false; }

fan.sys.File.prototype.osPath   = function() { this._throwNotSupported("osPath"); }
fan.sys.File.prototype.parent   = function() { this._throwNotSupported("parent"); }
fan.sys.File.prototype.list     = function(pattern) { this._throwNotSupported("list"); }

fan.sys.File.prototype.listDirs = function(pattern)
{
  if (pattern === undefined) pattern = null;

  var list = this.list(pattern);
  if (list.isEmpty()) return list;
  return fan.sys.File._filter(list, (f) => f.isDir());
}

fan.sys.File.prototype.listFiles = function(pattern)
{
  if (pattern === undefined) pattern = null;

  var list = this.list(pattern);
  if (list.isEmpty()) return list;
  return fan.sys.File._filter(list, (f) => !f.isDir());
}

fan.sys.File.prototype.walk = function(c)
{
  c.call(this);
  if (this.isDir())
  {
    var list = this.list();
    for (var i=0; i<list.size(); ++i)
      (list.get(i)).walk(c);
  }
}

fan.sys.File.prototype.normalize = function() { this._throwNotSupported("normalize"); }

fan.sys.File.prototype.plus = function(uri, checkSlash)
{
  if (typeof uri == "string") uri = fan.sys.Uri.fromStr(uri);
  return fan.sys.File.make(this.m_uri.plus(uri), checkSlash);
}

fan.sys.File.prototype.store = function() { this._throwNotSupported("store"); }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.create = function() { this._throwNotSupported("create"); }

fan.sys.File.prototype.createFile = function(name)
{
  if (!this.isDir()) throw IOErr.make("Not a directory: " + this.toStr());
  return this.plus(fan.sys.Uri.fromStr(name)).create();
}

fan.sys.File.prototype.createDir = function(name)
{
  if (!this.isDir()) throw IOErr.make("Not a directory: " + this.toStr());
  if (!fan.sys.Str.endsWith(name, "/")) name = name + "/";
  return this.plus(fan.sys.Uri.fromStr(name)).create();
}

fan.sys.File.prototype.$delete      = function() { this._throwNotSupported("delete"); }
fan.sys.File.prototype.deleteOnExit = function() { this._throwNotSupported("deleteOnExit"); }

//////////////////////////////////////////////////////////////////////////
// Copy
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.copyTo = function(to, options)
{
  if (options === undefined) options = null;

  // sanity
  if (this.isDir() != to.isDir())
  {
    if (this.isDir())
      throw fan.sys.ArgErr.make("copyTo must be dir `" + to.toStr() + "`");
    else
      throw fan.sys.ArgErr.make("copyTo must not be dir `" + to.toStr() + "`");
  }

  // options
  var exclude = null, overwrite = null;
  if (options != null)
  {
    exclude = options.get("exclude");
    overwrite = options.get("overwrite");
  }

  // recurse
  this.doCopyTo(to, exclude, overwrite);
  return to;
}

fan.sys.File.prototype.doCopyTo = function(to, exclude, overwrite)
{
  // check exclude
  if (exclude instanceof fan.sys.Regex)
  {
    if (exclude.matches(this.m_uri.toStr())) return;
  }
  else if (exclude instanceof fan.sys.Func)
  {
    if (exclude.call(this)) return;
  }

  // check for overwrite
  if (to.exists())
  {
    if (typeof overwrite == "boolean")
    {
      if (!overwrite) return;
    }
    else if (overwrite instanceof fan.sys.Func)
    {
      if (!overwrite.m_func.apply(null, [to, this])) return;
    }
    else
    {
      throw fan.sys.IOErr.make("No overwrite policy for `" + to.toStr() + "`");
    }
  }

  // copy directory
  if (this.isDir())
  {
    to.create();
    var kids = this.list();
    for (var i=0; i<kids.size(); ++i)
    {
      var kid = kids.get(i);
      kid.doCopyTo(to.plusNameOf(kid), exclude, overwrite);
    }
  }

  // copy file contents
  else this.doCopyFile(to);
}

fan.sys.File.prototype.doCopyFile = function(to)
{
  var out = to.out();
  try
  {
    this.$in().pipe(out);
  }
  finally
  {
    out.close();
  }
}

fan.sys.File.prototype.copyInto = function(dir, options)
{
  if (options === undefined) options = null;

  if (!dir.isDir())
    throw fan.sys.ArgErr.make("Not a dir: `" + dir.toStr() + "`");

  return this.copyTo(dir.plusNameOf(this), options);
}

//////////////////////////////////////////////////////////////////////////
// Move
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.moveTo = function(to) { this._throwNotSupported("moveTo"); }

fan.sys.File.prototype.moveInto = function(dir)
{
  if (!dir.isDir())
    throw fan.sys.ArgErr.make("Not a dir: `" + dir.toStr() + "`");

  return this.moveTo(dir.plusNameOf(this));
}

fan.sys.File.prototype.rename = function(newName)
{
  if (this.isDir()) newName += "/";
  var parent = this.parent();
  if (parent == null)
    return this.moveTo(fan.sys.File.make(fan.sys.Uri.fromStr(newName)));
  else
    return this.moveTo(parent.plus(fan.sys.Uri.fromStr(newName)));
}

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype.open = function(mode) { this._throwNotSupported("open"); }
fan.sys.File.prototype.mmap = function(mode, pos, size) { this._throwNotSupported("mmap"); }
fan.sys.File.prototype.$in   = function(bufSize) { this._throwNotSupported("in"); }
fan.sys.File.prototype.out  = function(append, bufSize) { this._throwNotSupported("out"); }

fan.sys.File.prototype.readAllBuf = function()
{
  return this.$in(fan.sys.Int.Chunk).readAllBuf();
}

fan.sys.File.prototype.readAllLines = function()
{
  return this.$in(fan.sys.Int.Chunk).readAllLines();
}

fan.sys.File.prototype.eachLine = function(f)
{
  this.$in(fan.sys.Int.Chunk).eachLine(f);
}

fan.sys.File.prototype.readAllStr = function(normalizeNewlines)
{
  if (normalizeNewlines === undefined) normalizeNewlines = true;
  return this.$in(fan.sys.Int.Chunk).readAllStr(normalizeNewlines);
}

fan.sys.File.prototype.readProps = function()
{
  return this.$in(fan.sys.Int.Chunk).readProps();
}

fan.sys.File.prototype.writeProps = function(props)
{
  this.out(false, fan.sys.Int.Chunk).writeProps(props, true);
}

fan.sys.File.prototype.readObj = function(options)
{
  if (options === undefined) options = null;
  var ins = this.$in();
  try
  {
    return ins.readObj(options);
  }
  finally
  {
    ins.close();
  }
}

fan.sys.File.prototype.writeObj = function(obj, options)
{
  if (options === undefined) options = null;
  var out = this.out();
  try
  {
    out.writeObj(obj, options);
  }
  finally
  {
    out.close();
  }
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

fan.sys.File.sep     = function() { this._throwNotSupported("sep"); }
fan.sys.File.pathSep = function() { this._throwNotSupported("pathSep"); }

//////////////////////////////////////////////////////////////////////////
// Helper functions
//////////////////////////////////////////////////////////////////////////

fan.sys.File.prototype._throwNotSupported = function(name)
{
  throw fan.sys.UnsupportedErr.make("File." + name + " is not implemented in this environment.");
}

fan.sys.File._filter = function(list, p)
{
  var acc = fan.sys.List.make(fan.sys.File.$type, []);
  for (var i=0; i<list.size(); ++i)
  {
    var f = list.get(i);
    if (p(f))
      acc.add(f);
  }
  return acc;
}

fan.sys.File.prototype.plusNameOf = function(x)
{
  var name = x.$name();
  if (x.isDir()) name += "/";
  return this.plus(fan.sys.Uri.fromStr(name));
}