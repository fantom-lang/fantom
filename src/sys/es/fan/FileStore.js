//
// Copyright (c) 2013, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Sep 2013  Brian Frank  Creation
//   20 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * FileStore
 */
class FileStore extends Obj {
  constructor() { super(); }
  
  totalSpace() { return null; }
  availSpace() { return null; }
  freeSpace() { return null; }
}

/**
 * LocalFileStore
 */
class LocalFileStore extends FileStore {
  constructor() { super(); }
  typeof$() { return LocalFileStore.type$; }
  totalSpace() { return null; }
  availSpace() { return null; }
  freeSpace() { return null; }
}