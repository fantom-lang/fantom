//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   23 Oct 2024  Matthew Giannini  Creation
//

**
** Custom delimiter processor for additional delimiters besides '_' and '*'.
**
** Note that implementations of this need to be thread-safe, the same instance
** may be used by multiple parsers.
**
@Js
const mixin DelimiterProcessor
{
  ** The character that marks the beginning of a delimited node, must not clash
  ** with any built-in special characters.
  abstract Int openingChar()

  ** The character that marks the ending of a delimited node, must not clas with any
  ** built-in special characters. Note that for a symmetric delimiter such as '*',
  ** this is the same as the opening.
  abstract Int closingChar()

  ** Minimum number of delimiter characters that are needed to activate this.
  ** Must be at least 1.
  abstract Int minLen()

  ** Process the delimiter runs.
  **
  ** The processor can examine the runs and the nodes and decide if it wants to
  ** process or not. If not, it should not change any nodes and return 0.
  ** If yes, it should do the processing (wrapping nodes, etc.) and then return
  ** how many delimiters were used.
  **
  ** Note that removal (unlinking) of the used delimiter `Text` nodes is done by
  ** the caller.
  **
  ** Returns how many delimiters were used; must not be greater than the length
  ** of either opener or closer
  abstract Int process(Delimiter openingRun, Delimiter closingRun)
}

**************************************************************************
** EmphasisDelimiterProcessor
**************************************************************************

@Js
@NoDoc abstract const class EmphasisDelimiterProcessor : DelimiterProcessor
{
  protected new make(Int delimChar)
  {
    this.delimChar = delimChar
  }

  protected const Int delimChar

  override Int openingChar() { delimChar }
  override Int closingChar() { delimChar }
  override Int minLen() { 1 }

  override Int process(Delimiter openingRun, Delimiter closingRun)
  {
    // "multiple of 3" rule for internal delimiter runs
    if ((openingRun.canClose || closingRun.canOpen) &&
           closingRun.origSize % 3 != 0 &&
           (openingRun.origSize + closingRun.origSize) % 3 == 0)
    {
      return 0
    }

    usedDelims := 0
    Node? emphasis := null
    // calculate actual number of delimiters used from this closer
    if (openingRun.size >= 2 && closingRun.size >= 2)
    {
      usedDelims = 2
      emphasis = StrongEmphasis(delimChar.toChar * 2)
    }
    else
    {
      usedDelims = 1
      emphasis = Emphasis(delimChar.toChar)
    }

    sourceSpans := SourceSpans.empty
    sourceSpans.addAllFrom(openingRun.openers(usedDelims))

    opener := openingRun.opener
    Node.eachBetween(opener, closingRun.closer) |node|
    {
      emphasis.appendChild(node)
      sourceSpans.addAll(node.sourceSpans)
    }

    sourceSpans.addAllFrom(closingRun.closers(usedDelims))

    emphasis.setSourceSpans(sourceSpans.sourceSpans)
    opener.insertAfter(emphasis)

    return usedDelims
  }
}

**************************************************************************
** AsteriskDelimiterProcessor
**************************************************************************

@Js
internal const class AsteriskDelimiterProcessor : EmphasisDelimiterProcessor
{
  new make() : super('*') { }
}

**************************************************************************
** UnderscoreDelimiterProcessor
**************************************************************************

@Js
internal const class UnderscoreDelimiterProcessor : EmphasisDelimiterProcessor
{
  new make() :super('_') { }
}