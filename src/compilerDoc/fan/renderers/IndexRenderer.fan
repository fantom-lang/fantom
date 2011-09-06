//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   6 Sep 2011  Andy Frank  Creation
//

using fandoc
using syntax
using web

**
** IndexRenderer renders main doc index.
**
** Manuals
** =======
**
**   <h2>Manuals</h2>
**   <table>
**     <tr>
**       <td><a>{pod.name}</a></td>
**       <td>
**         {pod.summary}
**         <div><a>{chapter.name}</a>, ...</div>
**       </td>
**     </td>
**   </table>
**
** APIs
** ====
**
**   <h2>APIs</h2>
**   <table>
**     <tr>
**       <td><a>{pod.name}</a></td>
**       <td>{pod.summary}</td>
**     </td>
**   </table>
**  </div>
**
class IndexRenderer : DocRenderer
{
  ** Constructor with env, out params.
  new make(DocEnv env, WebOutStream out) : super(env, out)
  {
    this.manuals = DocPod[,]
    this.apis    = DocPod[,]
    env.pods.each |p|
    {
      if (p.isManual) manuals.add(p)
      else apis.add(p)
    }
    manuals.moveTo(manuals.find |p| { p.name == "docIntro" }, 0)
    manuals.moveTo(manuals.find |p| { p.name == "docFanr" }, 3)
  }

  ** Manual list for index.
  DocPod[] manuals

  ** API list for index
  DocPod[] apis

  ** Write manuals index.
  virtual Void writeManuals()
  {
    out.div("class='manuals'")
    out.h2.w("Manuals").h2End
    out.table
    manuals.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary)
        .div
        pod.chapters.each |ch,i|
        {
          if (i > 0) out.w(", ")
          out.a(`${pod.name}/${ch.name}.html`).w("$ch.name").aEnd
        }
        out.divEnd
        out.tdEnd
     out.trEnd
    }
    out.tableEnd
    out.divEnd
  }

  ** Write API index.
  virtual Void writeApis()
  {
    out.div("class='apis'")
    out.h2.w("APIs").h2End
    out.table
    apis.each |pod|
    {
      out.tr
        .td.a(`${pod.name}/index.html`).w(pod.name).aEnd.tdEnd
        .td.w(pod.summary).tdEnd
        .trEnd
    }
    out.tableEnd
    out.divEnd
  }
}

