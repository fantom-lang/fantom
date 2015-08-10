//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jul 15  Matthew Giannini    Creation
//

using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration.Install;
using System.IO;
using System.ServiceProcess;

namespace FanSc
{
    public class FanSc
    {
        private string[] rawArgs;

        public FanSc(string[] rawArgs)
        {
            this.rawArgs = rawArgs;
        }

        public void Run()
        {
            string cmd = rawArgs[0];
            switch (cmd.ToLower())
            {
                case "install":
                    DoInstall();
                    break;
                case "uninstall":
                    DoUninstall();
                    break;
                default:
                    ServiceBase.Run(new FanService(rawArgs));
                    break;
            }
        }

        private void DoInstall()
        {
            List <string> installerArgs = new List<string>();
            installerArgs.Add("/LogToConsole=true");
            installerArgs.Add("/ServiceName=" + ServiceName);
            installerArgs.Add("/FanLauncher=" + FanLauncher);
            installerArgs.Add("/LauncherArgs=" + LauncherArgs);

            IDictionary state = new Hashtable();
            string exe = System.Reflection.Assembly.GetExecutingAssembly().Location;
            AssemblyInstaller installer = new AssemblyInstaller(exe, installerArgs.ToArray());
            installer.UseNewContext = true;
            installer.Install(state);
            installer.Commit(state);
        }

        private void DoUninstall()
        {
            List<string> installerArgs = new List<string>();
            installerArgs.Add("/LogToConsole=true");
            installerArgs.Add("/ServiceName=" + ServiceName);

            IDictionary state = new Hashtable();
            string exe = System.Reflection.Assembly.GetExecutingAssembly().Location;
            AssemblyInstaller installer = new AssemblyInstaller(exe, installerArgs.ToArray());
            installer.UseNewContext = true;
            installer.Uninstall(state);
        }

        public string ServiceName
        {
            get
            {
                if (rawArgs.Length < 2) Usage("ServiceName required");
                return rawArgs[1];
            }
        }

        public string FanLauncher
        {
            get
            {
                if (rawArgs.Length < 3) Usage("FanLauncher argument required");
                string launcher = Path.GetFullPath(rawArgs[2].Trim(' ', '\'', '"'));
                if (!File.Exists(launcher))
                {
                    Console.Error.WriteLine("Fantom launcher '" + launcher + "' does not exist");
                    Environment.Exit(2);
                }
                launcher = String.Format("\"{0}\"", launcher);
                return launcher;
            }
        }

        public string LauncherArgs
        {
            get
            {
                // super-naive approach right now
                string args = "";
                for (int i=3; i < rawArgs.Length; ++i)
                {
                    args += rawArgs[i] + " ";
                }
                return args;
            }
        }

        public static void Usage(string msg = "")
        {
            Console.WriteLine(msg);
            Console.WriteLine(
@"
fansc is used to install or uninstall a Fantom application as a Windows service:

  fansc.exe install <ServiceName> <path\to\app\app_launcher.bat> [app arguments]

  fansc.exe uninstall <ServiceName>

  Examples:
    fansc.exe install MyService C:\fantom\myapp\bin\myservice.bat -port 8080
    fansc.exe uninstall MyService
"
            );
            Environment.Exit(1);
        }

        public static void Main(string[] args)
        {
            if (args.Length == 0) Usage();
            new FanSc(args).Run();
        }
    }
}
