//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   27 Dec 06  Brian Frank  Creation
//

#include <stdio.h>
#include <Windows.h>
#include <jni.h>
#include "props.h"
#include "launcher.h"
#include "utils.h"

//////////////////////////////////////////////////////////////////////////
// TypeDefs
//////////////////////////////////////////////////////////////////////////

typedef jint (JNICALL *CreateJavaVMFunc)(JavaVM **pvm, void **penv, void *vm_args);

//////////////////////////////////////////////////////////////////////////
// Globals
//////////////////////////////////////////////////////////////////////////

const int MAX_OPTIONS = 32;        // max number of Java options
JavaVMOption options[MAX_OPTIONS]; // Java options to pass to create VM
char jvmPath[MAX_PATH];            // path to jvm.dll to dynamically load
int nOptions;                      // Number of options
JavaVM* vm;                        // VM created
JNIEnv* env;                       // JNI environment

//////////////////////////////////////////////////////////////////////////
// Init Java VM
//////////////////////////////////////////////////////////////////////////

/**
 * Find the jvm.dll path to use by querying the registry.
 */
int findJvmPath()
{
  if (debug) printf("-- findJvmPath\n");

  // first see if explicitly specified in config.props
  const char* prop = getProp(sysProps, "java.jvm");
  if (prop != NULL)
  {
    if (debug) printf("--   java.jvm = %s\n", prop);
    sprintf(jvmPath, prop);
    return 0;
  }

  // query registry to get current Java version
  const char* jreKey = "SOFTWARE\\JavaSoft\\Java Runtime Environment";
  char curVer[MAX_PATH];
  if (readRegistry(jreKey, "CurrentVersion", curVer, sizeof(curVer))) return -1;
  if (debug) printf("--   registry query: CurrentVersion = %s\n", curVer);

  // use curVer to get default jvm.dll to use
  char jvmKey[MAX_PATH];
  sprintf(jvmKey, "%s\\%s", jreKey, curVer);
  if (readRegistry(jvmKey, "RuntimeLib", jvmPath, sizeof(jvmPath))) return -1;
  if (debug) printf("--   registry query: RuntimeLib = %s\n", jvmPath);

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Init Options
//////////////////////////////////////////////////////////////////////////

/**
 * Get the full list of options to pass to the Java VM which
 * are the required options set by the launcher, plus any additional
 * options configured in etc/sys/config.props.
 */
int initOptions()
{
  if (debug) printf("-- initOptions\n");

  // predefined classpath, include every jar file
  // found in lib/java/ext/win and lib/java/ext/win
  static char optClassPath[MAX_PATH*10];
  sprintf(optClassPath, "-Djava.class.path=%s\\lib\\java\\sys.jar", fanHome);
  options[nOptions++].optionString = optClassPath;

  // predefined fan.home
  static char optHome[MAX_PATH];
  sprintf(optHome, "-Dfan.home=%s", fanHome);
  options[nOptions++].optionString = optHome;

  // user specified options from config.props
  const char* prop = getProp(sysProps, "java.options", "");
  char* copy = new char[strlen(prop)+1];
  strcpy(copy, prop);
  char* tok = strtok(copy, " ");
  while (tok != NULL)
  {
    if (nOptions >= MAX_OPTIONS) break;
    options[nOptions++].optionString = tok;
    tok = strtok(NULL, " ");
  }

  // debug
  if (debug)
  {
    printf("--   options:\n");
    for (int i=0; i<nOptions; ++i)
      printf("--     %s\n", options[i].optionString);
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Load Java
//////////////////////////////////////////////////////////////////////////

/**
 * Load the Java VM.
 */
int loadJava()
{
  if (debug) printf("-- loadJava\n");

  // dynamically load jvm.dll
  if (debug) printf("--   load %s...\n", jvmPath);
  HINSTANCE dll = LoadLibrary(jvmPath);
  if (dll == NULL)
    return err("Cannot load library: %s", jvmPath);

  // query for create VM procedure
  if (debug) printf("--   query procedure...\n");
  CreateJavaVMFunc createVM = (CreateJavaVMFunc)GetProcAddress(dll, "JNI_CreateJavaVM");
  if (createVM == NULL)
    return err("Cannot find JNI_CreateJavaVM in %s", jvmPath);

  // setup args
  JavaVMInitArgs vm_args;
  vm_args.version = JNI_VERSION_1_2;
  vm_args.options = options;
  vm_args.nOptions = nOptions;
  vm_args.ignoreUnrecognized = TRUE;

  // create vm
  if (debug) printf("--   create java vm...\n");
  if (createVM(&vm, (void**)&env, &vm_args) < 0)
    return err("Cannot launch Java VM");

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Check Version
//////////////////////////////////////////////////////////////////////////

/**
 * Find and invoke the Java Fan runtime main.
 */
int checkVersion()
{
  if (debug) printf("-- checkVersion...\n");

  // query for the java.version
  jclass sysClass = env->FindClass("java/lang/System");
  jmethodID getProp = env->GetStaticMethodID(sysClass, "getProperty", "(Ljava/lang/String;)Ljava/lang/String;");
  jstring key = env->NewStringUTF("java.version");
  jstring jver = (jstring)env->CallStaticObjectMethod(sysClass, getProp, key);
  if (jver == NULL)
    return err("Cannot query java.version system property");
  const char* ver = env->GetStringUTFChars(jver, NULL);
  if (debug) printf("--   java.version = %s\n", ver);

  // parse major, minor
  const char* p = ver;
  int major = 0, minor = 0;
  while (*p != '.' && *p != '\0') { major = major*10 + (*p-'0'); p++; }
  p++;
  while (*p != '.' && *p != '\0') { minor = minor*10 + (*p-'0'); p++; }
  if (debug) printf("--   parsed = %d.%d\n", major, minor);

  // check that we are running 1.5
  if (major < 1 || minor < 5)
    return err("Fan requires Java 1.5 or greater (you have %s)", ver);
  if (debug) printf("--   version check ok\n");

  // cleanup
  env->ReleaseStringUTFChars(key, NULL);
  env->ReleaseStringUTFChars(jver, ver);

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Load Java
//////////////////////////////////////////////////////////////////////////

/**
 * Find and invoke the Java Fan runtime main.
 */
int runJavaMain()
{
  if (debug) printf("-- runJavaMain...\n");

  // figure out main
  char temp[256];
  sprintf(temp, "fanx/tools/%s", FAN_TOOL);
  const char* mainClassName = (const char*)temp;

  // find the main class
  if (debug) printf("--   find class %s...\n", mainClassName);
  jclass mainClass = env->FindClass(mainClassName);
  if (mainClass == NULL)
    return err("Cannot find Java main %s", mainClassName);

  // find the main method
  if (debug) printf("--   find method %s.main(String[])...\n", mainClassName);
  jmethodID mainMethod = env->GetStaticMethodID(mainClass, "main", "([Ljava/lang/String;)V");
  if (mainMethod == NULL)
    return err("Cannot find %s.main(String[])", mainClassName);

  // map C string args to Java string args
  if (debug) printf("--   c args to java args...\n");
  jstring jstr = env->NewStringUTF("");
  jobjectArray jargs = env->NewObjectArray(fanArgc, env->FindClass("java/lang/String"), jstr);
  for (int i=0; i<fanArgc; ++i)
    env->SetObjectArrayElement(jargs, i, env->NewStringUTF(fanArgv[i]));

  // invoke main
  env->CallStaticVoidMethod(mainClass, mainMethod, jargs);

  return 0;
}

//////////////////////////////////////////////////////////////////////////
// Java Main
//////////////////////////////////////////////////////////////////////////

int runJava()
{
  if (findJvmPath())  return -1;
  if (initOptions())  return -1;
  if (loadJava())     return -1;
  if (checkVersion()) return -1;
  if (runJavaMain())  return -1;
  return 0;
}