//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Brian Frank  Creation
//

#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "props.h"

//////////////////////////////////////////////////////////////////////////
// Char Stream
//////////////////////////////////////////////////////////////////////////

// push back for read
int unread = 0;

/**
 * Read next character from stream or return EOF
 */
int readChar(FILE* fp)
{
  if (unread != 0)
  {
    int c = unread;
    unread = 0;
    return c;
  }
  else
  {
    return fgetc(fp);
  }
}

/**
 * Pushback a character to reuse for next readChar()
 */
void unreadChar(int ch)
{
  assert(unread == 0);
  unread = ch;
}

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

/**
 * Convert a hexadecimal digit char into its numeric
 * value or return -1 on error.
 */
int hex(int c)
{
  if ('0' <= c && c <= '9') return c - '0';
  if ('a' <= c && c <= 'f') return c - 'a' + 10;
  if ('A' <= c && c <= 'F') return c - 'A' + 10;
  return -1;
}

/**
 * Return if specified character is whitespace.
 */
bool isSpace(int c)
{
  return c == ' ' || c == '\t';
}

/**
 * Given a pointer to a string of characters, trim the leading
 * and trailing whitespace and return a copy of the string from
 * heap memory.
 */
char* makeTrimCopy(char* s, int num)
{
  // trim leading/trailing whitespace
  int start = 0;
  int end = num;
  while (start < end) if (isSpace(s[start])) start++; else break;
  while (end > start) if (isSpace(s[end-1])) end--; else break;
  s[end] = '\0';
  s = s+start;

  // make copy on heap
  char* copy = new char[end-start+1];
  strcpy(copy, s);
  return copy;
}

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

/**
 * Parse the specified props file according to the file format
 * specified by sys::InStream - this is pretty much a C port of
 * the Java implementation.  Return a linked list of Props or if
 * error, then print error to stdout and return NULL.
 */
Prop* readProps(const char* filename)
{
  char name[512];
  char val[4096];
  int nameNum = 0, valNum = 0;
  bool inVal = false;
  int inBlockComment = 0;
  bool inEndOfLineComment = false;
  int c = -1, last = -1;
  int lineNum = 1;
  FILE* fp;
  Prop* head = NULL;
  Prop* tail = NULL;

  fp = fopen(filename, "r");
  if (fp == NULL)
  {
    printf("File not found [%s]\n", filename);
    return NULL;
  }

  for (;;)
  {
    last = c;
    c = readChar(fp);
    if (c == EOF) break;

    // end of line
    if (c == '\n' || c == '\r')
    {
      inEndOfLineComment = false;
      if (last == '\r' && c == '\n') continue;
      char* n = makeTrimCopy(name, nameNum);
      if (inVal)
      {
        char* v = makeTrimCopy(val, valNum);

        Prop* p = new Prop();
        p->name = n;
        p->val = v;
        p->next = NULL;
        if (head == NULL) { head = tail = p; }
        else { tail->next = p; tail = p; }

        inVal = false;
        nameNum = valNum = 0;
      }
      else if (strlen(n) > 0)
      {
        printf("Invalid name/value pair [%s:%d]\n", filename, lineNum);
        return NULL;
      }
      lineNum++;
      continue;
    }

    // if in comment
    if (inEndOfLineComment) continue;

    // block comment
    if (inBlockComment > 0)
    {
      if (last == '/' && c == '*') inBlockComment++;
      if (last == '*' && c == '/') inBlockComment--;
      continue;
    }

    // equal
    if (c == '=' && !inVal)
    {
      inVal = true;
      continue;
    }

    // comment
    if (c == '/')
    {
      int peek = readChar(fp);
      if (peek < 0) break;
      if (peek == '/') { inEndOfLineComment = true; continue; }
      if (peek == '*') { inBlockComment++; continue; }
      unreadChar(peek);
    }

    // escape or line continuation
    if (c == '\\')
    {
      int peek = readChar(fp);
      if (peek < 0) break;
      else if (peek == 'n')  c = '\n';
      else if (peek == 'r')  c = '\r';
      else if (peek == 't')  c = '\t';
      else if (peek == '\\') c = '\\';
      else if (peek == '\r' || peek == '\n')
      {
        // line continuation
        lineNum++;
        if (peek == '\r')
        {
          peek = readChar(fp);
          if (peek != '\n') unreadChar(peek);
        }
        while (true)
        {
          peek = readChar(fp);
          if (peek == ' ' || peek == '\t') continue;
          unreadChar(peek);
          break;
        }
        continue;
      }
      else if (peek == 'u')
      {
        int n3 = hex(readChar(fp));
        int n2 = hex(readChar(fp));
        int n1 = hex(readChar(fp));
        int n0 = hex(readChar(fp));
        if (n3 < 0 || n2 < 0 || n1 < 0 || n0 < 0)
        {
          printf("Invalid hex value for \\uxxxx [%s:%d]\n", filename, lineNum);
          return NULL;
        }
        c = ((n3 << 12) | (n2 << 8) | (n1 << 4) | n0);
      }
      else
      {
        printf("Invalid escape sequence [%s:%d]\n", filename, lineNum);
        return NULL;
      }
    }

    // normal character
    if (inVal)
    {
      if (valNum+1 < sizeof(val)) val[valNum++] = c;
    }
    else
    {
      if (nameNum+1 < sizeof(name)) name[nameNum++] = c;
    }
  }

  char* n = makeTrimCopy(name, nameNum);
  if (inVal)
  {
    char* v = makeTrimCopy(val, valNum);

    Prop* p = new Prop();
    p->name = n;
    p->val = v;
    p->next = NULL;
    if (head == NULL) { head = tail = p; }
    else { tail->next = p; tail = p; }
  }
  else if (strlen(n) > 0)
  {
    printf("Invalid name/value pair [%s:%d]\n", filename, lineNum);
    return NULL;
  }

  return head;
}

//////////////////////////////////////////////////////////////////////////
// Get
//////////////////////////////////////////////////////////////////////////

/**
 * Get a property from the linked list or return NULL if not found.
 */
const char* getProp(Prop* props, const char* name) { return getProp(props, name, NULL); }

/**
 * Get a property from the linked list or return def if not found.
 */
const char* getProp(Prop* props, const char* name, const char* def)
{
  for (Prop* p = props; p != NULL; p = p->next)
    if (strcmp(p->name, name) == 0)
      return p->val;
  return def;
}

//////////////////////////////////////////////////////////////////////////
// Set
//////////////////////////////////////////////////////////////////////////

/**
 * Set a property in the linked list or add it if not found.
 */
Prop* setProp(Prop* props, const char* name, const char* value)
{
  Prop* last = NULL;
  for (Prop* p = props; p != NULL; p = p->next)
  {
    if (strcmp(p->name, name) == 0)
    {
      p->val = value;
      return props;
    }
    last = p;
  }

  Prop* p = new Prop();
  p->name = name;
  p->val  = value;
  p->next = NULL;

  if (last == NULL) props = p;
  else last->next = p;
  return props;
}

