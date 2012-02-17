//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Sep 05  Brian Frank  Creation
//   29 Aug 06  Brian Frank  Ported from Java to Fan
//

**
** CNamespace is responsible for providing a unified view pods, types,
** and slots between the entities currently being compiled and the
** entities being imported from pre-compiled pods.
**
abstract class CNamespace
{

//////////////////////////////////////////////////////////////////////////
// Initialization
//////////////////////////////////////////////////////////////////////////

  **
  ** Once the sub class is initialized, it must call this
  ** method to initialize our all predefined values.
  **
  protected Void init()
  {
    // sys pod
    sysPod = resolvePod("sys", null)

    // error placeholder type
    error = GenericParameterType(this, "Error")

    // nothing placeholder type
    nothingType = GenericParameterType(this, "Nothing")

    // generic parameter types
    genericParams =
    [
      "A": genericParam("A"),
      "B": genericParam("B"),
      "C": genericParam("C"),
      "D": genericParam("D"),
      "E": genericParam("E"),
      "F": genericParam("F"),
      "G": genericParam("G"),
      "H": genericParam("H"),
      "K": genericParam("K"),
      "L": genericParam("L"),
      "M": genericParam("M"),
      "R": genericParam("R"),
      "V": genericParam("V"),
    ].ro()

    // types
    objType      = sysType("Obj")
    boolType     = sysType("Bool")
    enumType     = sysType("Enum")
    facetType    = sysType("Facet")
    intType      = sysType("Int")
    floatType    = sysType("Float")
    decimalType  = sysType("Decimal")
    strType      = sysType("Str")
    strBufType   = sysType("StrBuf")
    durationType = sysType("Duration")
    listType     = sysType("List")
    mapType      = sysType("Map")
    funcType     = sysType("Func")
    errType      = sysType("Err")
    podType      = sysType("Pod")
    typeType     = sysType("Type")
    slotType     = sysType("Slot")
    fieldType    = sysType("Field")
    methodType   = sysType("Method")
    rangeType    = sysType("Range")
    testType     = sysType("Test")
    uriType      = sysType("Uri")
    voidType     = sysType("Void")
    fieldNotSetErrType = sysType("FieldNotSetErr")

    // methods
    objTrap            = sysMethod(objType,    "trap")
    objWith            = sysMethod(objType,    "with")
    objToImmutable     = sysMethod(objType,    "toImmutable")
    boolNot            = sysMethod(boolType,   "not")
    intIncrement       = sysMethod(intType,    "increment")
    intDecrement       = sysMethod(intType,    "decrement")
    intPlus            = sysMethod(intType,    "plus")
    floatPlus          = sysMethod(floatType,  "plus")
    floatMinus         = sysMethod(floatType,  "minus")
    strPlus            = sysMethod(strType,    "plus")
    strBufMake         = sysMethod(strBufType, "make")
    strBufAdd          = sysMethod(strBufType, "add")
    strBufToStr        = sysMethod(strBufType, "toStr")
    listMake           = sysMethod(listType,   "make")
    listMakeObj        = sysMethod(listType,   "makeObj")
    listAdd            = sysMethod(listType,   "add")
    mapMake            = sysMethod(mapType,    "make")
    mapSet             = sysMethod(mapType,    "set")
    enumOrdinal        = sysMethod(enumType,   "ordinal")
    funcBind           = sysMethod(funcType,   "bind")
    rangeMakeInclusive = sysMethod(rangeType,  "makeInclusive")
    rangeMakeExclusive = sysMethod(rangeType,  "makeExclusive")
    slotFindMethod     = sysMethod(slotType,   "findMethod")
    slotFindFunc       = sysMethod(slotType,   "findFunc")
    podFind            = sysMethod(podType,    "find")
    podLocale          = sysMethod(podType,    "locale")
    typePod            = sysMethod(typeType,   "pod")
    typeField          = sysMethod(typeType,   "field")
    typeMethod         = sysMethod(typeType,   "method")
    funcCall           = sysMethod(funcType,   "call")
    fieldNotSetErrMake = sysMethod(fieldNotSetErrType, "make")

    // mock methods
    mockFlags := FConst.Public + FConst.Virtual
    funcEnterCtor   = MockMethod(funcType, "enterCtor",   mockFlags, voidType, [objType])
    funcExitCtor    = MockMethod(funcType, "exitCtor",    mockFlags, voidType, CType[,])
    funcCheckInCtor = MockMethod(funcType, "checkInCtor", mockFlags, voidType, [objType])

    itBlockType = FuncType.makeItBlock(objType.toNullable)
    itBlockType.inferredSignature = true
  }

