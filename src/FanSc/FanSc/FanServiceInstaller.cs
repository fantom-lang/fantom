//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jul 15  Matthew Giannini    Creation
//

using System;
using System.Collections;
using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;


namespace FanSc
{
    [RunInstaller(true)]
    public class FanServiceInstaller : Installer
    {
        private readonly ServiceProcessInstaller processInstaller;
        private readonly ServiceInstaller serviceInstaller;

        public FanServiceInstaller()
        {
            processInstaller = new ServiceProcessInstaller();
            serviceInstaller = new ServiceInstaller();
            processInstaller.Account = ServiceAccount.LocalSystem;
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            Installers.Add(serviceInstaller);
            Installers.Add(processInstaller);
        }

        public override void Install(IDictionary stateSaver)
        {
            string svcName = getServiceName();
            serviceInstaller.ServiceName = svcName;
            serviceInstaller.DisplayName = svcName;
            stateSaver.Add("ServiceName", svcName);

            // install it
            base.Install(stateSaver);

            string launcher = Context.Parameters["FanLauncher"];
            string launcherArgs = Context.Parameters["LauncherArgs"];


            // tweak settings
            using (ServiceController controller = new ServiceController(svcName))
            {
                string exePath = Context.Parameters["assemblyPath"];
                Win32Services.SetServiceExeArgs(controller, exePath, launcher + " " + launcherArgs);
            }
        }

        public override void Rollback(IDictionary savedState)
        {
            serviceInstaller.ServiceName = getServiceName();
            base.Rollback(savedState);
        }

        public override void Uninstall(IDictionary savedState)
        {
            serviceInstaller.ServiceName = getServiceName();
            base.Uninstall(savedState);
        }

        private string getServiceName()
        {
            string svcName = Context.Parameters["ServiceName"];
            if (string.IsNullOrEmpty(svcName))
                throw new ArgumentException("Missing required parameter 'ServiceName'");
            return svcName;
        }
    }
}
