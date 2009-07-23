//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Sep 07  Andy Frank  Creation
//

namespace Fanx.Serial
{
  /// <summary>
  /// Token defines the token type constants and provides
  /// associated utility methods.
  /// </summary>
  public class Token
  {

  //////////////////////////////////////////////////////////////////////////
  // Token Type Ids
  //////////////////////////////////////////////////////////////////////////

    public const int EOF              = -1;
    public const int ID               = 0;
    public const int BOOL_LITERAL     = 1;
    public const int STR_LITERAL      = 2;
    public const int INT_LITERAL      = 3;
    public const int FLOAT_LITERAL    = 4;
    public const int DECIMAL_LITERAL  = 5;
    public const int DURATION_LITERAL = 6;
    public const int URI_LITERAL      = 7;
    public const int NULL_LITERAL     = 8;
    public const int DOT              = 9;   //  .
    public const int SEMICOLON        = 10;  //  ;
    public const int COMMA            = 11;  //  ,
    public const int COLON            = 12;  //  :
    public const int DOUBLE_COLON     = 13;  //  ::
    public const int LBRACE           = 14;  //  {
    public const int RBRACE           = 15;  //  }
    public const int LPAREN           = 16;  //  (
    public const int RPAREN           = 17;  //  )
    public const int LBRACKET         = 18;  //  [
    public const int RBRACKET         = 19;  //  ]
    public const int LRBRACKET        = 20;  //  []
    public const int EQ               = 21;  //  =
    public const int POUND            = 22;  //  #
    public const int QUESTION         = 23;  //  ?
    public const int AT               = 24;  //  @
    public const int AS               = 25;  //  as
    public const int USING            = 26;  //  using

  //////////////////////////////////////////////////////////////////////////
  // Utils
  //////////////////////////////////////////////////////////////////////////

    public static bool isLiteral(int type)
    {
      return BOOL_LITERAL <= type && type <= NULL_LITERAL;
    }

    public static string keyword(int type)
    {
      if (AS <= type && type <= USING)
        return toString(type);
      else
        return null;
    }

    public static string toString(int type)
    {
      switch (type)
      {
        case EOF:              return "end of file";
        case ID:               return "identifier";
        case BOOL_LITERAL:     return "Bool literal";
        case STR_LITERAL:      return "String literal";
        case INT_LITERAL:      return "Int literal";
        case FLOAT_LITERAL:    return "Float literal";
        case DECIMAL_LITERAL:  return "Decimal literal";
        case DURATION_LITERAL: return "Duration literal";
        case URI_LITERAL:      return "Uri literal";
        case NULL_LITERAL:     return "null";
        case DOT:              return ".";
        case SEMICOLON:        return ";";
        case COMMA:            return ",";
        case COLON:            return ":";
        case DOUBLE_COLON:     return "::";
        case LBRACE:           return "{";
        case RBRACE:           return "}";
        case LPAREN:           return "(";
        case RPAREN:           return ")";
        case LBRACKET:         return "[";
        case RBRACKET:         return "]";
        case LRBRACKET:        return "[]";
        case EQ:               return "=";
        case POUND:            return "#";
        case QUESTION:         return "?";
        case AT:               return "@";
        case AS:               return "as";
        case USING:            return "using";
        default:               return "Token[" + type + "]";
      }
    }

  }
}