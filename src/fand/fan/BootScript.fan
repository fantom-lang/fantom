//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 Mar 08  Brian Frank  Creation
//

**
** BootScript is the base class for the scripts used to
** boot up a fand process.
**
abstract class BootScript
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct a new build script.
  **
  new make()
  {
    try
    {
      setup
    }
    catch (Err err)
    {
      log.error("Error initializing script [$scriptFile.osPath]")
      throw err
    }
  }

//////////////////////////////////////////////////////////////////////////
// Environment
//////////////////////////////////////////////////////////////////////////

  ** Boot script log
  Log log := Log("fand")

  ** The source file of this script
  File scriptFile := File(type->sourceFile->toUri)

  ** The directory containing the this script
  File scriptDir := scriptFile.parent

//////////////////////////////////////////////////////////////////////////
// Services
//////////////////////////////////////////////////////////////////////////

  **
  ** The services are the list of threads to spawn on startup.
  **
  abstract Thread[] services

  **
  ** Start all the threads
  **
  virtual Void startServices()
  {
    services.each |Thread t| { t.start }
    Thread.sleep(50ms)
  }

//////////////////////////////////////////////////////////////////////////
// Setup
//////////////////////////////////////////////////////////////////////////

  **
  ** The setup callback is for initializing the application.
  **
  virtual Void setup()
  {
  }

  **
  ** Run the script
  **
  virtual Void run()
  {
    log.info("booting...")
    startServices
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  Int main()
  {
    success := false
    try
    {
      run
      Thread.sleep(Duration(Int.maxVal))
      return 0
    }
    catch (Err err)
    {
      log.error("Cannot boot")
      err.trace
      return 1
    }
  }

}