  private CType genericParam(Str name)
  {
    t := GenericParameterType(this, name)
    n := t.toNullable
    typeCache[t.signature] = t
    typeCache[n.signature] = n
    return t
  }

  private CType sysType(Str name)
  {
    return sysPod.resolveType(name, true)
  }

  private CMethod sysMethod(CType t, Str name)
  {
    m := t.method(name)
    if (m == null) throw Err("Cannot resolve '${t.qname}.$name' method in namespace")
    return m
  }

//////////////////////////////////////////////////////////////////////////
// Cleanup
//////////////////////////////////////////////////////////////////////////

  Void cleanup()
  {
    bridgeCache.each |bridge|
    {
      try
        bridge.cleanup
      catch (Err e)
        e.trace
    }
  }

//////////////////////////////////////////////////////////////////////////
// Resolution
//////////////////////////////////////////////////////////////////////////

  **
  ** Resolve to foreign function interface bridge.
  ** Bridges are loaded once for each compiler session.
  **
  private CBridge resolveBridge(Str name, Loc? loc)
  {
    // check cache
    bridge := bridgeCache[name]
    if (bridge != null) return bridge

    // delegate to findBridge
    bridge = findBridge(compiler, name, loc)

    // put into cache
    bridgeCache[name] = bridge
    return bridge
  }
  private Str:CBridge bridgeCache := Str:CBridge[:]  // keyed by pod name

  **
  ** Subclass hook to resolve a FFI name to a CBridge implementation.
  ** Throw CompilerErr if there is a problem resolving the bridge.
  ** The default implementation attempts to resolve the indexed
  ** property "compiler.bridge.$name" to a Type qname.
  **
  protected virtual CBridge findBridge(Compiler compiler, Str name, Loc? loc)
  {
    // resolve the compiler bridge using indexed props
    t := Env.cur.index("compiler.bridge.${name}")
    if (t.size > 1)
      throw CompilerErr("Multiple FFI bridges available for '$name': $t", loc)
    if (t.size == 0)
      throw CompilerErr("No FFI bridge available for '$name'", loc)

    // construct bridge instance
    try
      return Type.find(t.first).make([compiler])
    catch (Err e)
      throw CompilerErr("Cannot construct FFI bridge '$t.first'", loc, e)
  }

  **
  ** Attempt to import the specified pod name against our
  ** dependency library.  If not found then throw CompilerErr.
  **
  CPod resolvePod(Str podName, Loc? loc)
  {
    // check cache
    pod := podCache[podName]
    if (pod != null) return pod

    if (podName[0] == '[')
    {
      // we have a FFI, route to bridge
      sep := podName.index("]")
      ffi := podName[1..<sep]
      package := podName[sep+1..-1]
      pod = resolveBridge(ffi, loc).resolvePod(package, loc)
    }
    else
    {
      // let namespace resolve it
      pod = findPod(podName)
      if (pod == null)
        throw CompilerErr("Pod not found '$podName'", loc)
    }

    // stash in the cache and return
    podCache[podName] = pod
    return pod
  }
  private Str:CPod podCache := Str:CPod[:]  // keyed by pod name

  **
  ** Subclass hook to resolve a pod name to a CPod implementation.
  ** Return null if not found.
  **
  protected abstract CPod? findPod(Str podName)

  **
  ** Attempt resolve a signature against our dependency
  ** library.  If not a valid signature or it can't be
  ** resolved, then throw Err.
  **
  CType resolveType(Str sig)
  {
    // check our cache first
    t := typeCache[sig]
    if (t != null) return t

    // parse it into a CType
    t = TypeParser.resolve(this, sig)
    typeCache[sig] = t
    return t
  }
  internal Str:CType typeCache := Str:CType[:]   // keyed by signature

