//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jul 15  Matthew Giannini    Creation
//

using System;
using System.Collections;
using System.Configuration;
using System.Configuration.Install;
using System.Diagnostics;
using System.IO;
using System.Management;
using System.ServiceProcess;

namespace FanSc
{
    class FanService : ServiceBase
    {
        private string[] cmdArgs;
        private Process process;

        public FanService(string[] args)
        {
            this.cmdArgs = args;
            this.ServiceName = Path.GetFileNameWithoutExtension(args[0]);
            this.CanStop = true;
            this.CanPauseAndContinue = false;
            this.AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            base.OnStart(args);
            ProcessStartInfo processInfo = new ProcessStartInfo("cmd.exe", "/C " + string.Join(" ", cmdArgs));
            this.EventLog.WriteEntry("Launching Fantom Service: cmd.exe " + processInfo.Arguments);
            processInfo.UseShellExecute = false;
            processInfo.CreateNoWindow = false;
            //processInfo.RedirectStandardError = true;
            //processInfo.RedirectStandardOutput = true;
            this.process = Process.Start(processInfo);
        }

        protected override void OnStop()
        {
            if (process != null)
            {
                KillProcessAndChildren(process.Id);
            }
            base.OnStop();
        }

        private static void KillProcessAndChildren(int pid)
        {
            ManagementObjectSearcher searcher = new ManagementObjectSearcher
               ("Select * From Win32_Process Where ParentProcessID=" + pid);
            ManagementObjectCollection moc = searcher.Get();
            foreach (ManagementObject mo in moc)
            {
                KillProcessAndChildren(Convert.ToInt32(mo["ProcessID"]));
            }
            try
            {
                Process proc = Process.GetProcessById(pid);
                proc.Kill();
            }
            catch (ArgumentException)
            {
                // Process already exited.
            }
        }
    }
}
