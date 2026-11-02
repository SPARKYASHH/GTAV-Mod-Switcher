// MIT License. Copyright (c) 2026 SPARKYASHH.
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Windows.Forms;

internal static class Launcher {
    private const string Title = "GTA V Mod Switcher by SPARKYASHH";
    private static readonly string BasePath = AppDomain.CurrentDomain.BaseDirectory;
    private static readonly object LogLock = new object();
    private static StreamWriter Log;

    [STAThread]
    private static int Main(string[] args) {
        bool test = args.Length == 1 && args[0] == "--self-test";
        string logPath = "";
        Application.EnableVisualStyles();
        try {
            if (args.Length != 0 && !test) throw new ArgumentException("Unknown launcher argument.");
            string logs = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "SPARKYASHH", "GTAVModSwitcher", "logs");
            Directory.CreateDirectory(logs);
            logPath = Path.Combine(logs,"startup-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-") + Guid.NewGuid().ToString("N") + ".log");
            Log = new StreamWriter(logPath,false,new UTF8Encoding(true));
            Log.AutoFlush = true;
            Log.WriteLine(Title + " | " + DateTime.Now.ToString("o"));
            foreach(string name in new [] {"Launch-Worker.ps1","ModSwitch.ps1","ModSwitch.Core.ps1","Theme.cs","tests/Core.Tests.ps1","assets/app.ico"})
                if(!File.Exists(Path.Combine(BasePath,name))) throw new FileNotFoundException("Missing package file: " + name);
            if(test) RunWorker("Probe");
            RunWorker("Tests");
            RunWorker("Smoke");
            if(!test) RunWorker("App");
            Log.WriteLine("Completed successfully.");
            return 0;
        } catch(Exception ex) {
            if(Log != null) Log.WriteLine(ex.ToString());
            if(!test) MessageBox.Show(
                "Could not start GTA V Mod Switcher.\r\n\r\n" + ex.Message +
                (logPath.Length == 0 ? "" : "\r\n\r\nStartup log:\r\n" + logPath),Title,
                MessageBoxButtons.OK,MessageBoxIcon.Error);
            return 1;
        } finally {
            if(Log != null) Log.Dispose();
        }
    }
    private static void RunWorker(string step) {
        string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
            "WindowsPowerShell","v1.0","powershell.exe");
        var info = new ProcessStartInfo {
            FileName = powershell,
            Arguments = "-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File \"" + Path.Combine(BasePath,"Launch-Worker.ps1") + "\" -Step " + step,
            WorkingDirectory = BasePath,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };
        Log.WriteLine("Step: " + step);
        using(var process = new Process()) {
            process.StartInfo = info;
            DataReceivedEventHandler receive = delegate(object sender,DataReceivedEventArgs e) {
                if(e.Data != null) lock(LogLock) { Log.WriteLine(e.Data); }
            };
            process.OutputDataReceived += receive;
            process.ErrorDataReceived += receive;
            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            process.WaitForExit();
            if(process.ExitCode != 0) throw new InvalidOperationException("Startup step '" + step + "' failed (exit " + process.ExitCode + "). See the startup log.");
        }
    }
}
