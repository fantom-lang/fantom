//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Sep 10  Andy Frank  Creation
//

/**
 * LocalFile.
 */

fan.sys.LocalFile = fan.sys.Obj.$extend(fan.sys.File);
fan.sys.LocalFile.prototype.$ctor = function() {}
fan.sys.LocalFile.prototype.$typeof = function() { return fan.sys.LocalFile.$type; }

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.make = function(file)
{
  var instance = new fan.sys.LocalFile();
  instance.m_file = file;
  instance.m_uri  = fan.sys.LocalFile.fileToUri(file, file.isDirectory(), null);
  return instance;
}

fan.sys.LocalFile.makeUri = function(uri, file)
{
  if (file.exists())
  {
    if (file.isDirectory())
    {
      if (!uri.isDir())
        throw fan.sys.IOErr.make("Must use trailing slash for dir: " + uri);
    }
    else
    {
      if (uri.isDir())
        throw fan.sys.IOErr.make("Cannot use trailing slash for file: " + uri);
    }
  }

  var instance = new fan.sys.LocalFile();
  instance.m_uri  = uri;
  instance.m_file = file;
  return instance;
}

//////////////////////////////////////////////////////////////////////////
// Conversions
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.fileToUri = function(file, isDir, scheme)
{
  var path = fan.sys.Str.javaToJs(file.getPath());
  var len = path.length;
  var s = "";

  // if scheme was specified
  if (scheme != null) s += scheme + ':';

  // deal with Windoze drive name
  if (len > 2 && path.charAt(1) == ':' && path.charAt(0) != '/')
    s += '/';

  // map characters
  for (var i=0; i<len; ++i)
  {
    var c = path.charAt(i);
    switch (c)
    {
      case '?':
      case '#':  s += '\\' + c; break;
      case '\\': s += '/'; break;
      default:   s += c;
    }
  }

  // add trailing slash if not present
  if (isDir && (s.length == 0 || s.charAt(s.length-1) != '/'))
    s += '/';

  return fan.sys.Uri.fromStr(s);
}

fan.sys.LocalFile.uriToFile = function(uri)
{
  if (uri.scheme() != null && uri.scheme() != "file")
    throw fan.sys.ArgErr.make("Invalid Uri scheme for local file: " + uri);
  return new java.io.File(fan.sys.LocalFile.uriToPath(uri));
}

fan.sys.LocalFile.uriToPath = function(uri)
{
  var path = uri.pathStr();
  var len  = path.length;
  var s = null;
  for (var i=0; i<len; ++i)
  {
    var c = path.charAt(i);
    if (c == '\\')
    {
      if (s == null) { s = ""; s += path.substr(0, i); }
    }
    else if (s != null) s += c;
  }
  return s == null ? path : s;
}

fan.sys.LocalFile.fileNameToUriName = function(name)
{
  var len = name.length;
  var s = null;
  for (var i=0; i<len; ++i)
  {
    var c = name.charAt(i);
    switch (c)
    {
      case '?':
      case '#':
        if (s == null) { s = ""; s += name.substr(0,i); }
        s += '\\' + c;
        break;
      default:
        if (s != null) s += c;
    }
  }
  return s == null ? name : s;
}

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.isDir = function() { return this.m_uri.isDir(); }

fan.sys.LocalFile.prototype.exists = function() { return this.m_file.exists(); }

fan.sys.LocalFile.prototype.size = function()
{
  if (this.m_file.isDirectory()) return null;
  return this.m_file.length();
}

//public DateTime modified() { return DateTime.fromJava(file.lastModified()); }

//public void modified(DateTime time) { file.setLastModified(time.toJava()); }

fan.sys.LocalFile.prototype.osPath = function()
{
  return fan.sys.Str.javaToJs(this.m_file.getPath());
}

fan.sys.LocalFile.prototype.parent = function()
{
  var parent = this.m_uri.parent();
  if (parent == null) return null;
  return fan.sys.LocalFile.makeUri(parent, fan.sys.LocalFile.uriToFile(parent));
}

fan.sys.LocalFile.prototype.list = function()
{
  var list = this.m_file.listFiles();
  var len = list == null ? 0 : list.length;
  var acc = fan.sys.List.make(fan.sys.File.$type, []);
  for (var i=0; i<len; ++i)
  {
    var f = list[i];
    var name = fan.sys.LocalFile.fileNameToUriName(f.getName());
    acc.add(fan.sys.LocalFile.makeUri(this.m_uri.plusName(name, f.isDirectory()), f));
  }
  return acc;
}

// public File normalize()

fan.sys.LocalFile.prototype.plus = function(uri, checkSlash)
{
  return fan.sys.File.make(this.m_uri.plus(uri), checkSlash);
}

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.create = function()
{
  if (this.isDir())
    this.createDir();
  else
    this.createFile();
  return this;
}

fan.sys.LocalFile.prototype.createFile = function()
{
  if (this.m_file.exists())
  {
    if (this.m_file.isDirectory())
      throw fan.sys.IOErr.make("Already exists as dir: " + this.m_file);
  }

  var parent = this.m_file.getParentFile();
  if (parent != null && !parent.exists())
  {
    if (!parent.mkdirs())
      throw fan.sys.IOErr.make("Cannot create dir: " + parent);
  }

  try
  {
    var out = new java.io.FileOutputStream(this.m_file);
    out.close();
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.LocalFile.prototype.createDir = function()
{
  if (this.m_file.exists())
  {
    if (!this.m_file.isDirectory())
      throw fan.sys.IOErr.make("Already exists as file: " + this.m_file);
  }
  else
  {
    if (!this.m_file.mkdirs())
      throw fan.sys.IOErr.make("Cannot create dir: " + this.m_file);
  }
}

fan.sys.LocalFile.prototype.$delete = function()
{
  if (!this.exists()) return;

  if (this.m_file.isDirectory())
  {
    var kids = this.list();
    for (var i=0; i<kids.size(); ++i)
      kids.get(i).$delete();
  }

  if (!this.m_file['delete']())
    throw fan.sys.IOErr.make("Cannot delete: " + this.m_file);
}


//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

fan.sys.LocalFile.prototype.$in = function(bufSize)
{
  if (bufSize === undefined) bufSize = fan.sys.Int.Chunk;
  try
  {
    return fan.sys.SysInStream.make(new java.io.FileInputStream(this.m_file), bufSize);
  }
  catch (e)
  {
    throw fan.sys.IOErr.make(e);
  }
}

fan.sys.LocalFile.prototype.out = function(append, bufSize)
{
  if (append === undefined) append = false;
  if (bufSize === undefined) bufSize = fan.sys.Int.Chunk;
  try
  {
    var parent = this.m_file.getParentFile();
    if (parent != null && !parent.exists()) parent.mkdirs();
    var fout = new java.io.FileOutputStream(this.m_file, append);
    var bout = fan.sys.SysOutStream.toBuffered(fout, bufSize);
    return new fan.sys.LocalFileOutStream(bout, fout.getFD());
    return null;
  }
  catch (err)
  {
    throw fan.sys.IOErr.make(e);
  }
}

