//
// Copyright (c) 2010, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   12 Jan 2010  Andy Frank  Creation
//   17 Apr 2023  Matthew Giannini  Refactor for ES 
//

class Sys extends Obj {
  constructor() { super(); }

//////////////////////////////////////////////////////////////////////////
// Init Types
//////////////////////////////////////////////////////////////////////////

  static genericParamTypes = [];
  static AType = undefined;
  static BType = undefined;
  static CType = undefined;
  static DType = undefined;
  static EType = undefined;
  static FType = undefined;
  static GType = undefined;
  static HType = undefined;
  static KType = undefined;
  static LType = undefined;
  static MType = undefined;
  static RType = undefined;
  static VType = undefined;

  static initGenericParamTypes() {
    Sys.AType = Sys.#initGeneric('A');
    Sys.BType = Sys.#initGeneric('B');
    Sys.CType = Sys.#initGeneric('C');
    Sys.DType = Sys.#initGeneric('D');
    Sys.EType = Sys.#initGeneric('E');
    Sys.FType = Sys.#initGeneric('F');
    Sys.GType = Sys.#initGeneric('G');
    Sys.HType = Sys.#initGeneric('H');
    Sys.KType = Sys.#initGeneric('K');
    Sys.LType = Sys.#initGeneric('L');
    Sys.MType = Sys.#initGeneric('M');
    Sys.RType = Sys.#initGeneric('R');
    Sys.VType = Sys.#initGeneric('V');
  }

  static #initGeneric(ch) {
    const name = ch;
    try {
      const pod = Pod.find("sys");
      return Sys.genericParamTypes[ch] = pod.at$(name, "sys::Obj", [], 0);
    }
    catch (err) {
      throw Sys.initFail("generic " + name, err);
    }
  }

  static genericParamType(name) {
    if (name.length == 1)
      return Sys.genericParamTypes[name];
    else
      return null;
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  static initWarn(field, e) {
    ObjUtil.echo("WARN: cannot init Sys." + field);
    ObjUtil.echo(e);
    //e.printStackTrace();
  }

  static initFail(field, e) {
    ObjUtil.echo("ERROR: cannot init Sys." + field);
    ObjUtil.echo(e);
    //e.printStackTrace();
    throw new Error("Cannot boot fan: " + e);
  }

}