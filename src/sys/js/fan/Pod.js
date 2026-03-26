//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   14 Nov 2009  Andy Frank  Creation
//   31 Mar 2023  Matthew Giannini  Refactor to ES
//

/**
 * Pod
 */
class Pod extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(name) { 
    super();
    this.#name = name;
    this.#types = [];
    this.#meta = [];
    this.#version = Version.defVal;

    this.#uri = undefined;
    this.#depends = undefined;
    this.#$types = undefined;
    this.#log = undefined;
  }

  static #pods = [];
  static #list = null;
  static sysPod$ = undefined;

  #name;
  #types;
  #meta;
  #version;
  #uri;
  #depends;
  #$types;
  #log;

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  static of(obj) {
    return Type.of(obj).pod();
  }

  static list() {
    if (Pod.#list == null) {
      let pods = Pod.#pods;
      let list = List.make(Pod.type$);
      for (let n in pods) list.add(pods[n]);
      Pod.#list = list.sort().toImmutable();
    }
    return Pod.#list;
  }

  static load(instream) {
    throw UnsupportedErr.make("Pod.load");
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  name() { return this.#name; }  

  meta() { return this.#meta; }
  // compiler support for setting pod meta
  __meta(it) { 
    this.#meta = it.toImmutable(); 

    // set the version from metadata
    this.#version = Version.fromStr(this.#meta.get("pod.version"));
  }

  version() { return this.#version; }

  uri() {
    if (this.#uri === undefined) this.#uri = Uri.fromStr(`fan://${this.#name}`);
    return this.#uri;
  }

  depends() {
    if (this.#depends === undefined) {
      let arr = [];
      let depends = this.meta().get("pod.depends").split(";");
      for (let i=0; i<depends.length; ++i) {
        let d = depends[i];
        if (d == "") continue;
        arr.push(Depend.fromStr(d));
      }
      this.#depends = List.make(Depend.type$, arr);
    }
    return this.#depends;
  }

  toStr() { return this.#name; }

//////////////////////////////////////////////////////////////////////////
// Files
//////////////////////////////////////////////////////////////////////////

  files() { throw UnsupportedErr.make("Pod.files"); }

  file(uri, checked) { throw UnsupportedErr.make("Pod.file"); }

//////////////////////////////////////////////////////////////////////////
// Types
//////////////////////////////////////////////////////////////////////////

  types() {
    if (this.#$types == null) {
      let arr = [];
      for (let p in this.#types) arr.push(this.#types[p]);
      this.#$types = List.make(Type.type$, arr);
    }
    return this.#$types;
  }

  type(name, checked=true) {
    let t = this.#types[name];
    if (t == null && checked) {
      throw UnknownTypeErr.make(`${this.#name}::${name}`);
    }
    return t;
  }

  // addType
  at$(name, baseQname, mixins, facets, flags, jsRef) {
    let qname = `${this.#name}::${name}`;
    if (this.#types[name] != null) {
      throw Err.make(`Type already exists: ${qname}`);
    }
    let t = new Type(qname, baseQname, mixins, facets, flags, jsRef);
    this.#types[name] = t;
    return t;
  }

  // addMixin
  am$(name, baseQname, mixins, facets, flags, jsRef) {
    let t = this.at$(name, baseQname, mixins, facets, flags, jsRef);
    return t;
  }

//////////////////////////////////////////////////////////////////////////
// Static Methods
//////////////////////////////////////////////////////////////////////////

  static find(name, checked=true) {
    let p = Pod.#pods[name];
    if (p == null && checked) {
      throw UnknownPodErr.make(name);
    }
    return p;
  }

  static add$(name) {
    if (Pod.#pods[name] != null) {
      throw Err.make(`Pod already exists: ${name}`);
    }
    let p = new Pod(name);
    Pod.#pods[name] = p;
    return p;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  log() {
    if (this.#log == null) {
      this.#log = Log.get(this.#name);
    }
    return this.#log;
  }

  props(uri, maxAge) {
    return Env.cur().props(this, uri, maxAge);
  }

  config(key, def=null) {
    return Env.cur().config(this, key, def);
  }

  doc() { return null; }

  locale(key, def) {
    return Env.cur().locale(this, key, def);
  }

}