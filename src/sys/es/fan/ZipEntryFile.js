//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   28 Jul 2023  Kiera O'Flynn  Creation
//

/**
 * ZipEntryFile.
 */
class ZipEntryFile extends File {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(uri) {
    super(uri);
  }

  #isFileBacked;
  #entry;
  #yauzlZip;
 
  #zip;

  // Entry is parsed from central directory
  static makeFromFile(centralEntry, yauzlZip, zip) {
    const instance = new ZipEntryFile(Uri.fromStr("/" + centralEntry.fileName));
    instance.#isFileBacked = true;
    instance.#entry = centralEntry;
    instance.#yauzlZip = yauzlZip;
    instance.#zip = zip;
    return instance;
  }

  // Entry is parsed from local file header
  static makeFromStream(localEntry, yauzlZip) {
    const instance = new ZipEntryFile(Uri.fromStr("/" + localEntry.fileName));
    instance.#isFileBacked = false;
    instance.#entry = localEntry;
    instance.#yauzlZip = yauzlZip;
    return instance;
  }

//////////////////////////////////////////////////////////////////////////
// Info
//////////////////////////////////////////////////////////////////////////

  exists() {
    return true;
  }

  modified(val) {
    if (val)
      throw IOErr.make("ZipEntryFile is readonly");

    return yauzl.dosDateTimeToFantom(this.#entry.lastModFileDate, this.#entry.lastModFileTime);
  }

  size() {
    if ((this.#entry.generalPurposeBitFlag & 0x8) &&
         !this.#isFileBacked &&
         !this.#entry.foundDataDescriptor)
      return null;
    return this.#entry.uncompressedSize;
  }

  normalize() {
    return this;
  }

  osPath() {
    return null;
  }

//////////////////////////////////////////////////////////////////////////
// Navigation
//////////////////////////////////////////////////////////////////////////

  list(pattern) {
    if (!this.#isFileBacked || !this.uri().isDir())
      return List.make(File.type$, []);

    return this.#zip.contents().findAll((uri, f) => {
      this.uri().equals(uri.parent()) &&
      (!pattern || pattern.matches(uri.name))
    }).vals();
  }

  parent() {
    if (!this.#isFileBacked)
      return null;
    return this.#zip.contents().get(this.uri().parent());
  }

  plus(path, checkSlash=true) {
    if (!this.#isFileBacked)
      return File.make(newUri, checkSlash); // nonexistent file

    const newUri = this.uri().plus(path);
    const a = this.#zip.contents().get(newUri);
    if (a) return a;
    const b = this.#zip.contents().get(newUri.plusSlash());
    if (b) {
      if (checkSlash) throw IOErr.make("Must use trailing slash for dir: " + newUri.toString());
      else return b;
    }
    return File.make(newUri, checkSlash); // nonexistent file
  }

//////////////////////////////////////////////////////////////////////////
// Reading
//////////////////////////////////////////////////////////////////////////

  in$(bufferSize=4096) {
    if (this.#isFileBacked)
      return (this.#in = this.#yauzlZip.getInStream(this.#entry, {}, bufferSize));
    else {
      if (this.#in) throw IOErr.make("In stream already created");
      return (this.#in = this.#yauzlZip.getInStreamFromStream(this.#entry, {}, bufferSize));
    }
  }

  #in;
  __in(bufferSize=4096) {
    return this.#in || this.in$(bufferSize);
  }

//////////////////////////////////////////////////////////////////////////
// Not writing
//////////////////////////////////////////////////////////////////////////

  create() { this.#throwIO("create") }
  delete$() { this.#throwIO("delete") }
  deleteOnExit() { this.#throwIO("deleteOnExit") }
  moveTo() { this.#throwIO("moveTo") }
  out() { this.#throwIO("out") }

  #throwIO(name) { throw IOErr.make(`Cannot call '${name}'; zip entries are readonly.`) }

}