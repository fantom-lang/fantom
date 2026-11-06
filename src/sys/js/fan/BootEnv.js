//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   19 Nov 2024  Matthew Giannini  Creation
//

/**
 * BootEnv
 */
class BootEnv extends Env {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor(parent=null) {
    super(parent);
    this.#vars = Map.make(Str.type$, Str.type$);
    this.#vars.caseInsensitive(true);

    const vars = ((typeof js.fan$env) === 'undefined') ? {} : js.fan$env;
    this.__loadVars(vars);

    this.#out = new ConsoleOutStream();
  }

  #vars;
  #out;

  __loadVars(env) {
    if (!env) return
    const keys = Object.keys(env)

    // set some pre-defined vars
    if (Env.__isNode()) {
      this.#vars.set("os.name", this.os());
      this.#vars.set("os.version", Env.__node()?.os?.version());
    }

    for (let i=0; i<keys.length; ++i) {
      const k = keys[i];
      const v = env[k];
      this.#vars.set(k, v);
    }
  }

//////////////////////////////////////////////////////////////////////////
// Env
//////////////////////////////////////////////////////////////////////////

  args() { return List.make(Str.type$).toImmutable(); }

  mainMethod() { return null; }

  vars() { return this.#vars.toImmutable(); }

  diagnostics() { return Map.make(Str.type$, Obj.type$); }

  host() { return Env.__node()?.os?.hostname(); }

  user() { return Env.__node()?.os?.userInfo()?.username; }

  out() { return this.#out; }

  prompt(msg="") {
    // node has no sync readline, so read stdin a byte at a time until LF
    const fs = Env.__node()?.fs;
    const win = this.os() == "win32";
    const fd = win ? 0 : fs.openSync("/dev/stdin", "rs");
    try {
      fs.writeSync(1, String(msg));
      const bytes = [], buf = Buffer.alloc(1);
      let n;
      while ((n = fs.readSync(fd, buf, 0, 1, win ? 0 : null)) > 0 && buf[0] != 10) {
        if (buf[0] != 13) bytes.push(buf[0]);
      }
      if (n == 0 && bytes.length == 0) return null;
      return Buffer.from(bytes).toString();
    }
    finally {
      if (!win) fs.closeSync(fd);
    }
  }

  homeDir() { return this.__homeDir; }

  workDir() { return this.__workDir; }

  tempDir() { return this.__tempDir; }

  exit(status=0) {
    if (Env.__isNode()) process.exit(status);
  }

  addShutdownHook(f) { }

  removeShutdownHook(f) { }

}