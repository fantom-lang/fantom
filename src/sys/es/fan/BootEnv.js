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
      let path = Env.__node("path");
      this.#vars.set("os.name", this.os());
      this.#vars.set("os.version", Env.__node()?.os?.version());
      this.#vars.set("node.version", process.versions.node);
      this.#vars.set("node.path", path.dirname(process.execPath).replaceAll(path.sep, path.posix.sep));
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
    if (this.os() == "win32") return this.#win32prompt(msg);
    else return this.#unixprompt(msg);
  }

  #win32prompt(msg) {
    // https://github.com/nodejs/node/issues/28243
    const fs = Env.__node()?.fs;
    fs.writeSync(1, String(msg));
    let s = '', buf = Buffer.alloc(1);
    while(buf[0] != 10 && buf[0] != 13) {
      s += buf;
      fs.readSync(0, buf, 0, 1, 0);
    }
    if (buf[0] == 13) { fs.readSync(0, buf, 0, 1, 0); }
    return s.slice(1);
  }

  #unixprompt(msg) {
    // https://stackoverflow.com/questions/61394928/get-user-input-through-node-js-console/74250003?noredirect=1#answer-75008198
    const fs = Env.__node()?.fs;
    const stdin = fs.openSync("/dev/stdin","rs");

    fs.writeSync(process.stdout.fd, msg);
    let s = '';
    let buf = Buffer.alloc(1);
    fs.readSync(stdin,buf,0,1,null);
    while((buf[0] != 10) && (buf[0] != 13)) {
      s += buf;
      fs.readSync(stdin,buf,0,1,null);
    }
    // Not sure if we need this on unix?
    // if (buf[0] == 13) { fs.readSync(0, buf, 0, 1, 0); }
    return s;
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