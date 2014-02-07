--[[
Fantom lexer
=============
Copyright (c) 2013 Michael T. Richter
This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under
the terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. Consult http://www.wtfpl.net/txt/copying for more
details.
]]
 
local l                 = lexer
local token, word_match = l.token, l.word_match
 
local lt         = require 'lexer_tools'
local all_but    = lt.all_but
local check_for  = lt.check_for
local maybe      = lt.maybe
local maybe_some = lt.maybe_some
local some       = lt.some
local ws         = lt.ws
 
local P, R, S = lpeg.P, lpeg.R, lpeg.S
 
local M = { _NAME = 'fantom' }
 
-- Whitespace.
local whitespace = token(l.WHITESPACE, some(ws))
 
-- Comments.
local line_comment  = '//' * maybe_some(l.nonnewline)
local doc_comment   = '**' * maybe_some(l.nonnewline)
local block_comment = '/*' * maybe_some(all_but '*/') * maybe(P'*/')
local comment       = token(l.COMMENT, line_comment
                                     + doc_comment
                                     + block_comment)
-- Keywords
local keyword = token(l.KEYWORD, word_match {
  'class', 'true', 'false', 'if', 'else', 'while', 'continue', 'break', 'for',
  'switch', 'case', 'default', 'try', 'catch', 'throw', 'finally', 'null',
  'return', 'mixin', 'facet', 'enum', 'abstract', 'final', 'const', 'native',
  'public', 'protected', 'private', 'internal', 'static', 'this', 'super',
  'override', 'readonly', 'virtual', 'set', 'final', 'is', 'isnot', 'as', })
 
-- Standard library pod references
local pod_ref = token(l.CLASS, word_match {
  'build', 'compiler', 'compilerDoc', 'compilerJava', 'compilerJs',
  'concurrent', 'dom', 'email', 'fandoc', 'fanr', 'fansh', 'flux', 'fluxText',
  'fwt', 'gfx', 'inet', 'obix', 'sql', 'syntax', 'sys', 'util', 'web', 'webfwt',
  'webmod', 'wisp', 'xml', })
 
-- Function invocation
local func = token(l.FUNCTION, some(l.word) * check_for(P'('))
 
-- Operators
local operator = token(l.OPERATOR, S('+-*/%=!<>.?&|:~^{}[]'))
 
-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)
 
-- Strings.
local uri_str = l.delimited_range("`",    true,  true)
local dq_str  = l.delimited_range('"',    false, false)
local tdq_str = l.delimited_range('"""',  false, true)
local dsl_str = '<|' * maybe_some(all_but '|>') * maybe(P'|>')
local string = token(l.STRING, uri_str
                             + dq_str
                             + tdq_str
                             + dsl_str)
 
-- Standard types
local type = token(l.TYPE, word_match {
    -- Facets
  'Facet', 'Service',
  -- Classes
  'Bool', 'Buf', 'Charset', 'Date', 'DateTime', 'Decimal', 'Depend', 'Duration',
  'Enum', 'Env', 'Err', 'Field', 'File', 'Float', 'Func', 'InStream', 'Int',
  'List', 'Locale', 'Log', 'LogRec', 'Map', 'Method', 'MimeType', 'Num', 'Obj',
  'OutStream', 'Param', 'Pod', 'Process', 'Range', 'Regex', 'RegexMatcher',
  'Slot', 'Str', 'StrBuf', 'Test', 'This', 'Time', 'TimeZone', 'Type', 'Unit',
  'Unsafe', 'Uri', 'UriScheme', 'Uuid', 'Version', 'Void', 'Zip',
  -- Enums
  'Endian', 'LogLevel', 'Month', 'Weekday',
  -- Facets
  'Deprecated', 'FacetMeta', 'Js', 'NoDoc', 'Operator', 'Serializable',
  'Transient', })
 
local error = token(l.ERROR, word_match {
  -- Errs
  'ArgErr', 'CanceledErr', 'CastErr', 'ConstErr', 'FieldNotSetErr', 'IOErr',
  'IndexErr', 'InterruptedErr', 'NameErr', 'NotImmutableErr', 'NullErr',
  'ParseErr', 'ReadonlyErr', 'TimeoutErr', 'UnknownFacetErr', 'UnknownKeyErr',
  'UnknownPodErr', 'UnknownServiceErr', 'UnknownSlotErr', 'UnknownTypeErr',
  'UnresolvedErr', 'UnsupportedErr', })
 
-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)
 
M._rules = {
  { 'whitespace',  whitespace },
  { 'comment',     comment    },
  { 'keyword',     keyword    },
  { 'type',        type       },
  { 'error',       error      },
  { 'library pod', pod_ref    },
  { 'function',    func       },
  { 'string',      string     },
  { 'operator',    operator   },
  { 'identifier',  identifier },
  { 'number',      number     }, }
 
M._tokenstyles = { }
 
M._foldsymbols = {
  _patterns    = {'[{}]', '/%*', '%*/', '//', '**', },
  [l.OPERATOR] = {
    ['{'] = 1,
    ['}'] = -1
  },
  [l.COMMENT] = {
    ['/*'] = 1,
    ['*/'] = -1,
    ['**'] = l.fold_line_comments('**'),
    ['//'] = l.fold_line_comments('//'),
  },
  [l.STRING] = {
    ['<|'] = 1,
    ['|>'] = -1
  },
}
 
return M