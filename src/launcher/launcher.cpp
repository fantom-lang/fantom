//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Brian Frank  Creation
//

#include <stdio.h>
#include <Windows.h>
#include "launcher.h"
#include "java.h"
#include "dotnet.h"
#include "utils.h"

#ifndef FAN_TOOL
#error "Must defined FAN_TOOL to be Fan, Fant, Fanp, etc"
#endif

//////////////////////////////////////////////////////////////////////////
// TypeDefs
//////////////////////////////////////////////////////////////////////////

typedef enum { JavaRuntime, DotnetRuntime } Runtime;

//////////////////////////////////////////////////////////////////////////
// Globals
//////////////////////////////////////////////////////////////////////////

const char* LAUNCHER_VERSION = "1.0.50 2-Feb-10";

bool debug;                  // is debug turned on
char fanHome[MAX_PATH];      // dir path of fan installation
Prop* sysProps;              // {fanHome}\etc\sys\config.props
int fanArgc;                 // argument count to pass to Fan runtime
char** fanArgv;              // argument values to pass to Fan runtime
Runtime runtime;             // runtime to use
char* cmdLineRuntime = NULL; // runtime specified on cmd line


//////////////////////////////////////////////////////////////////////////
// Init
//////////////////////////////////////////////////////////////////////////

/**
 * Initialize the global variables for this process's environment.
 */
