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

  constructor(parent=null) {
    super();
    this.#parent = parent;
  }

  static make$(self, parent) {
    self.#parent = parent;
  }

  static #cur;
  static cur(env=undefined) {
    if (env) { Env.#cur = env; return; }
    if (!Env.#cur) Env.#cur = new BootEnv();
    return Env.#cur;
  }

  #parent;

//////////////////////////////////////////////////////////////////////////
// Static support
//////////////////////////////////////////////////////////////////////////

  static #index;
  __loadIndex(index) {
    if (index.typeof().toStr() != "[sys::Str:sys::Str[]]") throw ArgErr.make("Invalid type");
    Env.#index = index;
  }

  static #props;
  // internal compiler hook for setting properties
  __props(key, m) {
    if (!Env.#props) Env.#props = Map.make(Str.type$, Map.type$);
    let existing = Env.#props.get(key);
    if (!existing) Env.#props.add(key, m.toImmutable());
  }

  // used to display locale keys
  static __localeTestMode = false;

  static configProps() { return Uri.fromStr("config.props"); }
  static localeEnProps() { return Uri.fromStr("locale/en.props"); }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static __invokeMain(qname) {
    // resolve qname to method
    const dot = qname.indexOf('.');
    if (dot < 0) qname += '.main';
    const main = Slot.findMethod(qname);

    // invoke main
    if (main.isStatic()) main.call();
    else main.callOn(main.parent().make());
  }

//////////////////////////////////////////////////////////////////////////
// Node
//////////////////////////////////////////////////////////////////////////

  // If 'process' is defined, then we are running in Node.js
  static __isNode() { return typeof process !== "undefined"; }

  // Get a node module (must be imported already from node.js source file)
  // Note that currently the generated sys.js imports that file into
  // variable 'node'.
  static __node(module=null) {
    if (typeof node === "undefined") throw Unsupported>err("Only supported in Node.js runtime");
    return module == null ? node : node[module];
  }

//////////////////////////////////////////////////////////////////////////
// Obj
//////////////////////////////////////////////////////////////////////////

  toStr() { return this.typeof().toStr(); }

//////////////////////////////////////////////////////////////////////////
// Non-Virtuals
//////////////////////////////////////////////////////////////////////////

  parent() { return this.#parent; }

  os() {
    let p = Env.__node()?.os?.platform();
    if (p === "darwin") p = "macosx";
    return p;
  }

  arch() {
    let a = Env.__node()?.os?.arch();
    switch (a) {
      case "ia32":
        a = "x86";
        break;
      case  "x64":
        a = "x86_64";
        break;
    }
    return a;
  }

  platform() { return `${this.os()}-${this.arch()}`; }

  // TODO:FIXIT - we should probably make this more flexible than just "js",
  // but I think a lot of code my depend/assume that single value
  runtime() { return "js"; }

  javaVersion() { return 0; }

  idHash(obj) {
    if (!obj) return 0;
    return ObjUtil.hash(obj);
  }

//////////////////////////////////////////////////////////////////////////
// Virtuals
//////////////////////////////////////////////////////////////////////////

  args() { return this.#parent.args(); }

  mainMethod() { return this.#parent.mainMethod(); }

  vars() { return this.#parent.vars(); }

  diagnostics() { return this.#parent.diagnostics(); }

  gc() { this.#parent.gc(); }

  host() { return this.#parent.host(); }

  user() { return this.#parent.user(); }

  in() { return this.#parent.in(); }

  out() { return this.#parent.out(); }

  err() { return this.#parent.err(); }

  prompt(msg="") { return this.#parent.prompt(msg); }

  promptPassword(msg="") { return this.#parent.promptPassword(msg); }

  homeDir() { return this.#parent.homeDir(); }

  workDir() { return this.#parent.workDir(); }

  tempDir() { return this.#parent.tempDir(); }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  path() { return List.make(File.type$, [this.workDir()]).toImmutable(); }

//////////////////////////////////////////////////////////////////////////
// State
//////////////////////////////////////////////////////////////////////////

  index(key) { return Env.#index.get(key, Str.type$.emptyList()); }

  props(pod, uri, maxAge) {
    // if (!Env.#props) Env.#props = Map.make(Str.type$, Str.type$);

    const key = `${pod.name()}:${uri.toStr()}`;
    let map = Env.#props.get(key);
    if (map == null) {
      map = Map.make(Str.type$, Str.type$).toImmutable();
      Env.#props.add(key, map);
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

//////////////////////////////////////////////////////////////////////////
// Exiting and Shutdown Hooks
//////////////////////////////////////////////////////////////////////////

  exit(status=0) { this.#parent.exit(status); }

  addShutdownHook(f) { this.#parent.addShutdownHook(f); }

  removeShutdownHook(f) { return this.#parent.removeShutdownHook(f); }
}