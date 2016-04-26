//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   25 Apr 15  Matthew Giannini  Creation
//

**
** Models an HTTP challenge/response authentication scheme as defined
** in [RFC7235]`https://tools.ietf.org/html/rfc7235`. Auth schemes have
** a case-insensitive name, and either
**   1. a single value, or
**   1. a a map of auth parameters that have case-insensitive keys.
**
@Js const class WebAuthScheme
{
	** Make an auth scheme with the given name and a map of auth-params.
	new makeParams(Str name, Str:Str params := [:])
	{
		this.name = name
		if (!params.caseInsensitive)
		{
			m := [Str:Str][:] { caseInsensitive = true }
			params.each |v, k| { m[k] = v }
			params = m
		}
		this.params = params.toImmutable
	}

	** Make an auth scheme with the given name and token68 value.
	new makeToken68(Str name, Str tok68)
	{
		this.name  = name
		if (!AuthParser.isToken68(tok68)) throw ArgErr("Not a token68: '${tok68}'")
		this.tok68 = tok68
	}

	WebAuthScheme addParams(Str:Str params)
	{
		WebAuthScheme(name, this.params.dup.addAll(params))
	}

	** Case-insensitive check to see if scheme matches name
	Bool isScheme(Str name)
	{
		this.name.lower == name.lower
	}

	** True if the auth scheme is using the 'token68' syntax.
	Bool isToken68() { tok68 != null}

	** Get a value from the auth-params, or return the 'defVal'.
	@Operator
	Str? get(Str param, Str? defVal := null)
	{
		params[param] ?: defVal
	}

	** Encode the auth scheme for use as a header value.
	override Str toStr()
	{
		buf := StrBuf()
		buf.add(name)
		if (isToken68) buf.add(" ${tok68}")
		else if (!params.isEmpty) buf.add(" ${encodeParams(params)}")
		return buf.toStr
	}

	@NoDoc static Str encodeParams(Str:Str params)
	{
		buf := StrBuf()
		i := 0
		params.each |v, k| {
			if (i > 0) buf.add(", ")
			buf.add(k).add("=").add(WebUtil.toQuotedStr(v))
			++i
		}
		return buf.toStr
	}

	** The auth scheme name
	const Str name

	** The auth params for this scheme.
	const Str:Str params := [:]

	** The token68 value of this scheme.
	const Str? tok68 := null
}

**
** AuthParser
**
@NoDoc @Js internal class AuthParser
{
	new make(Str val)
	{
		this.buf = val
		reset(0)
	}

	Str:Str authParams()
	{
		params := parseAuthParams
		if (!eof) throw ParseErr("Invalid auth param list: ${buf}")
		return params
	}

	WebAuthScheme? nextScheme()
	{
		if (eof) return null
		if (pos > 0) commaOws

		name := parseToken([SP, COMMA, EOF])
		if (cur != SP) return WebAuthScheme(name)

		while (cur == SP) consume

		start  := pos
		tok68  := parseToken68([COMMA, EOF])
		if (tok68 != null) return WebAuthScheme(name, tok68)

		reset(start)
		params := parseAuthParams
		if (params.isEmpty) throw ParseErr("Expected token68 or #auth-param at pos ${pos}: '${buf}'")
		return WebAuthScheme(name, params)
	}

//////////////////////////////////////////////////////////////////////////
// Parsing
//////////////////////////////////////////////////////////////////////////

	** Parse auth params until we don't find any more. Does not necessarily
	** consume the entire buf.
	private Str:Str parseAuthParams()
	{
		params := Str:Str[:] { caseInsensitive = true }
		while (true)
		{
			start := pos
			if (eof) break
			if (params.size > 0) commaOws
			if (!parseAuthParam(params)) { reset(start); break }
			ows
		}
		return params
	}

	** Parse a single auth param.
	private Bool parseAuthParam(Str:Str params)
	{
		if (eof) return false

		start := pos
		key := parseToken([SP, HTAB, EQ, COMMA, EOF])
		ows
		if (cur != EQ)
		{
			// backtrack
			reset(start)
			return false
		}
		consume
		ows
		val := cur == DQUOT ? parseQuotedString : parseToken([SP, HTAB, COMMA, EOF])
		ows
		params[key] = val
		return true
	}

	private Str? parseToken68(Int[] terms)
	{
		tok := parseUntil(terms)
		return isToken68(tok) ? tok : null
	}

	static Bool isToken68(Str s)
	{
		if (s.isEmpty) return false
		eq := false
		return s.all |Int c, Int i->Bool| {
			// after first '=', everything must be '='
			if (c == EQ && i > 0) eq = true
			if (eq) return c == EQ
			return c.isAlpha || c.isDigit || Tok68Special.containsChar(c)
		}
	}
	private static const Str Tok68Special := "-._~+/"

	private Str parseToken(Int[] terms)
	{
		verifyToken(parseUntil(terms))
	}

	private Str parseUntil(Int[] terms)
	{
		start := pos
		while(true)
		{
			if (eof)
			{
				if (terms.contains(EOF)) break
				throw ParseErr("Unexpected <eof>: $buf")
			}
			if (terms.contains(cur)) break
			consume
		}
		return buf[start..<pos]
	}

	private Void ows()
	{
		while (isOWS) consume
	}

	private Bool isOWS()
	{
		cur == SP || cur == HTAB
	}

	private Str parseQuotedString()
	{
		start := pos
		if (cur != DQUOT) throw ParseErr("Expected '$DQUOT' at pos ${pos}")
		consume
		while (true)
		{
			if (eof) throw ParseErr("Unterminated quoted-string starting at ${pos}")
			if (cur == DQUOT) { consume; break }
			if (cur == ESC && peek == DQUOT) { consume; consume }
			else consume
		}
		return WebUtil.fromQuotedStr(buf[start..<pos])
	}

	private Str verifyToken(Str tok)
	{
		if (!WebUtil.isToken(tok)) throw ParseErr("Expected token, not '$tok'")
		return tok
	}

	private Void commaOws()
	{
		if (cur != COMMA) throw ParseErr("Expected ',': ${buf[0..pos]}")
		consume
		ows
	}

	Bool eof() { cur == EOF }

//////////////////////////////////////////////////////////////////////////
// Consume
//////////////////////////////////////////////////////////////////////////

	private Void consume()
	{
		cur = peek
		++pos
		if (pos+1 < buf.size)
			peek = buf[pos+1]
		else
			peek = EOF
	}

	private Void reset(Int pos)
	{
		this.pos = pos - 2
		consume
		consume
	}

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

	private const static Int SP    := ' '
	private const static Int HTAB  := '\t'
	private const static Int EQ    := '='
	private const static Int COMMA := ','
	private const static Int DQUOT := '"'
	private const static Int ESC   := '\\'
	private const static Int EOF   := -1

	private const Str buf
	private Int pos  := -2
	private Int cur  := EOF
	private Int peek := EOF
}
