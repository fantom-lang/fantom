//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Jul 09  Brian Frank  Creation
//

**
** PodFacetsParser is a light weight parser used to parse
** the facets of a pod definition before a the full compilation.
**
class PodFacetsParser
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with location and source.
  **
  new make(Location location, Str source)
  {
    this.location = location
    this.source   = source
    this.tokens   = TokenVal[,]
    this.facets   = Str:Obj?[:]
    this.usings   = "using sys\n"
  }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse the facets, if there is a tokenize error then
  ** throw CompilerErr.  Return this.
  **
  This parse()
  {
    tokenize
    while (curt === Token.usingKeyword) parseUsing
    while (curt === Token.at) parseFacet
    return this
  }

  **
  ** Pod name
  **
  readonly Str podName := "?"

  **
  ** List the keys we parsed.
  ** NOTE: currently we don't do any namespace resolution
  **
  Str[] keys() { facets.keys }

  **
  ** Get a pod facet with its qualified name.  If it doesn't
  ** exist then throw CompilerErr or return null depending on
  ** checked parameter.  If expected is passed and resulting
  ** value does not fit type then throw CompilerErr.
  ** NOTE: currently we don't do any namespace resolution
  **
  Obj? get(Str qname, Bool checked := true, Type expected := Obj?#)
  {
    // lookup facet (names may be not resolved to full qname)
    facet := facets[qname]
    if (facet == null)
    {
      colon := qname.index("::")
      if (colon == null) throw ArgErr("Not qualified name: $qname")
      facet = facets[qname[colon+2..-1]]
    }

    // if not found return null or throw CompilerErr
    if (facet == null)
    {
      if (!checked) return null
      throw CompilerErr("Pod facet not found '$qname'", location)
    }

    // parse value is still unparsed
    try
    {
      if (facet.val == null)
      {
        facet.val = (usings + facet.unparsed).in.readObj
        facet.unparsed = null
      }
    }
    catch (Err e)
    {
      throw CompilerErr("Cannot parse '$qname' value: $e", facet.loc, e)
    }

    // check type
    if (!facet.val.type.fits(expected))
      throw CompilerErr("Invalid type for pod facet '$qname'; expected '$expected' not '$facet.val.type'", facet.loc)

    return facet.val
  }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  private Void tokenize()
  {
    // read everything up to pod <id>
    tokenizer := Tokenizer(Compiler(CompilerInput()), location, source, false)
    lastIsPod := false
    while (true)
    {
      token := tokenizer.next
      if (token.kind === Token.eof) throw err("Unexpected end of file")
      if (token.kind === Token.identifier)
      {
        if (lastIsPod) { podName = token.val; break }
        lastIsPod = token.val == "pod"
      }
      tokens.add(token)
    }
    tokens.removeAt(-1)
    cur  = tokens[0]
    curt = cur.kind
  }

  private Void parseUsing()
  {
    s := "using "
    consume
    s += consumeId
    if (curt === Token.doubleColon)
    {
      consume
      s += "::" + consumeId
      if (curt === Token.asKeyword)
      {
        consume
        s += " as " + consumeId
      }
    }
    eos
    usings += "$s\n"
  }

  private Void parseHeader()
  {
    loc := cur
    if (consumeId != "pod") throw err("Expecting 'pod' keyword", loc)
    podName = consumeId
  }

  private Void parseFacet()
  {
    loc := cur
    consume(Token.at)
    name := consumeId
    if (curt === Token.doubleColon)
    {
      consume
      name = name + "::" + consumeId
    }
    facet := PodFacet(loc, name)
    if (curt === Token.assign) { consume; expr(facet) }
    else facet.val = true
    eos
    facets[name] = facet
  }

  private Void expr(PodFacet facet)
  {
    switch (curt)
    {
      case Token.strLiteral:
      case Token.intLiteral:
      case Token.floatLiteral:
      case Token.decimalLiteral:
      case Token.durationLiteral:
      case Token.uriLiteral:
        facet.val = consume.val
      default:
        complexExpr(facet)
    }
  }

  private Void complexExpr(PodFacet facet)
  {
    // just consume everything up until next @id= or end
    s := StrBuf()
    while (pos < tokens.size)
    {
      if (curt === Token.at && pos+2 < tokens.size &&
          tokens[pos+1].kind == Token.identifier &&
          tokens[pos+2].kind == Token.assign) break
      s.add(consume.toCode)
    }
    facet.unparsed = s.toStr
  }

  private Void eos()
  {
    if (curt === Token.semicolon) consume
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizing
//////////////////////////////////////////////////////////////////////////

  **
  ** Throw a CompilerError for current location
  **
  private CompilerErr err(Str msg, Location? loc := null)
  {
    if (loc == null) loc = cur
    throw CompilerErr(msg, loc)
  }

  **
  ** Verify current is an identifier, consume it, and return it.
  **
  private Str consumeId()
  {
    if (curt !== Token.identifier)
      throw err("Expected identifier, not '$cur'")
    return consume.val
  }

  **
  ** Check that the current token matches the specified
  ** type, but do not consume it.
  **
  private Void verify(Token kind)
  {
    if (curt !== kind)
      throw err("Expected '$kind.symbol', not '$cur'");
  }

  **
  ** Consume the current token and return consumed token.
  ** If kind is non-null then verify first
  **
  private TokenVal? consume(Token? kind := null)
  {
    // verify if not null
    if (kind != null) verify(kind)

    // save the current we are about to consume for return
    result := cur

    // advance
    try
      this.cur = tokens[++pos]
    catch
      this.cur = TokenVal(Token.eof)
    this.curt = cur.kind

    return result
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  static Void main(Str[] args)
  {
    if (args.isEmpty) { echo("usage PodFacetsParser <pod.fan>"); return }
    f := args.first.toUri.toFile
    t1 := Duration.now
    p := PodFacetsParser(Location.makeFile(f), f.readAllStr).parse
    t2 := Duration.now
    echo("")
    echo("Parsed '$p.podName' ${(t2-t1).toLocale}")
    echo("")
    p.keys.each |key| { print(p, key) }
  }

  private static Void print(PodFacetsParser p, Str key, Type expected := Obj?#)
  {
    try
      echo("@$key = " + p.get(key, true, expected))
    catch (CompilerErr e)
      echo("@$key = " + p.facets[key].unparsed  + " (cannot parse)")
    catch (Err e)
      echo("@$key = $e")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  Location location            // location of entire file
  private Str source           // source file to parse
  private TokenVal[] tokens    // tokenize
  private Int pos              // offset into tokens for cur
  private TokenVal? cur        // current token
  private Token? curt          // current token type
  private Str:PodFacet facets  // facets map
  private Str usings           // using imports
}

internal class PodFacet
{
  new make(Location l, Str n) { loc = l; name = n }
  Location loc
  Str name
  Obj? val
  Str? unparsed
}