//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 2010  Andy Frank  Creation
//   17 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Env
 */
class Env extends Obj {

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  constructor() {
    super();
    this.#args = List.make(Str.type$).toImmutable();
    this.#index = Map.make(Str.type$, new ListType(Str.type$)).toImmutable();
    this.#vars = Map.make(Str.type$, Str.type$);
    this.#vars.caseInsensitive(true);
    this.#props = Map.make(Str.type$, Str.type$);

    const vars = typeof fan$env === 'undefined' ? {} : fan$env;
    this.__loadVars(vars);

    // TODO:FIXIT - pod props map, keyed by pod.name
    // TODO:FIXIT - user?

    this.#out = new ConsoleOutStream();
  }

  __loadVars(env) {
    if (!env) return
    const keys = Object.keys(env)

    // set some pre-defined vars
    if (Env.__isNode()) {
      this.#vars.set("os.name", this.os());
      this.#vars.set("os.version", Env.__node().os.version());
    }

    for (let i=0; i<keys.length; ++i) {
      const k = keys[i];
      const v = env[k];
      this.#vars.set(k, v);
    }
  }

  #args;
  #index;
  #vars;
  #props;
  #out;
  __homeDir;
  __workDir;
  __tempDir;

  // used to display locale keys
  static __localeTestMode = false;

  static #cur = undefined;
  static cur() {
    if (Env.#cur === undefined) Env.#cur = new Env()
    return Env.#cur;
  }

  static configProps() { return Uri.fromStr("config.props"); }
  static localeEnProps() { return Uri.fromStr("locale/en.props"); }

  static __invokeMain(qname) {
    // resolve qname to method
    const dot = qname.indexOf('.');
    if (dot < 0) qname += '.main';
    const main = Slot.findMethod(qname);

    // invoke main
    if (main.isStatic()) main.call();
    else main.callOn(main.parent().make());
  }

  static __isNode() { return typeof node !== "undefined"; }

  static __node(module=null) {
    if (typeof node === "undefined") throw UnsupportedErr.make("Only supported in Node runtime");
    return module == null ? node : node[module];
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  toStr() { return this.typeof$().toString(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  runtime() { return "js"; }

  javaVersion() { return 0; }

  os() { 
    let p = Env.__node().os.platform();
    if (p === "darwin") p = "macosx";
    return p;
  }

  arch() {
    let a = Env.__node().os.arch();
    switch (a) {
      case "ia32": a = "x86";
      case "x64":  a = "x86_64";
    }
    return a;
  }

  platform() { return `${this.os()}-${this.arch()}`; }

  // TODO: FIXIT

  idHash(obj) {
    if (!obj) return 0;
    return ObjUtil.hash(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  args() { return this.#args; }

  vars() { return this.#vars.toImmutable(); }

  diagnostics() { return Map.make(Str.type$, Obj.type$); }

  host() { return Env.__node().os.hostname(); }

  user() { return "unknown"; }

  out() { return this.#out; }

  prompt(msg="") {
    if (this.os() == "win32") return this.#win32prompt(msg);
    else return this.#unixprompt(msg);
  }

  #win32prompt(msg) {
    // https://github.com/nodejs/node/issues/28243
    const fs = Env.__node().fs;
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
    const fs = Env.__node().fs;
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

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  path() { return List.make(File.type$, [this.workDir()]).toImmutable(); }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  index(key) { return this.#index.get(key, Str.type$.emptyList()); }

  props(pod, uri, maxAge) {
    const key = `${pod.name()}:${uri.toStr()}`;
    let map = this.#props.get(key);
    if (map == null) {
      map = Map.make(Str.type$, Str.type$).toImmutable();
      this.#props.add(key, map);
    }
    return map;
  }

  config(pod, key, def=null) {
    return this.props(pod, Uri.fromStr("config.props"), Duration.oneMin$()).get(key, def);
  }

  locale(pod, key, def, locale=Locale.cur()) {
    if (Env.__localeTestMode &&
        key.indexOf(".browser") == -1 &&
        key.indexOf(".icon") == -1 &&
        key.indexOf(".accelerator") == -1 &&
        pod.name() != "sys") 
    { 
      return pod + "::" + key; 
    }

    // TODO: why was the old code doing this?
    // if (def === undefined) def = "_Env_nodef_";

    let val;
    const maxAge = Duration.maxVal();

    // 1. 'props(pod, `locale/{locale}.props`)'
    val = this.props(pod, locale.__strProps, maxAge).get(key, null);
    if (val != null) return val;

    // 2. 'props(pod, `locale/{lang}.props`)'
    val = this.props(pod, locale.__langProps, maxAge).get(key, null);
    if (val != null) return val;

    // 3. 'props(pod, `locale/en.props`)'
    val = this.props(pod, Uri.fromStr("locale/en.props"), maxAge).get(key, null);
    if (val != null) return val;

    // 4. Fallback to 'pod::key' unless 'def' specified
    if (def === undefined) return pod + "::" + key;
    return def;
  }

  // Internal compiler hook for setting properties
  __props(key, m) { this.#props.add(key, m.toImmutable()); }

//////////////////////////////////////////////////////////////////////////
// Exiting and Shutdown Hooks
//////////////////////////////////////////////////////////////////////////

  exit(status=0) { process.exit(status); }

  addShutdownHook(f) { }

  removeShutdownHook(f) { }
}