int init(int argc, char** argv)
{
  // debug controlled by environment variable or --v argument
  debug = getenv("fan_launcher_debug") != NULL;
  for (int i=1; i<argc; ++i) if (strcmp(argv[i], "--v") == 0) debug = true;
  if (debug)
  {
    printf("-- launcher version %s\n", LAUNCHER_VERSION);
    for (int i=0; i<argc; ++i)
      printf("--   args[%d] = \"%s\"\n", i, argv[i]);
    printf("-- init\n");
  }

  // get my module
  char p[MAX_PATH];
  if (!GetModuleFileName(NULL, p, MAX_PATH))
    return err("GetModuleFileName");

  // walk up two levels of the path to get fan home:
  //   {fanHome}\bin\me.exe
  int len = strlen(p);
  for (; len > 0; len--) if (p[len] == '\\') { p[len] = '\0'; break; }
  for (; len > 0; len--) if (p[len] == '\\') { p[len] = '\0'; break; }
  strcpy(fanHome, p);
  if (debug) printf("--   fanHome = %s\n", fanHome);

  // parse etc/sys/config.props
  sprintf(p, "%s\\etc\\sys\\config.props", fanHome);
  sysProps = readProps(p);
  if (sysProps == NULL)
    printf("WARN: Cannot read config.props: \"%s\"", p);

  // debug props
  if (debug)
  {
    printf("--   config.props:\n");
    for (Prop* p = sysProps; p != NULL; p = p->next)
      printf("--     %s=%s\n", p->name, p->val);
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Parse Arguments
//////////////////////////////////////////////////////////////////////////

/**
 * Parse arguments to initialize fanArgc and fanArgv, plus check for
 * arguments used by the launcher itself (prefixed via --).  Note that
 * the --v debug is handled in init(), not this method.
 */
int parseArgs(int argc, char** argv)
{
  if (debug) printf("-- parseArgs\n");

  fanArgc = 0;
  fanArgv = new char*[argc];

#ifdef FAN_MAIN
  fanArgv[fanArgc++] = FAN_MAIN;
#endif

  for (int i=1; i<argc; ++i)
  {
    char* arg = argv[i];
    int len = strlen(arg);

    // if arg starts with --
    if (len >= 3 && arg[0] == '-' && arg[1] == '-')
    {
      // --v (already handled in init)
      if (strcmp(arg, "--v") == 0)
      {
        continue;
      }

      // --Dname=value
      else if (arg[2] == 'D')
      {
        char* temp = new char[len];
        strcpy(temp, arg+3);
        char* name = strtok(temp, "=");
        char* val  = strtok(NULL, "=");
        if (val != NULL)
        {
          sysProps = setProp(sysProps, name, val);
          if (debug) printf("--   override prop %s=%s\n", name, val);
          if (strcmp(name, "runtime") == 0) cmdLineRuntime = val;
        }
        continue;
      }
    }

    // pass thru to fan
    fanArgv[fanArgc++] = arg;
  }

  if (debug)
  {
    printf("--   fanArgs (%d)\n", fanArgc);
    for (int i=0; i<fanArgc; ++i)
      printf("--     [%d] %s\n", i, fanArgv[i]);
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Check for Substitute
//////////////////////////////////////////////////////////////////////////

/**
 * Check the "runtime.substitutes" sys property which is used
 * to specify an alternate Fan runtime to use for specific script
 * files - this is a bit of a hack so that we can cleanly manage
 * a "boot build" of the fan runtime with another fan runtime.  The
 * format of the "runtime.substitutes" prop is a list of
 * <scriptUri> "=" <runtimeUri> pairs separated by whitespace.  The
 * scriptUri identifies a file on the local machine in URI format
 * of a Fan script file.  The runtimeUri identifies the Fan home
 * directory of a Fan runtime installation.
 */
int checkSubstitutes()
{
  // we don't check for substitutes except when running the Fan
  // interpreter and we have at least one argument (which we
  // assume to be the target script being run)
  if (strcmp(FAN_TOOL, "Fan") != 0 || fanArgc < 1)
    return 0;
  const char* target = fanArgv[0];

  // check for system prop
  const char* prop = getProp(sysProps, "runtime.substitutes");
  if (prop == NULL) return 0;

  if (debug) printf("-- checkSubstitutes\n");

  // get the full path of the script as a Fan URI
  char targetUri[MAX_PATH];
  targetUri[0] = '/';
  if (GetFullPathName(target, sizeof(targetUri)-1, targetUri+1, NULL) == 0)
    return 0;
  for (int i=1; targetUri[i] != '\0'; ++i)
    if (targetUri[i] == '\\') targetUri[i] = '/';
  if (debug) printf("--   targetUri = %s\n", targetUri);

  // make copy of value on heap
  char* copy = new char[strlen(prop)+1];
  strcpy(copy, prop);

  // tokenize
  char* scriptUri  = strtok(copy, " ");
  char* eq         = strtok(NULL, " ");
  char* runtimeUri = strtok(NULL, " ");
  while (scriptUri != NULL && eq != NULL && runtimeUri != NULL)
  {
    if (debug) printf("--     %s = %s\n", scriptUri, runtimeUri);

    // sanity check
    if (strcmp(eq, "=") != 0)
    {
      err("Invalid format for sys prop \"runtime.substitutes\"\n");
      break;
    }

    // if we found a match update fan.home and break
    if (_stricmp(targetUri, scriptUri) == 0)
    {
      strcpy(fanHome, runtimeUri);
      if (debug) printf("--   substitute fan.home = %s\n", fanHome);
      break;
    }

    // move on to next token triple
    scriptUri  = strtok(NULL, " ");
    eq         = strtok(NULL, " ");
    runtimeUri = strtok(NULL, " ");
  }

  delete [] copy;
  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Get Runtime
//////////////////////////////////////////////////////////////////////////

/**
 * Set the runtime variable with the runtime to use.
 */
int getRuntime()
{
  const char* rt = getProp(sysProps, "runtime", "java");

  if (getenv("fan_runtime") != NULL)
    rt = getenv("fan_runtime");

  if (cmdLineRuntime != NULL)
    rt = cmdLineRuntime;

  if (debug) printf("-- getRuntime = %s\n", rt);

  if (strcmp(rt, "java") == 0) runtime = JavaRuntime;
  else if (strcmp(rt, "dotnet") == 0) runtime = DotnetRuntime;
  else return err("Unknown runtime %s", rt);

  // force stub apps to always use the right runtime
  if (strcmp(FAN_TOOL, "Jstub") == 0) runtime = JavaRuntime;
  else if (strcmp(FAN_TOOL, "Nstub") == 0) runtime = DotnetRuntime;

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

int main(int argc, char** argv)
{
  if (init(argc, argv)) return -1;
  if (parseArgs(argc, argv)) return -1;
  if (checkSubstitutes()) return -1;
  if (getRuntime()) return -1;
  switch (runtime)
  {
    case JavaRuntime:   return runJava();
    case DotnetRuntime: return runDotnet();
    default:          return err("internal error in main");
  }
  return 0;
}