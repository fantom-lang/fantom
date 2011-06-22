//
// Copyright (c) 2011, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 May 11  Brian Frank  Creation
//

**
** PublishCmd publishes a pod file from env to the repo
**
internal class PublishCmd : Command
{

//////////////////////////////////////////////////////////////////////////
// Usage
//////////////////////////////////////////////////////////////////////////

  override Str name() { "publish" }

  override Str summary() { "publish pod from env to repo" }

//////////////////////////////////////////////////////////////////////////
// Args/Opts
//////////////////////////////////////////////////////////////////////////

  @CommandArg
  {
    name = "pod"
    help = "name or local file path for pod to publish"
  }
  Str? pod

//////////////////////////////////////////////////////////////////////////
// Execution
//////////////////////////////////////////////////////////////////////////

  override Void run()
  {
    findFile
    parseSpec
    if (!confirm("Publish $srcSpec")) return
    publish
    printResult
  }

  private Void findFile()
  {
    // figure out if pod is name from local env or file path
    if (pod.contains(".") || pod.contains("/") || pod.contains("\\"))
    {
      this.file = parsePath(pod)
      if (!file.exists) throw err("Pod file not found: $file")
    }
    else
    {
      this.file = Env.cur.findPodFile(pod)
      if (file == null) throw err("Pod not found: $pod")
    }
  }

  private Void parseSpec()
  {
    try
      this.srcSpec = PodSpec.load(file)
    catch (Err e)
      throw err("Invalid or corrupt pod file: $file", e)
  }

  private Void publish()
  {
    pubSpec = repo.publish(file)
  }

  private Void printResult()
  {
    out.printLine("Publish success:")
    out.printLine
    printPodVersions([pubSpec])
  }

  private File? file         // findFile
  private PodSpec? srcSpec   // parseSpec
  private PodSpec? pubSpec   // publish
}