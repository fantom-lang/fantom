//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 13  Brian Frank  Creation
//

/**
 * LocalFileStore
 */

fan.sys.LocalFileStore = fan.sys.Obj.$extend(fan.sys.FileStore);
fan.sys.LocalFileStore.prototype.$ctor = function() {}
fan.sys.LocalFileStore.prototype.$typeof = function() { return fan.sys.LocalFileStore.$type; }

