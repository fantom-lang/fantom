//
// Copyright (c) 2023, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   02 May 2023  Matthew Giannini  Creation
//

**
** ModuleSystem
**
abstract const class ModuleSystem
{
  new make(File nodeDir)
  {
    this.nodeDir = nodeDir
  }

  const File nodeDir

  abstract Str moduleType()
  abstract File moduleDir()
  abstract Str ext()
  virtual File file(Str basename) { moduleDir.plus(`${basename}.${ext}`) }

  virtual Void writePackageJson([Str:Obj?] json)
  {
    str := Type.find("util::JsonOutStream").method("writeJsonToStr").call(json)
    nodeDir.plus(`package.json`).out.writeChars(str).flush.close
  }

  virtual This writeBeginModule(OutStream out) { this }
  virtual OutStream writeEndModule(OutStream out) { out }

  OutStream writeInclude(OutStream out, Str module, Str baseDir := "")
  {
    p   := "${baseDir}${module}"
    uri := module.toUri
    if (uri.ext != null)
    {
      module = uri.basename
      p = "./${baseDir.toUri}${uri.basename}.${ext}"
    }
    return doWriteInclude(out, module, p)
  }
  protected abstract OutStream doWriteInclude(OutStream out, Str module, Str path)

  abstract OutStream writeExports(OutStream out, Str[] exports)
}

**************************************************************************
** CommonJs
**************************************************************************

const class CommonJs : ModuleSystem
{
  new make(File nodeDir) : super(nodeDir)
  {
  }
  static const Str moduleStart :=
  """(function () {
     const __require = (m) => {
       const name = m.split('.')[0];
       const fan = this.fan;
       if (typeof require === 'undefined') return name == "fan" ? fan : fan[name];
       try { return require(`\${m}`); } catch (e) { /* ignore */ }
     }
     """

  override const Str moduleType := "cjs"
  override const File moduleDir := nodeDir.plus(`node_modules/`)
  override const Str ext := "js"
  override This writeBeginModule(OutStream out)
  {
    out.printLine(CommonJs.moduleStart)
    return this
  }
  override OutStream writeEndModule(OutStream out)
  {
    out.printLine("}).call(this);")
  }
  protected override OutStream doWriteInclude(OutStream out, Str module, Str path)
  {
    // we assume the module is always in the Node.js path so we ignore
    // any path and just require the name of the module
    out.printLine("const ${module} = __require('${path.toUri.name}');")
  }
  override OutStream writeExports(OutStream out, Str[] exports)
  {
    out.print("module.exports = {")
    exports.each |export| { out.print("${export},") }
    return out.printLine("};")
  }
}

**************************************************************************
** Esm
**************************************************************************

const class Esm : ModuleSystem
{
  new make(File nodeDir) : super(nodeDir)
  {
  }

  override const Str moduleType := "esm"
  override const File moduleDir := nodeDir.plus(`esm/`)
  override const Str ext := "js"
  override Void writePackageJson([Str:Obj?] json)
  {
    json["type"] = "module"
    super.writePackageJson(json)
  }
  override OutStream writeExports(OutStream out, Str[] exports)
  {
    out.print("export {")
    exports.each |export| { out.print("${export},") }
    return out.printLine("};")
  }
  protected override OutStream doWriteInclude(OutStream out, Str module, Str path)
  {
    // out.printLine("const ${module} = await (async function() { try { return await import('${path}'); } catch (err) { /* ignore */ } })();")
    out.printLine("import * as ${module} from '${path}';")
  }

}