//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   29 Mar 2009  Andy Frank     Creation
//   07 Jan 2023  Kiera O'Flynn  Integration w/ Node JS
//   20 Apr 2023  Matthew Giannini  Refactor for ES
//

class File extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(uri) {
    super();
    this.#uri = uri;
  }

  #uri;
  #uri_str;
  static #tempCt=0;

  static make(uri, checkSlash=true)
  {
    if (typeof uri == "string") uri = Uri.fromStr(uri);

    let f;

    if (Env.__isNode()) {
      // Create nodejs instance
      f = LocalFile.make(uri);
    }
    else {
      // Create "empty" instance as backup
      console.log("Warning: not running on Node JS, dummy file object returned");
      f = new File(uri);
      return f;
    }

    // Check slash
    if (f.exists()) {
      if (f.__isDirectory() && !checkSlash && !uri.isDir())
        f.#uri = uri.plusSlash();
      else if (f.__isDirectory() && !uri.isDir())
        throw IOErr.make("Must use trailing slash for dir: " + uri.toStr());
      else if (!f.__isDirectory() && uri.isDir())
        throw IOErr.make("Cannot use trailing slash for file: " + uri.toStr());
    }
    else if (f.isDir() && Str.size(f.#uri.toStr()) > 1) {
      const altStr = Str.getRange(f.#uri.toStr(), new Range(0, -2));
      const fAlt = File.make(Uri.fromStr(altStr));
      if (fAlt.exists() && !fAlt.__isDirectory())
        throw IOErr.make("Cannot use trailing slash for file: " + uri.toStr());
    }

    return f;
  }

  static os(osPath) {
    if (!Env.__isNode())
      throw Err.make("Must be running on Node JS to create a local file.");
    const os   = node.os;
    if (os.platform() == "win32") {
      if (osPath.startsWith("/")) {
        osPath = "file://" + osPath;
      } else if (/^.+:/.test(osPath)) {
        osPath = "file:///" + osPath;
      }
    }
    return File.make(Uri.fromStr(osPath), false);
  }

  // TODO : only gets the root for the cwd
  static osRoots() {
    if (!Env.__isNode())
      throw Err.make("Must be running on Node JS to access the OS roots.");
    const r = node.os.platform() == "win32"
      ? "/" + File.__win32Drive() + "/"
      : node.path.parse(process.cwd()).root;
    return List.make(File.type$, [File.make(r, false)]);
  }

  static __win32Drive() { return process.cwd().split(node.path.sep)[0]; }

  static createTemp(prefix="fan", suffix=".tmp", dir=null) {
    if (dir == null)
      dir = Env.cur().tempDir();
    else if (!dir.isDir())
      throw IOErr.make(`Not a directory: ${dir.toStr()}`);
    else if (!(dir instanceof LocalFile))
      throw IOErr.make(`Dir is not on local file system: ${dir.toStr()}`);
    
    let f;
    do {
      f = LocalFile.make(
            Uri.fromStr(
                dir.toStr() + prefix + File.#tempCt + suffix
            ));
      File.#tempCt++;
    }
    while (f.exists());
    return f.create();
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  equals(that) {
    if (that && that instanceof File)
      return this.#uri.equals(that.#uri);
    return false;
  }

  hash() { return this.#uri.hash(); }
  toStr() { 
    if (!this.#uri_str) this.#uri_str = this.#uri.toStr();
    return this.#uri_str; 
  }

//////////////////////////////////////////////////////////////////////////
// Uri
//////////////////////////////////////////////////////////////////////////

  uri() { return this.#uri; }
  isDir() { return this.#uri.isDir(); }
  path() { return this.#uri.path(); }
  pathStr() { return this.#uri.pathStr(); }
  name() { return this.#uri.name(); }
  basename() { return this.#uri.basename(); }
  ext() { return this.#uri.ext(); }
  mimeType() { return this.#uri.mimeType(); }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  // Returns whether the file is *internally* a directory, rather than just using the uri
  __isDirectory() { this.#throwNotSupported("isDirectory"); }

  exists() { return false; }
  size() { this.#throwNotSupported("size"); }

  isEmpty() {
    if (this.isDir()) return this.list().isEmpty();
    const size = this.size();
    return size == null || size <= 0;
  }

  modified(it) { throw this.#throwNotSupported("modified"); }

  isHidden() { this.#throwNotSupported("isHidden"); }
  isReadable() { return false; }
  isWritable() { return false; }
  isExecutable() { return false; }

  osPath() { this.#throwNotSupported("osPath"); }
  parent() { this.#throwNotSupported("parent"); }
  list(pattern) { this.#throwNotSupported("list"); }

  listDirs(pattern=null) {
    const list = this.list(pattern);
    if (list.isEmpty()) return list;
    return File.#filter(list, (f) => { return f.isDir() });
  }

  listFiles(pattern=null) {
    const list = this.list(pattern);
    if (list.isEmpty()) return list;
    return File.#filter(list, (f) => { return !f.isDir() });
  }

  walk(c) {
    c(this);
    if (this.isDir()) {
      const list = this.list();
      for (let i=0; i<list.size(); ++i)
        (list.get(i)).walk(c);
    }
  }

  normalize() { this.#throwNotSupported("normalize"); }

  plus(uri, checkSlash=true) {
    if (typeof uri == "string") uri = Uri.fromStr(uri);
    return File.make(this.#uri.plus(uri), checkSlash);
  }

  store() { this.#throwNotSupported("store"); }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  create() { this.#throwNotSupported("create"); }

  createFile(name) {
    if (!this.isDir()) throw IOErr.make(`Not a directory: ${this.toStr()}`);
    return this.plus(Uri.fromStr(name)).create();
  }

  createDir(name) {
    if (!this.isDir()) throw IOErr.make(`Not a directory: ${this.toStr()}`);
    if (!Str.endsWith(name, "/")) name = name + "/";
    return this.plus(Uri.fromStr(name)).create();
  }

  delete$() { this.#throwNotSupported("delete"); }
  deleteOnExit() { this.#throwNotSupported("deleteOnExit"); }

//////////////////////////////////////////////////////////////////////////
// Copy
//////////////////////////////////////////////////////////////////////////

  copyTo(to, options=null) {
    // sanity
    if (this.isDir() != to.isDir()) {
      if (this.isDir())
        throw ArgErr.make("copyTo must be dir `" + to.toStr() + "`");
      else
        throw ArgErr.make("copyTo must not be dir `" + to.toStr() + "`");
    }

    // options
    let exclude = null, overwrite = null;
    if (options != null) {
      exclude   = options.get("exclude");
      overwrite = options.get("overwrite");
    }

    // recurse
    this.#doCopyTo(to, exclude, overwrite);
    return to;
  }

  #doCopyTo(to, exclude, overwrite) {
    // check exclude
    if (exclude instanceof Regex) {
      if (exclude.matches(this.uri().toStr())) return;
    }
    else if (exclude instanceof Function) {
      if (exclude(this)) return;
    }

    // check for overwrite
    if (to.exists()) {
      if (typeof overwrite == "boolean") {
        if (!overwrite) return;
      }
      else if (overwrite instanceof Function) {
        if (!overwrite.apply(null, [to, this])) return;
      }
      else {
        throw IOErr.make("No overwrite policy for `" + to.toStr() + "`");
      }
    }

    // copy directory
    if (this.isDir()) {
      to.create();
      const kids = this.list();
      for (let i=0; i<kids.size(); ++i) {
        const kid = kids.get(i);
        kid.#doCopyTo(to.#plusNameOf(kid), exclude, overwrite);
      }
    }

    // copy file contents
    else this.__doCopyFile(to);
  }

  __doCopyFile(to) {
    const out = to.out();
    try {
      this.in$().pipe(out);
    }
    finally {
      out.close();
    }
  }

  copyInto(dir, options=null) {
    if (!dir.isDir())
      throw ArgErr.make("Not a dir: `" + dir.toStr() + "`");

    return this.copyTo(dir.#plusNameOf(this), options);
  }

//////////////////////////////////////////////////////////////////////////
// Move
//////////////////////////////////////////////////////////////////////////

  moveTo(to) { this.#throwNotSupported("moveTo"); }

  moveInto(dir) {
    if (!dir.isDir())
      throw ArgErr.make("Not a dir: `" + dir.toStr() + "`");

    return this.moveTo(dir.#plusNameOf(this));
  }

  rename(newName) {
    if (this.isDir()) newName += "/";
    const parent = this.parent();
    if (parent == null)
      return this.moveTo(File.make(Uri.fromStr(newName)));
    else
      return this.moveTo(parent.plus(Uri.fromStr(newName)));
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  open(mode) { this.#throwNotSupported("open"); }
  mmap(mode, pos, size) { this.#throwNotSupported("mmap"); }

  in$(bufSize=4096) { this.#throwNotSupported("in"); }
  out(append=false, bufSize=4096) { this.#throwNotSupported("out"); }

  readAllBuf() { return this.in$(Int.__chunk).readAllBuf(); }

  readAllLines() { return this.in$(Int.__chunk).readAllLines(); }

  eachLine(f) { this.in$(Int.__chunk).eachLine(f); }

  readAllStr(normalizeNewlines=true) {
    return this.in$(Int.__chunk).readAllStr(normalizeNewlines);
  }

  readProps() { return this.in$(Int.__chunk).readProps(); }

  writeProps(props) { 
    this.create();
    this.out(false, Int.__chunk).writeProps(props, true); 
  }

  readObj(options=null) {
    const ins = this.in$();
    try {
      return ins.readObj(options);
    }
    finally {
      ins.close();
    }
  }

  writeObj(obj, options=null) {
    const out = this.out();
    try {
      out.writeObj(obj, options);
    }
    finally {
      out.close();
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static sep() { this.#throwNotSupported("sep"); }
  static pathSep() { this.#throwNotSupported("pathSep"); }

//////////////////////////////////////////////////////////////////////////
// Helper functions
//////////////////////////////////////////////////////////////////////////

  #throwNotSupported(name) { 
    throw UnsupportedErr.make(`File.${name} is not implemented in this environment.`);
  }

  static #filter(list, p) {
    const acc = List.make(File.type$, []);
    for (let i=0; i<list.size(); ++i) {
      const f = list.get(i);
      if (p(f)) acc.add(f);
    }
    return acc;
  }

  #plusNameOf(x) {
    let name = x.name();
    if (x.isDir()) name += "/";
    return this.plus(Uri.fromStr(name));
  }

}
