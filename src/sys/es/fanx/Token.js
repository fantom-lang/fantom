//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   11 May 09  Andy Frank  Creation
//

/**
 * Token defines the token type constants and provides
 * associated utility methods.
 */
function fanx_Token() {}

//////////////////////////////////////////////////////////////////////////
// Token Type Ids
//////////////////////////////////////////////////////////////////////////

fanx_Token.EOF              = -1;
fanx_Token.ID               = 0;
fanx_Token.BOOL_LITERAL     = 1;
fanx_Token.STR_LITERAL      = 2;
fanx_Token.INT_LITERAL      = 3;
fanx_Token.FLOAT_LITERAL    = 4;
fanx_Token.DECIMAL_LITERAL  = 5;
fanx_Token.DURATION_LITERAL = 6;
fanx_Token.URI_LITERAL      = 7;
fanx_Token.NULL_LITERAL     = 8;
fanx_Token.DOT              = 9;   //  .
fanx_Token.SEMICOLON        = 10;  //  ;
fanx_Token.COMMA            = 11;  //  ,
fanx_Token.COLON            = 12;  //  :
fanx_Token.DOUBLE_COLON     = 13;  //  ::
fanx_Token.LBRACE           = 14;  //  {
fanx_Token.RBRACE           = 15;  //  }
fanx_Token.LPAREN           = 16;  //  (
fanx_Token.RPAREN           = 17;  //  )
fanx_Token.LBRACKET         = 18;  //  [
fanx_Token.RBRACKET         = 19;  //  ]
fanx_Token.LRBRACKET        = 20;  //  []
fanx_Token.EQ               = 21;  //  =
fanx_Token.POUND            = 22;  //  #
fanx_Token.QUESTION         = 23;  //  ?
fanx_Token.AS               = 24;  //  as
fanx_Token.USING            = 25;  //  using

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

fanx_Token.isLiteral = function(type)
{
  return fanx_Token.BOOL_LITERAL <= type && type <= fanx_Token.NULL_LITERAL;
}

fanx_Token.toString = function(type)
{
  switch (type)
  {
    case fanx_Token.EOF:              return "end of file";
    case fanx_Token.ID:               return "identifier";
    case fanx_Token.BOOL_LITERAL:     return "Bool literal";
    case fanx_Token.STR_LITERAL:      return "String literal";
    case fanx_Token.INT_LITERAL:      return "Int literal";
    case fanx_Token.FLOAT_LITERAL:    return "Float literal";
    case fanx_Token.DECIMAL_LITERAL:  return "Decimal literal";
    case fanx_Token.DURATION_LITERAL: return "Duration literal";
    case fanx_Token.URI_LITERAL:      return "Uri literal";
    case fanx_Token.NULL_LITERAL:     return "null";
    case fanx_Token.DOT:              return ".";
    case fanx_Token.SEMICOLON:        return ";";
    case fanx_Token.COMMA:            return ",";
    case fanx_Token.COLON:            return ":";
    case fanx_Token.DOUBLE_COLON:     return "::";
    case fanx_Token.LBRACE:           return "{";
    case fanx_Token.RBRACE:           return "}";
    case fanx_Token.LPAREN:           return "(";
    case fanx_Token.RPAREN:           return ")";
    case fanx_Token.LBRACKET:         return "[";
    case fanx_Token.RBRACKET:         return "]";
    case fanx_Token.LRBRACKET:        return "[]";
    case fanx_Token.EQ:               return "=";
    case fanx_Token.POUND:            return "#";
    case fanx_Token.QUESTION:         return "?";
    case fanx_Token.AS:               return "as";
    case fanx_Token.USING:            return "using";
    default:                          return "Token[" + type + "]";
  }
}