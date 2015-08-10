//
// Copyright (c) 2015, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   31 Jul 15  Matthew Giannini    Creation
//

using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.ServiceProcess;

namespace FanSc
{
    internal static class Win32Services
    {
        private enum SERVICE_CONFIG_INFO
        {
            DESCRIPTION = 1,
            FAILURE_ACTIONS = 2,
            DELAYED_AUTO_START_INFO = 3,
            FAILURE_ACTIONS_FLAG = 4,
            SERVICE_SID_INFO = 5,
            REQUIRED_PRIVILEGES_INFO = 6,
            PRESHUTDOWN_INFO = 7
        }

        private enum SC_ACTION_TYPE : uint
        {
            SC_ACTION_NONE = 0x00000000, // No action.
            SC_ACTION_RESTART = 0x00000001, // Restart the service.
            SC_ACTION_REBOOT = 0x00000002, // Reboot the computer.
            SC_ACTION_RUN_COMMAND = 0x00000003 // Run a command.
        }

        private static class Win32
        {
            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool SetServiceObjectSecurity(SafeHandle serviceHandle,
                                                                SecurityInfos secInfos,
                                                                [In] byte[] lpSecDesrBuf);

            [DllImport("advapi32.dll", SetLastError = true)]
            public static extern bool QueryServiceObjectSecurity(SafeHandle serviceHandle,
                                                                  SecurityInfos secInfo,
                                                                  [Out] byte[] lpSecDesrBuf, uint bufSize,
                                                                  out uint bufSizeNeeded);

            [DllImport("advapi32.dll", EntryPoint = "ChangeServiceConfig2W", ExactSpelling = true,
                CharSet = CharSet.Unicode, SetLastError = true)]
            private static extern int ChangeServiceConfig2(SafeHandle hService, int dwInfoLevel, IntPtr lpInfo);

            [DllImport("advapi32.dll", EntryPoint = "ChangeServiceConfigW", ExactSpelling = true,
                CharSet = CharSet.Unicode, SetLastError = true)]
            public static extern int ChangeServiceConfig(SafeHandle hService, int nServiceType, int nStartType,
                                                          int nErrorControl,
                                                          String lpBinaryPathName, String lpLoadOrderGroup,
                                                          IntPtr lpdwTagId, [In] String lpDependencies,
                                                          String lpServiceStartName,
                                                          String lpPassword, String lpDisplayName);

            public static void SetServiceConfig<T>(ServiceController sc, SERVICE_CONFIG_INFO infoId, T objData)
            {
                GCHandle hdata = GCHandle.Alloc(objData, GCHandleType.Pinned);
                try
                {
                    if (0 == ChangeServiceConfig2(sc.ServiceHandle, (int)infoId, hdata.AddrOfPinnedObject()))
                        throw new Win32Exception();
                }
                finally
                {
                    hdata.Free();
                }
            }
        }

        internal static void SetServiceExeArgs(ServiceController sc, string exePath, string arguments)
        {
            exePath = Path.GetFullPath(exePath.Trim(' ', '\'', '"'));
            string fqExec = String.Format("\"{0}\" {1}", exePath, arguments).TrimEnd();

            const int notChanged = -1;
            if (0 == Win32.ChangeServiceConfig(sc.ServiceHandle, notChanged, notChanged, notChanged, fqExec,
                                               null, IntPtr.Zero, null, null, null, null))
                throw new Win32Exception();
        }
    }
}
