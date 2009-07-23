//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//    3 Sep 05  Brian Frank  Creation for Fan compiler
//   17 Aug 07  Brian        Rework for serialization parser
//
package fanx.serial;

/**
 * Token defines the token type constants and provides
 * associated utility methods.
 */
public class Token
{

//////////////////////////////////////////////////////////////////////////
// Token Type Ids
//////////////////////////////////////////////////////////////////////////

  public static final int EOF              = -1;
  public static final int ID               = 0;
  public static final int BOOL_LITERAL     = 1;
  public static final int STR_LITERAL      = 2;
  public static final int INT_LITERAL      = 3;
  public static final int FLOAT_LITERAL    = 4;
  public static final int DECIMAL_LITERAL  = 5;
  public static final int DURATION_LITERAL = 6;
  public static final int URI_LITERAL      = 7;
  public static final int NULL_LITERAL     = 8;
  public static final int DOT              = 9;   //  .
  public static final int SEMICOLON        = 10;  //  ;
  public static final int COMMA            = 11;  //  ,
  public static final int COLON            = 12;  //  :
  public static final int DOUBLE_COLON     = 13;  //  ::
  public static final int LBRACE           = 14;  //  {
  public static final int RBRACE           = 15;  //  }
  public static final int LPAREN           = 16;  //  (
  public static final int RPAREN           = 17;  //  )
  public static final int LBRACKET         = 18;  //  [
  public static final int RBRACKET         = 19;  //  ]
  public static final int LRBRACKET        = 20;  //  []
  public static final int EQ               = 21;  //  =
  public static final int POUND            = 22;  //  #
  public static final int QUESTION         = 23;  //  ?
  public static final int AT               = 24;  //  @
  public static final int AS               = 25;  //  as
  public static final int USING            = 26;  //  using

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  public static boolean isLiteral(int type)
  {
    return BOOL_LITERAL <= type && type <= NULL_LITERAL;
  }

  public static String keyword(int type)
  {
    if (AS <= type && type <= USING)
      return toString(type);
    else
      return null;
  }

  public static String toString(int type)
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