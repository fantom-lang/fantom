//
// Copyright (c) 2016, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 2016  Andy Frank  Creation
//

using web

**************************************************************************
** MutationObserver
**************************************************************************

** MutationObserver invokes a callback when DOM modifications occur.
@Js
class MutationObserver
{
  ** Constructor.
  new make(|MutationRec[]| callback)
  {
    this.callback = callback
  }

  ** Register to receive DOM mutation events for given node.
  ** At least one option is required:
  **  - "childList": 'true' to observe node additions and removals on target (including text nodes)
  **  - "attrs":  'true' to observe target attribute mutations
  **  - "charData": 'true' to observe target data mutation
  **  - "subtree": 'true' to observe target and target's descendant mutations
  **  - "attrOldVal": 'true' to capture attribute value before mutation (requires "attrs":'true')
  **  - "charDataOldVal": 'true' to capture target's data before mutation (requires "charData":'true')
  **  - "attrFilter": Str[] whitelist of attribute names to observe (requires "attrs":'true')
  native This observe(Elem target, Str:Obj opts)

  ** Empties this observers's record queue and returns what was in there.
  native MutationRec[] takeRecs()

  ** Disconnect this observer from receiving DOM mutation events.
  native This disconnect()

  @NoDoc
  internal Func? callback
}

**************************************************************************
** MutationRec
**************************************************************************

** MutationRec represents an individual DOM mutation.
@Js
class MutationRec
{
  ** It-block constructor.
  internal new make(|This|? f := null) { if (f != null) f(this) }

  ** Mutation type:
  **  - "attrs" if the mutation was an attribute mutation
  **  - "charData" if it was a mutation to a CharacterData node
  **  - "childList" if it was a mutation to the tree of nodes
  Str type

  ** Target node that mutation affected, depending on the 'type':
  **  - For "attrs", it is the element whose attribute changed
  **  - For "charData", it is the CharacterData node
  **  - For "childList", it is the node whose children changed
  Elem target

  ** List of nodes added, or empyt list if no nodes added.
  Elem[] added

  ** List of nodes removed, or empty list if no nodes removed.
  Elem[] removed

  ** Previous sibling of the added or removed nodes, or null
  ** if not nodes added or removed.
  Elem? prevSibling

  ** Next sibling of the added or removed nodes, or null if
  ** no nodes added or removed.
  Elem? nextSibling

  ** Name of the changed attribute, or null if no attribute was changed.
  Str? attr

  ** Namespace of the changed attribute, or null if no attribute was changed.
  Str? attrNs

  ** Old value, depending on 'type':
  **  - For "attrs", it is the value of the changed attribute before the change
  **  - For "charData", it is the data of the changed node before the change
  **  - For "childList", it is null
  Str? oldVal
}