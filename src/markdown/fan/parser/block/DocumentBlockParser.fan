//
// Copyright (c) 2024, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   08 Oct 2024  Matthew Giannini  Creation
//

@Js
internal class DocumentBlockParser : BlockParser
{
  new make() { }

//////////////////////////////////////////////////////////////////////////
// BlockParser
//////////////////////////////////////////////////////////////////////////

  override Document block := Document() { private set }

  override const Bool isContainer := true

  override Bool canContain(Block block) { true }

  override BlockContinue? tryContinue(ParserState state)
  {
    BlockContinue.atIndex(state.index)
  }

  override Void addLine(SourceLine line) { }

}