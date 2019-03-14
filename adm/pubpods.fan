#! /usr/bin/env fan

using fanr
using web
using util

**
** Publish distro pods to the fanr repo on fantom.org for online documentation
**
class Main : AbstractMain
{
  override Int run()
  {
    // URI to use
    siteUri := `https://fantom.org/`

    // get pods to publish
    pods := Pod.list.findAll |p| { !p.name.startsWith("test") && p.name != "icons" }
    pods.sort |a,b| { a.name <=> b.name }
    echo
    echo("Publish:")
    pods.each |p| { echo("  " + p.name.padr(12) + " $p.version [" + Env.cur.findPodFile(p.name).osPath + "]") }
    echo

    // prompt for credentials
    Env.cur.out.print("username> ").flush  // email address
    username := Env.cur.in.readLine.trim
    Env.cur.out.print("password> ").flush
    password := Env.cur.in.readLine.trim

    // display post summary
    echo
    echo("##")
    echo("## Repo:       $siteUri")
    echo("## Pods:       $pods.size pods")
    echo("## Version:    $pods.first.version")
    echo("## Username:   $username")
    echo("##")
    echo

    // confirm
    Env.cur.out.print("Continue? [y|n]> ").flush
    confirm := Env.cur.in.readLine.trim
    if (!confirm.lower.contains("y")) { echo("Cancelled"); return 1 }

    // publish each pod
    echo
    echo("Publishing...")
    repo := Repo.makeForUri(siteUri+`fanr/`, username, password)
    pods.each |p|
    {
      file := Env.cur.findPodFile(p.name)
      echo("Publishing $p.name ...")
      repo.publish(file)
    }

    // rebuild docs
    c := (WebClient)repo->prepare("POST", siteUri + `fanr/rebuildDocs`)
    echo("Rebuild docs...")
    c.postStr("rebuild docs")
    if (c.resCode != 200) throw Err("Invalid HTTP response: $c.resCode")
    echo("Rebuild res: $c.resStr.trim")

    // success!
    echo
    echo("Published $pods.size pods!!!")
    echo
    return 0
  }
}

