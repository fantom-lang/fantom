//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   01 Sep 2010  Andy Frank     Creation
//   08 Jan 2023  Kiera O'Flynn  Integration w/ Node JS
//   05 Jul 2023  Matthew Giannini  Refactor for ES
//

/**
 * LocalFile.
 */
class LocalFile extends File {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(uri) {
    super(uri);
  }

  #node_os_path;
  static #toDelete = [];

  static make(uri) {
    if (uri.scheme() != null && uri.scheme() != "file")
      throw ArgErr.make("Invalid Uri scheme for local file: " + uri.toStr());
    const instance = new LocalFile(uri);

    const os   = node.os;
    const url  = node.url;
    const path = node.path

    // node cannot handle windows paths with leading '/' so we need
    // finagle the uri path into a format that works on unix and windows
    // console.log("TODO: normalize windows path: " + instance.m_uri_str);
    instance.#node_os_path = uri.toStr();

    if (os.platform == "win32" && uri.isPathAbs()) {
      let uriStr = uri.toStr();
      if (!uri.isAbs()) {
        // ensure the uri has file scheme
        uriStr = "file://" + uriStr;
      }
      else if (!/^.+:/.test(uri.pathStr())) {
        // ensure paths that don't have drive are fixed to have drive
        // otherwise url.fileURLToPath barfs
        // file:/ok/path => file:///C:/ok/path
        uriStr = "file:///" + File.__win32Drive() + uri.pathStr();
      }
      instance.#node_os_path = url.fileURLToPath(uriStr).split(path.sep).join(path.posix.sep);
    }

    return instance;
  }

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  __isDirectory() {
    return this.exists() && node.fs.statSync(this.#node_os_path).isDirectory();
  }

  exists() { return node.fs.existsSync(this.#node_os_path); }

  size() {
    if (!this.exists() || this.__isDirectory()) return null;
    return node.fs.statSync(this.#node_os_path).size;
  }

  modified(it) {
    if (!it) {
      if (!this.exists()) return null;
      return DateTime.fromJs(node.fs.statSync(this.#node_os_path).mtime);
    }
    node.fs.utimesSync(this.#node_os_path, it.toJs(), it.toJs());
  }

  #checkAccess(C) {
    try {
      node.fs.accessSync(this.#node_os_path, C);
      return true;
    } catch (e) {
      return false;
    }
  }

  isHidden() {
    throw UnsupportedErr.make("Node JS cannot detect whether a local file is hidden.");
  }

  isReadable() { return this.#checkAccess(node.fs.constants.R_OK); }
  isWritable() { return this.#checkAccess(node.fs.constants.W_OK); }
  isExecutable() { return this.#checkAccess(node.fs.constants.X_OK); }

  osPath() { return this.#node_os_path; }

  parent() {
    const parent = this.uri().parent();
    if (parent == null) return null;
    return LocalFile.make(parent);
  }

  list(pattern=null) {
    const acc = List.make(File.type$, []);
    if (!this.exists() || !this.isDir())
      return acc;

    const list = node.fs.readdirSync(this.#node_os_path, { withFileTypes: true });
    const len  = list == null ? 0 : list.length;
    for (let i=0; i<len; ++i) {
      const f = list[i];
      const name = f.name;
      if (!pattern || pattern.matches(name))
        acc.add(LocalFile.make(this.uri().plusName(name, f.isDirectory())));
    }
    return acc;
  }

  normalize() {
    const url  = node.url;
    const path = node.path;
    let href = url.pathToFileURL(path.resolve(this.#node_os_path)).href;
    if (this.__isDirectory()) href += "/";
    const uri  = Uri.fromStr(href);
    return LocalFile.make(uri);
  }

  store() { return new LocalFileStore(); }

//////////////////////////////////////////////////////////////////////////
// File Management
//////////////////////////////////////////////////////////////////////////

  // Helper create functions

  #createFile() {
    if (this.__isDirectory())
      throw IOErr.make(`Already exists as dir: ${this.uri()}`);

    if (this.exists()) this.delete$();

    const fs = node.fs;
    const parent = this.parent();
    if (parent != null && !parent.exists()) parent.create();

    try {
      const out = fs.openSync(this.#node_os_path, 'w');
      fs.close(out);
    }
    catch (e) {
      throw IOErr.make(e);
    }
  }

  #createDir() {
    try {
      node.fs.mkdirSync(this.#node_os_path, { recursive: true });
    }
    catch (e) {
      throw IOErr.make(e);
    }
  }

  create() {
    if (this.isDir())
      this.#createDir();
    else
      this.#createFile();
    return this;
  }

  delete$() {
    if (!this.exists()) return;

    try {
      node.fs.rmSync(this.#node_os_path, { recursive: true, force: true });
    }
    catch (e) {
      throw IOErr.make(`Cannot delete: ${this.uri()}\n${e}`);
    }
  }

  deleteOnExit() {
    LocalFile.#toDelete.push(this);
    return this;
  }

  static {
    if (typeof process !== "undefined") {
      process.on('exit', () => {
        LocalFile.#toDelete.forEach((f) => { f.delete$(); })
      });
    }
  }

//////////////////////////////////////////////////////////////////////////
// Copy
//////////////////////////////////////////////////////////////////////////

  __doCopyFile(to) {
    if (!(to instanceof LocalFile))
      return super.__doCopyFile(to);

    node.fs.copyFileSync(this.#node_os_path, to.#node_os_path);
  }

//////////////////////////////////////////////////////////////////////////
// Move
//////////////////////////////////////////////////////////////////////////

  moveTo(to) {
    if (this.isDir() != to.isDir()) {
      if (this.isDir())
        throw ArgErr.make("moveTo must be dir `" + to.toStr() + "`");
      else
        throw ArgErr.make("moveTo must not be dir `" + to.toStr() + "`");
    }

    if (!(to instanceof LocalFile))
      throw IOErr.make(`Cannot move LocalFile to ${to.typeof$()}`);
    
    if (to.exists())
      throw IOErr.make(`moveTo already exists: ${to.toStr()}`);
    
    if (!this.exists())
      throw IOErr.make(`moveTo source file does not exist: ${this.toStr()}`);
    
    if (!this.__isDirectory()) {
      const destParent = to.parent();
      if (destParent != null && !destParent.exists())
        destParent.create();
    }

    try {
      // NOTE: this is very likely going to fail sometimes on windows and we can't
      // do async retries. so that is sad
      // https://stackoverflow.com/questions/32457363/eperm-while-renaming-directory-in-node-js-randomly
      node.fs.renameSync(this.#node_os_path, to.#node_os_path)
    }
    catch (e) {
      throw IOErr.make(`moveTo failed: ${to.toStr()}`, IOErr.make(""+e));
    }

    return to;
  }

//////////////////////////////////////////////////////////////////////////
// IO
//////////////////////////////////////////////////////////////////////////

  // open(mode="rw") { }

// TODO: mmap

  in$(bufSize) {
    if (this.__isDirectory())
      throw IOErr.make("cannot get in stream for a directory");
    if (!bufSize) bufSize = Int.__chunk;

    const fd = node.fs.openSync(this.#node_os_path, 'r');
    return LocalFileInStream.make(fd, bufSize);
    // return this.m_in = new fan.sys.LocalFileInStream(fd, bufSize);
  }

  out(append=false, bufSize=4096) {
    if (this.__isDirectory())
      throw IOErr.make("cannot get out stream for a directory");

    const flag = append ? 'a' : 'w';
    const fd = node.fs.openSync(this.#node_os_path, flag);
    // TODO: add bufSize
    return LocalFileOutStream.make(fd);
  }
}