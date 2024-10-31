//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Oct 2024  Matthew Giannini  Creation
//

**
** Stores all definitions from the document by definition type
**
@Js
internal class Definitions
{
  new make() { }

  private Type:DefinitionMap defsByType := [:]

  ** Add all definitions from this map into the global set of definitions for that type
  Void addDefinitions(DefinitionMap map)
  {
    existing := get(map.of)
    if (existing == null) defsByType.add(map.of, map)
    else existing.addAll(map)
  }

  ** Get a definition of the given type with the given label
  Block? def(Type of, Str label)
  {
    map := get(of)
    return map == null ? null : map.get(label)
  }

  private DefinitionMap? get(Type of) { defsByType[of] }

}

**
** A map that can be used to store and lookup reference definitions by a label.
** The labels are case-insensitive and normalized, the same way as for
** LinkReferenceDefinition nodes.
**
@Js
final class DefinitionMap
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  new make(Type of)
  {
    this.of = of
    if (!of.fits(Block#)) throw ArgErr("${of} is not a Block")
  }

  ** The type of definition stored in this map
  const Type of

  ** Store the definitions while maintaining order
  private Str:Block defs := Str:Block[:] { ordered = true }

//////////////////////////////////////////////////////////////////////////
// Definition Map
//////////////////////////////////////////////////////////////////////////

  @Operator
  Block? get(Str label, Block? def := null)
  {
    normLabel := Esc.normalizeLabelContent(label)
    return defs.get(normLabel, def)
  }

  Void addAll(DefinitionMap that)
  {
    that.defs.each |def, label|
    {
      // note that keys are already normalized, so we can add them directly
      if (!defs.containsKey(label)) set(label, def)
    }
  }

  ** Store a new definition unless one is already in the map. If there is no definition
  ** for the label yet, return null. Otherwise return the existing definition
  **
  ** The label is normalized by the definition map before storing.
  Block? putIfAbsent(Str label, Block def)
  {
    normalizedLabel := Esc.normalizeLabelContent(label)

    // spec: when there are multiple matching linke reference definitions, the
    // first is used
    if (!defs.containsKey(normalizedLabel))
    {
      set(normalizedLabel, def)
      return null
    }
    return defs[normalizedLabel]
  }

  ** choke-point for setting a label:def pair. It ensures
  ** the def is an instance of the type stored by this map.
  private Void set(Str normLabel, Block def)
  {
    if (!def.typeof.fits(of)) throw ArgErr("cannot insert ${def.typeof} into map of ${of}")
    defs[normLabel] = def
  }

}