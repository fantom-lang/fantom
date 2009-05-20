//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 09  Andy Frank  Creation
//   20 May 09  Andy Frank  Refactor to new OO model
//

/**
 * InStream
 */
var sys_InStream = sys_Obj.$extend(sys_Obj);

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

sys_InStream.prototype.$ctor = function()
{
  this.$in = null;
}

//////////////////////////////////////////////////////////////////////////
// InStream
//////////////////////////////////////////////////////////////////////////

// read = function()
// readBuf = function(buf, n)
// unread = function(n)

sys_InStream.prototype.skip = function(n)
{
  if (this.$in != null) return this.$in.skip(n);

  for (var i=0; i<n; ++i)
    if (this.read() == 0) return i;
  return n;
}

// readAllBuf = function()
// readBufFully = function(buf, n)

// ...

sys_InStream.prototype.readObj = function(options)
{
  if (options == undefined) options = null;
  return new fanx_ObjDecoder(this, options).readObj();
}

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

sys_InStream.prototype.type = function()
{
  return sys_Type.find("sys::InStream");
}

//////////////////////////////////////////////////////////////////////////
// Static
//////////////////////////////////////////////////////////////////////////

sys_InStream.makeForStr = function(s)
{
  return new sys_StrInStream(s);
}

