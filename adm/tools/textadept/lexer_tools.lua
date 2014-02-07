--[[
Lexer tool snippets
===================
Copyright (c) 2013 Michael T. Richter
This program is free software. It comes without any warranty, to the extent
permitted by applicable law. You can redistribute it and/or modify it under
the terms of the Do What The Fuck You Want To Public License, Version 2, as
published by Sam Hocevar. Consult http://www.wtfpl.net/txt/copying for more
details.
 
Instructions
------------
Import the module (preferably with a short alias) along with the lexer library:
 
  l  = require 'lexer'
  lt = require 'lexer_tools'
 
Use the snippets you need:
 
  local some, ws = lt.some, lt.ws
  local whitespace = token(l.WHITESPACE, some(ws))
 
So why use this module instead of the LPeg primitives?  I find the more verbose
aliases a little easier to read in complicated expressions.
]]
 
M = {}
 
local l     = require 'lexer'
local any   = l.any
local space = l.space
 
local B, P, R, S = lpeg.B, lpeg.P, lpeg.R, lpeg.S
 
--[[
--  all_but()
--  ---------
--  all_but(pattern) matches one character iff pattern isn't present.
--]]
M.all_but = function(p)
              return any - p
            end
 
--[[
--  check_for()
--  ----------
--  check_for(pattern) matches pattern but does not consume it.
--]]
M.check_for = function(p)
                return #p
              end
 
--[[
--  maybe()
--  -------
--  maybe(pattern) matches at most one instance of pattern.
--]]
M.maybe = function(p)
            return p^-1
          end
 
--[[
--  maybe_some()
--  ------------
--  maybe_some(pattern) matches zero or more instances of pattern.
--]]
M.maybe_some = function(p)
                 return p^0
               end
 
--[[
--  some()
--  ------
--  some(pattern) matches one or more instances of pattern.
--]]
M.some = function(p)
           return p^1
         end
 
--[[
--  text_to()
--  ---------
--  text_to(pattern) matches all text up to but not including pattern.
--]]
M.text_to = function(p)
              return maybe_some(all_but(p))
            end
 
--[[
--  ws
--  --
--  Matches a space character.  Simply an alias for lexer.space.
--]]
M.ws = space
 
--[[
--  with_ws()
--  ---------
--  with_ws(pattern) matches iff pattern is followed by whitespace.  The
--  whitespace is not consumed.
--]]
M.with_ws = function(p)
              return p * #ws
            end
 
--[[
--  ws_with()
--  ---------
--  ws_with(pattern) matches iff pattern is preceeded by whitespace.  The
--  whitespace is not consumed.
--]]
M.ws_with = function(p)
              return B(ws) * p
            end
 
--[[
--  ws_with_ws()
--  ------------
--  ws_with_ws(pattern) matches iff pattern is both preceeded by whitespace and
--  followed by whitespace.  The whitespace is not consumed.
--]]
M.ws_with_ws = function(p)
                 return B(ws) * p * #ws
               end
 
return M