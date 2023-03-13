//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 10  Andy Frank     Creation
//   8 Jan 23  Kiera O'Flynn  Integration w/ Node JS
//


var fs = null;
if (typeof require !== "undefined") { fs = require('fs'); }

/**
 * LocalFile.
 */

fan.sys.LocalFile = fan.sys.Obj.$extend(fan.sys.File);
fan.sys.LocalFile.prototype.$ctor = function()
{
  fan.sys.File.prototype.$ctor.call();
}
fan.sys.LocalFile.prototype.$typeof = function() { return fan.sys.LocalFile.$type; }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.make = function(uri)
{
  if (uri.scheme() != null && uri.scheme() != "file")
    throw fan.sys.ArgErr.make("Invalid Uri scheme for local file: " + uri.toStr());
  var os = require('os');
  var url = require('url');
  var path = require('path');
  var instance = new fan.sys.LocalFile();
  instance.m_uri = uri;
  instance.m_uri_str = uri.toStr();

  // node cannot handle windows paths with leading '/' so we need
  // finagle the uri path into a format that works on unix and windows
  // console.log("TODO: normalize windows path: " + instance.m_uri_str);
  instance.m_node_os_path = uri.toStr();

  if (os.platform == "win32" && uri.isPathAbs()) {
    var uriStr = uri.toStr();
    if (!uri.isAbs()) {
      // ensure the uri has file scheme
      uriStr = "file://" + uriStr;
    }
    else if (!/^.+:/.test(uri.pathStr())) {
      // ensure paths that don't have drive are fixed to have drive
      // otherwise url.fileURLToPath barfs
      // file:/ok/path => file:///C:/ok/path
      uriStr = "file:///" + fan.sys.File._win32Drive() + uri.pathStr();
    }
    instance.m_node_os_path = url.fileURLToPath(uriStr).split(path.sep).join(path.posix.sep);
  }

  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.isDirectory = function()
{
  return this.exists() && fs.statSync(this.m_node_os_path).isDirectory();
}

fan.sys.LocalFile.prototype.exists = function() { return fs.existsSync(this.m_node_os_path); }

fan.sys.LocalFile.prototype.size = function()
{
  if (!this.exists() || this.isDirectory()) return null;
  return fs.statSync(this.m_node_os_path).size;
}

fan.sys.LocalFile.prototype.modified = function()
{
  if (!this.exists()) return null;
  return fan.sys.DateTime.fromJs(fs.statSync(this.m_node_os_path).mtime);
}

fan.sys.LocalFile.prototype.modified$ = function(val)
{
  throw fan.sys.UnsupportedErr.make("Node JS cannot set the last-modified time of a local file.");
}

fan.sys.LocalFile.prototype._checkAccess = (C) =>
(
  function()
  {
    try {
      fs.accessSync(this.m_node_os_path, C);
      return true;
    } catch (e) {
      return false;
    }
  }
)

fan.sys.LocalFile.prototype.isHidden = function()
{
  throw fan.sys.UnsupportedErr.make("Node JS cannot detect whether a local file is hidden.");
}
fan.sys.LocalFile.prototype.isReadable = function()
{
  return this._checkAccess(fs.constants.R_OK);
}
fan.sys.LocalFile.prototype.isWritable = function()
{
  return this._checkAccess(fs.constants.W_OK);
}
fan.sys.LocalFile.prototype.isExecutable = function()
{
  return this._checkAccess(fs.constants.X_OK);
}

fan.sys.LocalFile.prototype.osPath = function()
{
  return this.m_node_os_path;
}

fan.sys.LocalFile.prototype.parent = function()
{
  let parent = this.m_uri.parent();
  if (parent == null) return null;
  return fan.sys.LocalFile.make(parent);
}

fan.sys.LocalFile.prototype.list = function(pattern)
{
  if (!this.exists() || !this.isDir())
    return fan.sys.List.make(fan.sys.File.$type, []);

  var list = fs.readdirSync(this.m_node_os_path, { withFileTypes: true });

  var len = list == null ? 0 : list.length;
  var acc = fan.sys.List.make(fan.sys.File.$type, []);
  for (var i=0; i<len; ++i)
  {
    var f = list[i];
    var name = f.name;
    if (!pattern || pattern.matches(name))
      acc.add(fan.sys.LocalFile.make(this.m_uri.plusName(name, f.isDirectory())));
  }
  return acc;
}

fan.sys.LocalFile.prototype.normalize = function()
{
  var url = require('url');
  var path = require('path');
  var href = url.pathToFileURL(path.resolve(this.m_node_os_path)).href;
  var uri  = fan.sys.Uri.fromStr(href);
  return fan.sys.LocalFile.make(uri);
}

fan.sys.LocalFile.prototype.store = function()
{
  return new fan.sys.LocalFileStore();
}

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

// Helper create functions

fan.sys.LocalFile.prototype._createFile = function()
{
  if (this.isDirectory())
    throw fan.sys.IOErr.make("Already exists as dir: " + this.m_uri);

  if (this.exists())
    this.$delete();

  var parent = this.parent();
  if (parent != null && !parent.exists())
    parent.create();

  try
  {
    var out = fs.openSync(this.m_node_os_path, 'w');
    fs.close(out);
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.LocalFile.prototype._createDir = function()
{
  try
  {
    fs.mkdirSync(this.m_node_os_path, { recursive: true });
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.LocalFile.prototype.create = function()
{
  if (this.isDir())
    this._createDir();
  else
    this._createFile();
  return this;
}

fan.sys.LocalFile.prototype.$delete = function()
{
  if (!this.exists()) return;

  try
  {
    fs.rmSync(this.m_node_os_path, { recursive: true, force: true });
  }
  catch (e)
  {
    throw fan.sys.IOErr.make("Cannot delete: " + this.m_uri + "\n" + e);
  }
}

fan.sys.LocalFile._toDelete = [];

if (typeof process !== "undefined") {
process.on('SIGTERM', () => {
  fan.sys.LocalFile._toDelete.forEach((f) => {
    f.delete$();
  })
});
}

fan.sys.LocalFile.prototype.deleteOnExit = function()
{
  fan.sys.LocalFile._toDelete.push(this);
  return this;
}

//////////////////////////////////////////////////////////////////////////
// Copy
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.superDoCopyFile = fan.sys.File.prototype.doCopyFile;

fan.sys.LocalFile.prototype.doCopyFile = function(to)
{
  if (!(to instanceof fan.sys.LocalFile))
    return this.superDoCopyFile(to);

  fs.copyFileSync(this.m_node_os_path, to.m_node_os_path);
}

//////////////////////////////////////////////////////////////////////////
// Move
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.moveTo = function(to)
{
  if (this.isDir() != to.isDir())
  {
    if (this.isDir())
      throw fan.sys.ArgErr.make("moveTo must be dir `" + to.toStr() + "`");
    else
      throw fan.sys.ArgErr.make("moveTo must not be dir `" + to.toStr() + "`");
  }

  if (!(to instanceof fan.sys.LocalFile))
    throw fan.sys.IOErr.make("Cannot move LocalFile to " + to.$typeof());
  
  if (to.exists())
    throw fan.sys.IOErr.make("moveTo already exists: " + to.toStr());
  
  if (!this.exists())
    throw fan.sys.IOErr.make("moveTo source file does not exist: " + this.toStr());
  
  if (!this.isDirectory())
  {
    var destParent = to.parent();
    if (destParent != null && !destParent.exists())
      destParent.create();
  }

  try
  {
    // NOTE: this is very likely going to fail sometimes on windows and we can't
    // do async retries. so that is sad
    // https://stackoverflow.com/questions/32457363/eperm-while-renaming-directory-in-node-js-randomly
    fs.renameSync(this.m_node_os_path, to.m_node_os_path)
  }
  catch (e)
  {
    throw fan.sys.IOErr.make("moveTo failed: " + to.toStr(), fan.sys.IOErr.make(""+e));
  }

  return to;
}

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

// fan.sys.LocalFile.prototype.open = function(mode)
// {
//   if (!mode) mode = "rw";
// }

// TODO: mmap

fan.sys.LocalFile.prototype.$in = function(bufSize)
{
  if (!bufSize) bufSize = fan.sys.Int.Chunk;

  if (this.isDirectory())
    throw fan.sys.IOErr.make("cannot get in stream for a directory");

  var fd = fs.openSync(this.m_node_os_path, 'r');
  return this.m_in = new fan.sys.LocalFileInStream(fd, bufSize);
}

fan.sys.LocalFile.prototype.out = function(append, bufSize)
{
  if (append === undefined)  append = false;
  if (!bufSize) bufSize = fan.sys.Int.Chunk;

  if (this.isDirectory())
    throw fan.sys.IOErr.make("cannot get out stream for a directory");

  var flag = append ? 'a' : 'w';
  var fd = fs.openSync(this.m_node_os_path, flag);
  // TODO: add bufSize
  return new fan.sys.LocalFileOutStream(fd);
}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

// TODO: sep
// TODO: pathSep