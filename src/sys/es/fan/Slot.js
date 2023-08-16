//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 Mar 2009  Andy Frank  Creation
//   20 May 2009  Andy Frank  Refactor to new OO model
//   12 Apr 2023  Matthew Giannini  Refactor for ES
//

/**
 * Slot.
 */
class Slot extends Obj {

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  constructor(parent, name, flags, facets, doc=null) {
    super();
    this.#parent = parent;
    this.#qname  = parent.qname() + "." + name;
    this.#name   = name;
    this.#flags  = flags;
    this.#facets = new Facets(facets);
    this.#doc    = doc;
  }

  #parent;
  #qname;
  #name;
  #flags;
  #facets;
  #doc;

  // TODO:FIXIT what do we do with this?
  #func;

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////
  
  toStr() { return this.#qname; }

  literalEncode$(out) {
    this.#parent.literalEncode$(out);
    out.w(this.#name);
  }

//////////////////////////////////////////////////////////////////////////
// Management
//////////////////////////////////////////////////////////////////////////

  static findMethod(qname, checked=true) {
    const slot = Slot.find(qname, checked);
    if (slot instanceof Method || checked)
      return ObjUtil.coerce(slot, Method.type$);
    return null;
  }

  static findField(qname, checked=true) {
    const slot = Slot.find(qname, checked);
    if (slot instanceof Field || checked)
      return ObjUtil.coerce(slot, Field.type$);
    return null;
  }

  static find(qname, checked=true) {
    let typeName, slotName;
    try
    {
      const dot = qname.indexOf('.');
      typeName = qname.substring(0, dot);
      slotName = qname.substring(dot+1);
    }
    catch (e)
    {
      throw Err.make("Invalid slot qname \"" + qname + "\", use <pod>::<type>.<slot>");
    }
    let _type = Type.find(typeName, false);
    if (_type == null) console.log("Type not found: " + _type);
    const type = Type.find(typeName, checked);
    if (type == null) return null;
    return type.slot(slotName, checked);
  }

  static findFunc(qname, checked=true) {
    const m = Slot.find(qname, checked);
    if (m == null) return null;
    return m.func();
  }

//////////////////////////////////////////////////////////////////////////
// Methods
//////////////////////////////////////////////////////////////////////////

  parent() { return this.#parent; }
  qname() { return this.#qname; }
  name() { return this.#name; }
  isField() { return this instanceof Field; }
  isMethod() { return this instanceof Method; }

//////////////////////////////////////////////////////////////////////////
// Flags
//////////////////////////////////////////////////////////////////////////

  flags$() { return this.#flags; }

  isAbstract()  { return (this.#flags & FConst.Abstract)  != 0; }
  isConst()     { return (this.#flags & FConst.Const)     != 0; }
  isCtor()      { return (this.#flags & FConst.Ctor)      != 0; }
  isEnum()      { return (this.#flags & FConst.Enum)      != 0; }
  isInternal()  { return (this.#flags & FConst.Internal)  != 0; }
  isNative()    { return (this.#flags & FConst.Native)    != 0; }
  isOverride()  { return (this.#flags & FConst.Override)  != 0; }
  isPrivate()   { return (this.#flags & FConst.Private)   != 0; }
  isProtected() { return (this.#flags & FConst.Protected) != 0; }
  isPublic()    { return (this.#flags & FConst.Public)    != 0; }
  isStatic()    { return (this.#flags & FConst.Static)    != 0; }
  isSynthetic() { return (this.#flags & FConst.Synthetic) != 0; }
  isVirtual()   { return (this.#flags & FConst.Virtual)   != 0; }

//////////////////////////////////////////////////////////////////////////
// Facets
//////////////////////////////////////////////////////////////////////////

  facets() { return this.#facets.list(); }
  hasFacet(type) { return this.facet(type, false) != null; }
  facet(type, checked=true) { return this.#facets.get(type, checked); }

//////////////////////////////////////////////////////////////////////////
// Documentation
//////////////////////////////////////////////////////////////////////////

  doc() { return this.#doc; }

//////////////////////////////////////////////////////////////////////////
// Util
//////////////////////////////////////////////////////////////////////////

  static #reservedWords = new js.Map();
  static
  {
    // must keep in sync with compilerJs::JsNode
    ["arguments",
     "as",
     "async",
     "await",
     "break",
     "case",
     "catch",
     "class",
     "const",
     "continue",
     "debugger",
     "default",
     "delete",
     "do",
     "else",
     "enum",
     "export",
     "eval",
     "extends",
     "false",
     "finally",
     "for",
     "from",
     "function",
     "get",
     "if",
     "implements",
     "import",
     "in",
     "instanceof",
     "interface",
     "let",
     "new",
     "null",
     "of",
     "package",
     "private",
     "protected",
     "public",
     "return",
     "self",      // not a reserved word but used heavily by the compiler
     "set",
     "static",
     "super",
     "switch",
     // "this",   
     "throw",
     "true",
     "try",
     "typeof",
     "var",
     "void",
     "while",
     "with",
     "yield",].forEach((n) => { Slot.#reservedWords.set(n, `${n}\$`); });
  }

  name$$(n) { return Slot.#reservedWords.get(n) ?? n; }
}