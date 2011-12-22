//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Aug 11  Brian Frank  Creation
//

using util
using web

**
** Main
**
@NoDoc
class Main : AbstractMain
{

  @Opt { help = "Generate docs for every installed pods" }
  Bool all

  @Opt { help = "Generation docs for Fantom core pods" }
  Bool allCore

  @Arg { help = "Name of pods to compile (does not update index)" }
  Str[] pods := [,]

  @Opt { help = "Delete outDir" }
  Bool clean

  @Opt { help = "Output dir for doc files" }
  File outDir := Env.cur.workDir + `doc/`

  DocEnv env := DefaultDocEnv()

  DocSpace[] spaces := DocSpace[,]

  override Int run()
  {
    // ensure outDir is a directory
    if (!outDir.isDir) outDir = outDir.uri.plusSlash.toFile

    // clean if specified
    if (clean)
    {
      echo("Delete [$outDir]")
      outDir.delete
    }

    // get space to doc based on arguments
    spaces = DocSpace[,]
    isAll := all || allCore
    podNames := isAll ? Env.cur.findAllPodNames : this.pods
    podNames.each |podName|
    {
      DocPod pod := env.space(podName)
      if (isAll) if (pod.meta["pod.docApi"] == "false") return
      if (allCore) if (!(pod.meta["proj.name"] ?: "").startsWith("Fantom ")) return
      spaces.add(pod)
    }

    // sort spaces
    if (isAll)
    {
      spaces.sort
      spaces.moveTo(spaces.find |p| { p.spaceName == "docIntro" }, 0)
      spaces.moveTo(spaces.find |p| { p.spaceName == "docLang" }, 1)
    }

    // write the documents
    if (isAll) writeTopIndex(env, DocTopIndex { it.spaces = this.spaces })
    spaces.each |space| { writeSpace(env, space) }
    return 0
  }

  virtual Void writeTopIndex(DocEnv env, DocTopIndex doc)
  {
    echo("Writing top-level index and css ...")

    // index.html
    file := outDir + `index.html`
    out := WebOutStream(file.out)
    env.render(out, doc)
    out.close

    // style.css
    Main#.pod.file(`/res/style.css`).copyInto(outDir, ["overwrite":true])
  }

  virtual Void writeSpace(DocEnv env, DocSpace space)
  {
    echo("Writing '$space.spaceName' ...")
    spaceDir := outDir + `$space.spaceName/`
    space.eachDoc |doc|
    {
      if (doc.docName == "pod-doc") return
      if (doc is DocRes)
        writeRes(env, spaceDir, doc)
      else
        writeDoc(env, spaceDir, doc)
    }
  }

  virtual Void writeRes(DocEnv env, File dir, DocRes res)
  {
    zip := Zip.open(res.pod.file)
    try
      zip.contents[res.uri].copyInto(dir, ["overwrite":true])
    finally
      zip.close
  }

  virtual Void writeDoc(DocEnv env, File dir, Doc doc)
  {
    file := dir + `${doc.docName}.html`
    out := WebOutStream(file.out)
    env.render(out, doc)
    out.close
  }
}