  **
  ** Attempt resolve a slot against our dependency
  ** library.  If can't be resolved, then throw Err.
  **
  CSlot resolveSlot(Str qname)
  {
    dot := qname.indexr(".")
    slot := resolveType(qname[0..<dot]).slot(qname[dot+1..-1])
    if (slot == null) throw Err("Cannot resolve slot: $qname")
    return slot
  }

  **
  ** Map one of the generic parameter types such as "sys::V" into a CType
  **
  CType genericParameter(Str id)
  {
    t := genericParams[id]
    if (t == null) throw UnknownTypeErr("sys::$id")
    return t
  }

//////////////////////////////////////////////////////////////////////////
// Compiler
//////////////////////////////////////////////////////////////////////////

  ** Used for resolveBridge only
  internal Compiler compiler() { c ?: throw Err("Compiler not associated with CNamespace") }
  internal Compiler? c

//////////////////////////////////////////////////////////////////////////
// Dependencies
//////////////////////////////////////////////////////////////////////////

  **
  ** Map of dependencies keyed by pod name set in ResolveDepends.
  **
  [Str:CDepend]? depends

//////////////////////////////////////////////////////////////////////////
// Predefined
//////////////////////////////////////////////////////////////////////////

  CPod? sysPod { private set }

  // generic parameters like sys::K, sys::V
  [Str:CType]? genericParams { private set }

  // place holder type used for resolve errors
  CType? error { private set }

  // place holder type used to indicate nothing (like throw expr)
  CType? nothingType { private set }

  // generic type for it block until we can infer type
  FuncType? itBlockType { private set }

  CType? objType              { private set }
  CType? boolType             { private set }
  CType? enumType             { private set }
  CType? facetType            { private set }
  CType? intType              { private set }
  CType? floatType            { private set }
  CType? decimalType          { private set }
  CType? strType              { private set }
  CType? strBufType           { private set }
  CType? durationType         { private set }
  CType? listType             { private set }
  CType? mapType              { private set }
  CType? funcType             { private set }
  CType? errType              { private set }
  CType? podType              { private set }
  CType? typeType             { private set }
  CType? slotType             { private set }
  CType? fieldType            { private set }
  CType? methodType           { private set }
  CType? rangeType            { private set }
  CType? testType             { private set }
  CType? uriType              { private set }
  CType? voidType             { private set }
  CType? fieldNotSetErrType   { private set }

  CMethod? objTrap            { private set }
  CMethod? objWith            { private set }
  CMethod? objToImmutable     { private set }
  CMethod? boolNot            { private set }
  CMethod? intIncrement       { private set }
  CMethod? intDecrement       { private set }
  CMethod? intPlus            { private set }
  CMethod? floatPlus          { private set }
  CMethod? floatMinus         { private set }
  CMethod? strPlus            { private set }
  CMethod? strBufMake         { private set }
  CMethod? strBufAdd          { private set }
  CMethod? strBufToStr        { private set }
  CMethod? listMake           { private set }
  CMethod? listMakeObj        { private set }
  CMethod? listAdd            { private set }
  CMethod? mapMake            { private set }
  CMethod? mapSet             { private set }
  CMethod? enumOrdinal        { private set }
  CMethod? funcBind           { private set }
  CMethod? rangeMakeInclusive { private set }
  CMethod? rangeMakeExclusive { private set }
  CMethod? slotFindMethod     { private set }
  CMethod? slotFindFunc       { private set }
  CMethod? podFind            { private set }
  CMethod? podLocale          { private set }
  CMethod? typePod            { private set }
  CMethod? typeField          { private set }
  CMethod? typeMethod         { private set }
  CMethod? funcEnterCtor      { private set }
  CMethod? funcExitCtor       { private set }
  CMethod? funcCheckInCtor    { private set }
  CMethod? funcCall           { private set }
  CMethod? fieldNotSetErrMake { private set }

}