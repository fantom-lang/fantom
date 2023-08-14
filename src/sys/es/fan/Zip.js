//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Mar 2023  Matthew Giannini  Creation
//   25 Apr 2023  Matthew Giannini  Refactor for ES
//   27 Jul 2023  Kiera O'Flynn     Implemented for Node
//

/**
 * Zip.
 */
class Zip extends Obj {
  constructor()
  {
    super();
    if (!Env.__isNode())
      throw UnsupportedErr.make("Zip is only available in a node environment.")
  }

  #yauzlZip;
  #yazlZip;

  #file;
  #in;
  #out;

//////////////////////////////////////////////////////////////////////////
// Static constructors
//////////////////////////////////////////////////////////////////////////

  static open(file)
  {
    if (!file.exists() || file.osPath() === null)
      throw IOErr.make("File must exist on the local filesystem");
    if (file.isDir())
      throw IOErr.make("Cannot unzip a directory");

    const zip = new Zip();
    zip.#file = file;
    zip.#yauzlZip = yauzl.open(file.osPath());
    return zip;
  }

  static read(in$)
  {
    const zip = new Zip();
    zip.#in = in$;
    zip.#yauzlZip = yauzl.fromStream(in$);
    return zip;
  }

  static write(out)
  {
    const zip = new Zip();
    zip.#out = out;
    zip.#yazlZip = new YazlZipFile(out);
    return zip;
  }

//////////////////////////////////////////////////////////////////////////
// File reading-only
//////////////////////////////////////////////////////////////////////////

  file()
  {
    return this.#file || null;
  }

  #contents;
  contents()
  {
    if (!this.#file) return null;
    if (this.#contents) return this.#contents;

    const map = Map.make(Uri.type$, File.type$);

    // Get each entry
    let entry;
    while (!!(entry = this.#yauzlZip.getEntry())) {
      map.add(Uri.fromStr("/" + entry.fileName), ZipEntryFile.makeFromFile(entry, this.#yauzlZip, this));
    }

    this.#contents = map.ro();
    return this.#contents;
  }

//////////////////////////////////////////////////////////////////////////
// InStream reading-only
//////////////////////////////////////////////////////////////////////////

  #lastFile;
  readNext()
  {
    if (!this.#in)
      throw UnsupportedErr.make("Not reading from an input stream");
    if (this.#lastFile) {
      this.#lastFile.__in().skip(this.#lastFile.__in().remaining(), true);
      this.#lastFile.__in().close();
    }

    const entry = this.#yauzlZip.getEntryFromStream();
    if (!entry) return null;
    return (this.#lastFile = ZipEntryFile.makeFromStream(entry, this.#yauzlZip));
  }

  readEach(c)
  {
    if (!this.#in)
      throw UnsupportedErr.make("Not reading from an input stream");

    for(let f = this.readNext(); f != null; f = this.readNext())
      c(f);
  }

//////////////////////////////////////////////////////////////////////////
// OutStream writing-only
//////////////////////////////////////////////////////////////////////////

  writeNext(path, modifyTime=DateTime.now(), opts=null)
  {
    if (!this.#out)
      throw UnsupportedErr.make("Not writing to an output stream");
    if (path.frag() != null)
      throw ArgErr.make("Path must not contain fragment: " + path);
    if (path.queryStr() != null)
      throw ArgErr.make("Path must not contain query: " + path);
    if (this.#finished)
      throw IOErr.make("Already finished writing the zip contents");
    
    let pathStr = path.toStr();
    if (pathStr.startsWith("/")) pathStr = pathStr.slice(1);

    // get the outstream
    return this.#yazlZip.addEntryAt(pathStr, {
      mtime: modifyTime.toJs(),
      compressed: opts ? (opts.get("level") || 0) > 0 : null,
      level: opts ? opts.get("level") : null,
      crc32: opts ? opts.get("crc") : null,
      compressedSize: opts ? opts.get("compressedSize") : null,
      uncompressedSize: opts ? opts.get("uncompressedSize") : null,
      fileComment: opts ? opts.get("comment") : null,
      extra: opts ? opts.get("extra") : null,
    });
  }

  #finished;
  finish()
  {
    if (!this.#out)
      throw UnsupportedErr.make("Not writing to an output stream");
    
    if (this.#finished)
      return false;
    try {
      this.#yazlZip.end();
      return true;
    } catch (_) {
      return false;
    }
  }

//////////////////////////////////////////////////////////////////////////
// Other methods
//////////////////////////////////////////////////////////////////////////

  close() {
    try {
      if (this.#yauzlZip) {
        this.#yauzlZip.close();
      }
      if (this.#in) {
        this.#in.close();
      }
      if (this.#out) {
        if (!this.#finished)
          this.finish();
        this.#out.close();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  static unzipInto(zipFile, dir) {
    if (!dir.isDir()) throw ArgErr.make("Not dir: " + dir);
    let zip;
    try
    {
      let count = 0;

      function processEntry(entry) {
        const relUri = entry.uri().toStr().substring(1);
        const dest = dir.plus(Uri.fromStr(relUri));
        dest.create();
        if (entry.isDir()) { return; }
        const out = dest.out();
        try {
          entry.in$().pipe(out);
        }
        finally {
          out.close();
        }
        if (entry.modified() != null) dest.modified(entry.modified());
        count++;
      }

      if (zipFile.osPath() != null) {
        // unzip w/ random access
        zip = Zip.open(zipFile);
        const contents = zip.contents();
        contents.each(processEntry);
      }
      else {
        // unzip from in stream
        zip = Zip.read(zipFile.in$());
        let entry;
        while ((entry = zip.readNext()) != null)
          processEntry(entry);
      }
      return count;
    }
    finally
    {
      if (zip) zip.close();
    }
  }

  static gzipOutStream(out) {
    return DeflateOutStream.makeGzip(out);
  }

  static gzipInStream(in$) {
    return InflateInStream.makeGunzip(in$);
  }

  static deflateOutStream(out, opts=null) {
    return DeflateOutStream.makeDeflate(out, opts);
  }

  static deflateInStream(in$, opts=null) {
    return InflateInStream.makeInflate(in$, opts);
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  toStr()
  {
    if (this.#file) return this.#file.toStr();
    return super.toStr();
  }

}