//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   21 Jul 08  Brian Frank  Creation
//

using fwt

**
** Flux specialization of normal fwt commands.  All FluxCommands
** are identified by a string id which is used to map the command
** in various APIs and bind to localized resources and key bindings.
** Command id should be globally scoped.  Common built-in commands
** are identified with a simple string like "cut" and a constant
** in `CommandId`.  Custom commands implemented by plugin pods should
** be prefixed with their pod name such as "imageEditor.resizeImage".
**
** All FluxCommands are assumed to be localized by mapping their name,
** icon, and default accelerator to a localized properties file.  The
** default 'make' constructor routes to `fwt::Command.makeLocale`.
**
** If a FluxCommand supports undo/redo, then it should be posted to
** the 'View.commandStack'.  However it should not maintain references
** to a specific view instance since the command stack is persisted
** between hyperlinks for a given URI.
**
class FluxCommand : Command
{

  **
  ** Construct with id and optional pod.  The pod defines where
  ** to look for localized name, icon, and default accelerator.
  ** If pod is omitted, it defaults to the "flux" pod.  This
  ** method routes to `fwt::Command.makeLocale` where 'id' is
  ** passed as the 'keyBase'.
  **
  ** The default accelerator is defined by the localized property
  ** definition.  But we allow the user to redefine key bindings
  ** via `KeyOptions`.  This constructor automatically checks for
  ** additional key bindings.
  **
  new make(Str id, Pod pod := Flux#.pod)
    : super.makeLocale(pod, id)
  {
    this.id = id

    // check for explicit binding
    binding := KeyOptions.load.bindings[id]
    try
    {
      if (binding != null) accelerator = Key(binding)
    }
    catch Pod.of(this).log.err("FluxCommand: invalid syntax in @keysBindings '$id:$binding'")
  }

  **
  ** The id serves as the string identifer for processing
  ** the command and looking up resources such as localization
  ** and key bindings.
  **
  const Str id

  **
  ** Get the flux Frame associated with this command.
  **
  Frame? frame
  {
    get { return &frame ?: Desktop.focus?.window }
    internal set
  }

  **
  ** Get the flux View associated with this command.
  **
  View? view() { return frame?.view }

}