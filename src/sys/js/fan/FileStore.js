//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 13  Brian Frank  Creation
//

/**
 * FileStore
 */

fan.sys.FileStore = fan.sys.Obj.$extend(fan.sys.Obj);
fan.sys.FileStore.prototype.$ctor = function() {}
fan.sys.FileStore.prototype.$typeof = function() { return fan.sys.FileStore.$type; }
fan.sys.FileStore.prototype.totalSpace = function() { return null; }
fan.sys.FileStore.prototype.availSpace = function() { return null; }
fan.sys.FileStore.prototype.freeSpace = function() { return null; }


/**
 * LocalFileStore
 */
fan.sys.LocalFileStore = fan.sys.Obj.$extend(fan.sys.FileStore);
fan.sys.LocalFileStore.prototype.$ctor = function() { fan.sys.FileStore.$ctor.call(); }
fan.sys.LocalFileStore.prototype.$typeof = function() { return fan.sys.LocalFileStore.$type; }
fan.sys.LocalFileStore.prototype.totalSpace = function() { return null; }
fan.sys.LocalFileStore.prototype.availSpace = function() { return null; }
fan.sys.LocalFileStore.prototype.freeSpace = function() { return null; }