//
// Copyright (c) 2025, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   03 Jul 2025  Matthew Giannini  Creation
//

/**
 * LockFile
 */
class LockFile extends sys.Obj
{

//////////////////////////////////////////////////////////////////////////
// Constructors
//////////////////////////////////////////////////////////////////////////

  constructor(file)
  {
    super();
    this.#file = file;
  }

  #file;

  typeof() { return LockFile.type$; }

  static make(file) { return new LockFile(file); }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  file() { return this.#file; }

  lock() { return this; }

  unlock() { return this; }
}

