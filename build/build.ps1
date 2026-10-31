# ==============================================================================
# Lead Architect: Emanuel Schaaf | Open Origin Architecture
# Projekt: Microsoft Ecosystem Desktop Hub V1 (Auto-Slide Edge + Inline Search)
# ==============================================================================

$ErrorActionPreference = "Stop"

# Laufende Instanz sauber beenden, falls vorhanden
Get-Process -Name "MicrosoftEcosystemHub" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 300

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$ExePath     = Join-Path $DesktopPath "MicrosoftEcosystemHub.exe"
$IconPath    = Join-Path $env:TEMP "ms_ecosystem_icon.ico"

Write-Host "[1/3] Erzeuge 4-Farben Microsoft-Ökosystem-Icon..." -ForegroundColor Cyan

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap(64, 64)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.Color]::FromArgb(255, 32, 32, 32))

# Klassische Microsoft-Quadrate (Rot, Grün, Blau, Gelb)
$cRed    = [System.Drawing.Color]::FromArgb(242, 80, 34)
$cGreen  = [System.Drawing.Color]::FromArgb(127, 186, 0)
$cBlue   = [System.Drawing.Color]::FromArgb(0, 164, 239)
$cYellow = [System.Drawing.Color]::FromArgb(255, 185, 0)

$size = 20
$g.FillRectangle((New-Object System.Drawing.SolidBrush($cRed)),    10, 10, $size, $size)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($cGreen)),  10 + $size + 4, 10, $size, $size)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($cBlue)),   10, 10 + $size + 4, $size, $size)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($cYellow)), 10 + $size + 4, 10 + $size + 4, $size, $size)
$g.Dispose()

$msPng = New-Object System.IO.MemoryStream
$bmp.Save($msPng, [System.Drawing.Imaging.ImageFormat]::Png)
$pngBytes = $msPng.ToArray()
$msPng.Dispose()
$bmp.Dispose()

$fsIco = New-Object System.IO.FileStream($IconPath, [System.IO.FileMode]::Create)
$bw    = New-Object System.IO.BinaryWriter($fsIco)
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]1)
$bw.Write([Byte]64);  $bw.Write([Byte]64);  $bw.Write([Byte]0); $bw.Write([Byte]0)
$bw.Write([UInt16]1); $bw.Write([UInt16]32)
$bw.Write([UInt32]$pngBytes.Length)
$bw.Write([UInt32]22)
$bw.Write($pngBytes)
$bw.Close()
$fsIco.Close()

Write-Host "[2/3] Kompiliere MicrosoftEcosystemHub ($ExePath)..." -ForegroundColor Cyan

$CSharpSource = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using Microsoft.Win32;

namespace MicrosoftEcosystemHub
{
    public class AppItem
    {
        public string Name;
        public string Category;
        public string Url;
        public string BadgeText;
        public Color BadgeColor;

        public AppItem(string name, string cat, string url, string badge, Color color)
        {
            Name = name;
            Category = cat;
            Url = url;
            BadgeText = badge;
            BadgeColor = color;
        }
    }

    public class SearchResultEntry
    {
        public string Title;
        public string Snippet;
        public string Url;
        public string SourceTag;
        public bool IsHighlight;
    }

    public class ConfigManager
    {
        private static string ConfigDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "MicrosoftEcosystemHub");
        private static string ConfigFile = Path.Combine(ConfigDir, "settings.ini");

        public int PosX = -1;
        public int PosY = -1;
        public bool IsLocked = false;
        public bool UseAppMode = true;
        public bool AlwaysOnTop = true;
        public bool AutoSlideEdge = true;

        public void Load()
        {
            try
            {
                if (!File.Exists(ConfigFile)) return;
                string[] lines = File.ReadAllLines(ConfigFile);
                foreach (string line in lines)
                {
                    string[] parts = line.Split('=');
                    if (parts.Length != 2) continue;
                    string k = parts[0].Trim();
                    string v = parts[1].Trim();
                    if (k == "PosX") int.TryParse(v, out PosX);
                    if (k == "PosY") int.TryParse(v, out PosY);
                    if (k == "IsLocked") bool.TryParse(v, out IsLocked);
                    if (k == "UseAppMode") bool.TryParse(v, out UseAppMode);
                    if (k == "AlwaysOnTop") bool.TryParse(v, out AlwaysOnTop);
                    if (k == "AutoSlideEdge") bool.TryParse(v, out AutoSlideEdge);
                }
            }
            catch { }
        }

        public void Save()
        {
            try
            {
                if (!Directory.Exists(ConfigDir)) Directory.CreateDirectory(ConfigDir);
                StringBuilder sb = new StringBuilder();
                sb.AppendLine("PosX=" + PosX);
                sb.AppendLine("PosY=" + PosY);
                sb.AppendLine("IsLocked=" + IsLocked);
                sb.AppendLine("UseAppMode=" + UseAppMode);
                sb.AppendLine("AlwaysOnTop=" + AlwaysOnTop);
                sb.AppendLine("AutoSlideEdge=" + AutoSlideEdge);
                File.WriteAllText(ConfigFile, sb.ToString());
            }
            catch { }
        }
    }

    public static class MSAccountDetector
    {
        public static string GetEdgePath()
        {
            string[] candidates = new string[]
            {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), @"Microsoft\Edge\Application\msedge.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Microsoft\Edge\Application\msedge.exe")
            };
            foreach (string path in candidates)
            {
                if (File.Exists(path)) return path;
            }
            return null;
        }

        public static string DetectActiveAccount(out bool isLoggedIn)
        {
            isLoggedIn = false;

            // 1. Primärprüfung: Native Windows Registry (IdentityCRL / MSA / Entra ID)
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\IdentityCRL\UserExtendedProperties", false))
                {
                    if (key != null)
                    {
                        string[] subKeys = key.GetSubKeyNames();
                        foreach (string sk in subKeys)
                        {
                            if (sk.Contains("@"))
                            {
                                isLoggedIn = true;
                                return sk;
                            }
                        }
                    }
                }
            }
            catch { }

            // 2. Sekundärprüfung: Microsoft Edge Local State Profil
            try
            {
                string edgeLocalState = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    @"Microsoft\Edge\User Data\Local State");

                if (File.Exists(edgeLocalState))
                {
                    string content;
                    using (FileStream fs = new FileStream(edgeLocalState, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    using (StreamReader sr = new StreamReader(fs, Encoding.UTF8))
                    {
                        content = sr.ReadToEnd();
                    }

                    Match mUser = Regex.Match(content, "\"user_name\"\\s*:\\s*\"([^\"]+@[^\"]+)\"");
                    if (mUser.Success && !string.IsNullOrEmpty(mUser.Groups[1].Value))
                    {
                        isLoggedIn = true;
                        return mUser.Groups[1].Value;
                    }
                }
            }
            catch { }

            return "Kein MSA / Entra-Konto erkannt";
        }

        public static void LaunchTarget(string url, bool appMode)
        {
            // Native Windows 11 Protokolle direkt über die Shell ausführen
            if (url.StartsWith("ms-") || url.StartsWith("windowsdefender:"))
            {
                try
                {
                    Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
                    return;
                }
                catch { }
            }

            bool loggedIn;
            DetectActiveAccount(out loggedIn);

            string targetUrl = url;
            if (!loggedIn && !url.Contains("login.live.com") && !url.Contains("account.microsoft.com"))
            {
                DialogResult dr = MessageBox.Show(
                    "Es wurde kein aktives Microsoft-Konto (MSA / Entra ID) erkannt.\n\nMöchtest du dich jetzt anmelden, um Microsoft 365 & Microsoft Rewards-Punkte zu verknüpfen?",
                    "Microsoft Account Verknüpfung",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Information);

                if (dr == DialogResult.Yes)
                {
                    targetUrl = "https://login.live.com/";
                }
            }

            string edgePath = GetEdgePath();
            if (edgePath != null)
            {
                string args = appMode ? ("--app=\"" + targetUrl + "\"") : ("\"" + targetUrl + "\"");
                Process.Start(edgePath, args);
            }
            else
            {
                Process.Start(targetUrl);
            }
        }
    }

    public static class InlineSearchEngine
    {
        static InlineSearchEngine()
        {
            try { ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072; } catch { }
        }

        private static string FetchString(string url)
        {
            HttpWebRequest req = (HttpWebRequest)WebRequest.Create(url);
            req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edg/128.0.0.0 MicrosoftEcosystemHub/1.0";
            req.Timeout = 7000;
            using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
            using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
            {
                return sr.ReadToEnd();
            }
        }

        private static string CleanStopWords(string query)
        {
            string q = query.Trim();
            string[] prefixes = new string[]
            {
                "erkläre mir was ein ", "erkläre mir was eine ", "erkläre mir was ", "erkläre mir ",
                "was ist ein ", "was ist eine ", "was sind ", "was ist ", "wer ist ", "wie funktioniert ein ",
                "wie funktioniert eine ", "wie funktioniert ", "erkläre ", "definiere "
            };
            string lower = q.ToLowerInvariant();
            foreach (string p in prefixes)
            {
                if (lower.StartsWith(p))
                {
                    q = q.Substring(p.Length);
                    break;
                }
            }
            q = Regex.Replace(q, @"(\s+ist)?\s*[\?\!\.]*$", "", RegexOptions.IgnoreCase).Trim();
            return string.IsNullOrEmpty(q) ? query.Trim() : q;
        }

        private static string DecodeJsonString(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            string s = input.Replace("\\\"", "\"").Replace("\\n", "\n").Replace("\\r", "").Replace("\\/", "/").Replace("\\t", " ");
            s = Regex.Replace(s, @"\\u([0-9a-fA-F]{4})", delegate(Match m) {
                return ((char)Convert.ToInt32(m.Groups[1].Value, 16)).ToString();
            });
            return s;
        }

        private static string StripHtml(string input)
        {
            if (string.IsNullOrEmpty(input)) return "";
            string s = Regex.Replace(input, "<[^>]+>", "");
            s = WebUtility.HtmlDecode(s);
            return s.Trim();
        }

        public static List<SearchResultEntry> QueryInline(string rawQuery)
        {
            List<SearchResultEntry> list = new List<SearchResultEntry>();
            string coreTerm = CleanStopWords(rawQuery);

            // 1. Copilot / Wissens-Übersicht (Wikipedia DE Summary REST API)
            try
            {
                string searchApi = "https://de.wikipedia.org/w/api.php?action=query&list=search&srsearch=" +
                                   Uri.EscapeDataString(coreTerm) + "&utf8=1&format=json&srlimit=2";
                string searchJson = FetchString(searchApi);

                MatchCollection titleMatches = Regex.Matches(searchJson, "\"title\"\\s*:\\s*\"([^\"]+)\"");
                if (titleMatches.Count > 0)
                {
                    string bestTitle = DecodeJsonString(titleMatches[0].Groups[1].Value);
                    string summaryUrl = "https://de.wikipedia.org/api/rest_v1/page/summary/" + Uri.EscapeDataString(bestTitle.Replace(" ", "_"));
                    string sumJson = FetchString(summaryUrl);

                    Match mExtract = Regex.Match(sumJson, "\"extract\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
                    if (mExtract.Success)
                    {
                        string extract = DecodeJsonString(mExtract.Groups[1].Value);
                        if (!string.IsNullOrEmpty(extract))
                        {
                            SearchResultEntry overview = new SearchResultEntry();
                            overview.Title = "✦ Copilot Wissens-Übersicht  —  " + bestTitle;
                            overview.Snippet = extract;
                            overview.Url = "https://www.bing.com/search?q=" + Uri.EscapeDataString(rawQuery);
                            overview.SourceTag = "BING / WISSEN";
                            overview.IsHighlight = true;
                            list.Add(overview);
                        }
                    }
                }
            }
            catch { }

            // 2. Offizielle Microsoft Learn / Docs API (Für IT-, Windows-, C#-, PowerShell- & Azure-Fragen)
            try
            {
                string learnApi = "https://learn.microsoft.com/api/search?search=" +
                                  Uri.EscapeDataString(coreTerm) + "&locale=de-de&$top=4";
                string learnJson = FetchString(learnApi);

                MatchCollection learnMatches = Regex.Matches(
                    learnJson,
                    "\"title\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"\\s*,\\s*\"url\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\".*?\"description\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"",
                    RegexOptions.Singleline);

                int lCount = 0;
                foreach (Match m in learnMatches)
                {
                    if (lCount >= 3) break;
                    string t = StripHtml(DecodeJsonString(m.Groups[1].Value));
                    string u = DecodeJsonString(m.Groups[2].Value);
                    string d = StripHtml(DecodeJsonString(m.Groups[3].Value));

                    if (!string.IsNullOrEmpty(t) && !string.IsNullOrEmpty(u))
                    {
                        SearchResultEntry docEntry = new SearchResultEntry();
                        docEntry.Title = "📘 MS Learn: " + t;
                        docEntry.Snippet = string.IsNullOrEmpty(d) ? "Offizielle Microsoft Learn & Docs Dokumentation" : d;
                        docEntry.Url = u;
                        docEntry.SourceTag = "MICROSOFT LEARN";
                        docEntry.IsHighlight = false;
                        list.Add(docEntry);
                        lCount++;
                    }
                }
            }
            catch { }

            // 3. Live Bing Search / News RSS-Schnittstelle
            try
            {
                string bingRss = "https://www.bing.com/news/search?q=" + Uri.EscapeDataString(rawQuery) + "&setlang=de&format=rss";
                string rssXml = FetchString(bingRss);
                MatchCollection items = Regex.Matches(rssXml, "<item>.*?<title>(.*?)</title>.*?<link>(.*?)</link>.*?<description>(.*?)</description>.*?</item>", RegexOptions.Singleline);
                int bCount = 0;
                foreach (Match m in items)
                {
                    if (bCount >= 4) break;
                    string t = StripHtml(m.Groups[1].Value);
                    string l = StripHtml(m.Groups[2].Value);
                    string d = StripHtml(m.Groups[3].Value);
                    if (d.Length > 200) d = d.Substring(0, 200) + " ...";

                    SearchResultEntry webEntry = new SearchResultEntry();
                    webEntry.Title = "🌐 " + t;
                    webEntry.Snippet = string.IsNullOrEmpty(d) ? "Aktuelles Ergebnis über Microsoft Bing" : d;
                    webEntry.Url = l;
                    webEntry.SourceTag = "BING WEB/NEWS";
                    webEntry.IsHighlight = false;
                    list.Add(webEntry);
                    bCount++;
                }
            }
            catch { }

            if (list.Count == 0)
            {
                SearchResultEntry fallback = new SearchResultEntry();
                fallback.Title = "✦ Bing & Copilot Direkt-Analyse: " + rawQuery;
                fallback.Snippet = "Klicke hier, um die Anfrage direkt in Microsoft Bing / Copilot im App-Modus zu öffnen.";
                fallback.Url = "https://www.bing.com/search?q=" + Uri.EscapeDataString(rawQuery);
                fallback.SourceTag = "BING";
                fallback.IsHighlight = true;
                list.Add(fallback);
            }

            return list;
        }
    }

    public class HubPopupForm : Form
    {
        private ConfigManager Config;
        private List<AppItem> AllApps = new List<AppItem>();
        private FlowLayoutPanel ContentPanel;
        private TextBox SearchBox;
        private Label AccountStatusLabel;
        private Button RewardsActionButton;
        private CheckBox AppModeCheck;
        private CheckBox AutostartCheck;
        private bool ShowingSearchResults = false;

        public HubPopupForm(ConfigManager config)
        {
            Config = config;

            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.StartPosition = FormStartPosition.Manual;
            this.Size = new Size(385, 630);
            this.BackColor = Color.FromArgb(28, 29, 33);
            this.TopMost = true;
            this.DoubleBuffered = true;

            InitAppCatalog();
            BuildUI();
        }

        private void InitAppCatalog()
        {
            Color cBlue    = Color.FromArgb(0, 120, 212);
            Color cCyan    = Color.FromArgb(0, 164, 239);
            Color cGreen   = Color.FromArgb(16, 124, 16);
            Color cLime    = Color.FromArgb(127, 186, 0);
            Color cOrange  = Color.FromArgb(216, 59, 1);
            Color cPurple  = Color.FromArgb(115, 70, 210);
            Color cTeal    = Color.FromArgb(0, 130, 114);
            Color cGold    = Color.FromArgb(230, 155, 0);

            // Meine Favoriten (Kern-Ökosystem)
            AllApps.Add(new AppItem("Copilot", "Fav", "https://copilot.microsoft.com", "✦", cPurple));
            AllApps.Add(new AppItem("Outlook", "Fav", "https://outlook.live.com", "✉", cBlue));
            AllApps.Add(new AppItem("OneDrive", "Fav", "https://onedrive.live.com", "☁", cBlue));
            AllApps.Add(new AppItem("MS Rewards", "Fav", "https://rewards.bing.com", "🏆", cGold));
            AllApps.Add(new AppItem("Xbox Cloud", "Fav", "https://www.xbox.com/play", "X", cGreen));
            AllApps.Add(new AppItem("MS Store", "Fav", "https://apps.microsoft.com", "🛍", cCyan));
            AllApps.Add(new AppItem("Teams", "Fav", "https://teams.microsoft.com", "T", cPurple));
            AllApps.Add(new AppItem("Office 365", "Fav", "https://www.office.com", "O", cOrange));
            AllApps.Add(new AppItem("Bing Suche", "Fav", "https://www.bing.com", "b", cCyan));

            // Alle Microsoft 365, Cloud, Dev & System Tools
            AllApps.Add(new AppItem("Word", "Ext", "https://www.office.com/launch/word", "W", cBlue));
            AllApps.Add(new AppItem("Excel", "Ext", "https://www.office.com/launch/excel", "X", cGreen));
            AllApps.Add(new AppItem("PowerPoint", "Ext", "https://www.office.com/launch/powerpoint", "P", cOrange));
            AllApps.Add(new AppItem("OneNote", "Ext", "https://www.onenote.com/notebooks", "N", cPurple));
            AllApps.Add(new AppItem("To Do", "Ext", "https://to-do.microsoft.com", "✔", cBlue));
            AllApps.Add(new AppItem("Kalender", "Ext", "https://outlook.live.com/calendar", "📅", cBlue));
            AllApps.Add(new AppItem("MS Loop", "Ext", "https://loop.microsoft.com", "∞", cPurple));
            AllApps.Add(new AppItem("Whiteboard", "Ext", "https://whiteboard.office.com", "✎", cCyan));
            AllApps.Add(new AppItem("Clipchamp", "Ext", "https://app.clipchamp.com", "🎬", cPurple));
            AllApps.Add(new AppItem("MS Designer", "Ext", "https://designer.microsoft.com", "🎨", cTeal));
            AllApps.Add(new AppItem("MS Learn", "Ext", "https://learn.microsoft.com/de-de/", "📘", cBlue));
            AllApps.Add(new AppItem("Azure Portal", "Ext", "https://portal.azure.com", "Δ", cCyan));
            AllApps.Add(new AppItem("GitHub", "Ext", "https://github.com", "🐙", cPurple));
            AllApps.Add(new AppItem("Dev Center", "Ext", "https://developer.microsoft.com", "</>", cBlue));
            AllApps.Add(new AppItem("Defender", "Ext", "windowsdefender:", "🛡", cLime));
            AllApps.Add(new AppItem("Win Update", "Ext", "ms-settings:windowsupdate", "↻", cBlue));
            AllApps.Add(new AppItem("Bing Maps", "Ext", "https://www.bing.com/maps", "📍", cTeal));
            AllApps.Add(new AppItem("MS Start News", "Ext", "https://www.msn.com/de-de", "📰", cBlue));
            AllApps.Add(new AppItem("Power BI", "Ext", "https://app.powerbi.com", "📊", cGold));
            AllApps.Add(new AppItem("LinkedIn", "Ext", "https://www.linkedin.com", "in", cBlue));
            AllApps.Add(new AppItem("MS Konto", "Ext", "https://account.microsoft.com", "👤", cCyan));
        }

        private void BuildUI()
        {
            Panel headerPanel = new Panel();
            headerPanel.Dock = DockStyle.Top;
            headerPanel.Height = 128;
            headerPanel.BackColor = Color.FromArgb(20, 21, 24);
            headerPanel.Padding = new Padding(12);

            AccountStatusLabel = new Label();
            AccountStatusLabel.Location = new Point(12, 10);
            AccountStatusLabel.Size = new Size(250, 22);
            AccountStatusLabel.Font = new Font("Segoe UI Semibold", 9.0f);
            AccountStatusLabel.ForeColor = Color.White;
            headerPanel.Controls.Add(AccountStatusLabel);

            RewardsActionButton = new Button();
            RewardsActionButton.Location = new Point(268, 7);
            RewardsActionButton.Size = new Size(103, 26);
            RewardsActionButton.FlatStyle = FlatStyle.Flat;
            RewardsActionButton.FlatAppearance.BorderSize = 0;
            RewardsActionButton.BackColor = Color.FromArgb(0, 120, 212);
            RewardsActionButton.ForeColor = Color.White;
            RewardsActionButton.Font = new Font("Segoe UI Semibold", 8.0f);
            RewardsActionButton.Text = "🏆 MS Rewards";
            RewardsActionButton.Cursor = Cursors.Hand;
            RewardsActionButton.Click += delegate {
                MSAccountDetector.LaunchTarget("https://rewards.bing.com", Config.UseAppMode);
                this.Hide();
            };
            headerPanel.Controls.Add(RewardsActionButton);

            SearchBox = new TextBox();
            SearchBox.Location = new Point(12, 42);
            SearchBox.Size = new Size(288, 26);
            SearchBox.BackColor = Color.FromArgb(40, 42, 48);
            SearchBox.ForeColor = Color.White;
            SearchBox.BorderStyle = BorderStyle.FixedSingle;
            SearchBox.Font = new Font("Segoe UI", 9.5f);
            SearchBox.Text = "";
            SearchBox.TextChanged += delegate {
                string txt = SearchBox.Text.Trim();
                if (string.IsNullOrEmpty(txt))
                {
                    PopulateAppGrid("");
                }
                else if (!ShowingSearchResults)
                {
                    bool anyMatch = false;
                    foreach (AppItem a in AllApps)
                    {
                        if (a.Name.IndexOf(txt, StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            anyMatch = true;
                            break;
                        }
                    }
                    if (anyMatch) PopulateAppGrid(txt);
                }
            };
            SearchBox.KeyDown += delegate(object s, KeyEventArgs e) {
                if (e.KeyCode == Keys.Enter && !string.IsNullOrEmpty(SearchBox.Text.Trim()))
                {
                    e.SuppressKeyPress = true;
                    RunInlineSearch(SearchBox.Text.Trim());
                }
            };
            headerPanel.Controls.Add(SearchBox);

            Button btnInlineSearch = new Button();
            btnInlineSearch.Location = new Point(306, 41);
            btnInlineSearch.Size = new Size(65, 26);
            btnInlineSearch.FlatStyle = FlatStyle.Flat;
            btnInlineSearch.FlatAppearance.BorderSize = 0;
            btnInlineSearch.BackColor = Color.FromArgb(0, 120, 212);
            btnInlineSearch.ForeColor = Color.White;
            btnInlineSearch.Font = new Font("Segoe UI Semibold", 8.0f);
            btnInlineSearch.Text = "✦ Suche";
            btnInlineSearch.Cursor = Cursors.Hand;
            btnInlineSearch.Click += delegate {
                if (!string.IsNullOrEmpty(SearchBox.Text.Trim()))
                {
                    RunInlineSearch(SearchBox.Text.Trim());
                }
                else
                {
                    SearchBox.Focus();
                }
            };
            headerPanel.Controls.Add(btnInlineSearch);

            AppModeCheck = new CheckBox();
            AppModeCheck.Location = new Point(12, 76);
            AppModeCheck.Size = new Size(215, 20);
            AppModeCheck.ForeColor = Color.FromArgb(200, 204, 210);
            AppModeCheck.Font = new Font("Segoe UI", 8.2f);
            AppModeCheck.Text = "In Edge als App öffnen (--app)";
            AppModeCheck.Checked = Config.UseAppMode;
            AppModeCheck.CheckedChanged += delegate {
                Config.UseAppMode = AppModeCheck.Checked;
                Config.Save();
            };
            headerPanel.Controls.Add(AppModeCheck);

            AutostartCheck = new CheckBox();
            AutostartCheck.Location = new Point(235, 76);
            AutostartCheck.Size = new Size(135, 20);
            AutostartCheck.ForeColor = Color.FromArgb(200, 204, 210);
            AutostartCheck.Font = new Font("Segoe UI", 8.2f);
            AutostartCheck.Text = "Windows-Autostart";
            AutostartCheck.Checked = IsAutostartEnabled();
            AutostartCheck.CheckedChanged += delegate {
                SetAutostart(AutostartCheck.Checked);
            };
            headerPanel.Controls.Add(AutostartCheck);

            Label modeHintLabel = new Label();
            modeHintLabel.Location = new Point(12, 101);
            modeHintLabel.Size = new Size(358, 18);
            modeHintLabel.ForeColor = Color.FromArgb(145, 150, 160);
            modeHintLabel.Font = new Font("Segoe UI", 7.8f);
            modeHintLabel.Text = "Frage + [Enter] -> Inline-Suche (Copilot-Wissen + MS Learn + Bing)!";
            headerPanel.Controls.Add(modeHintLabel);

            this.Controls.Add(headerPanel);

            ContentPanel = new FlowLayoutPanel();
            ContentPanel.Location = new Point(6, 132);
            ContentPanel.Size = new Size(373, 490);
            ContentPanel.AutoScroll = true;
            ContentPanel.FlowDirection = FlowDirection.LeftToRight;
            ContentPanel.WrapContents = true;
            ContentPanel.BackColor = Color.FromArgb(28, 29, 33);
            ContentPanel.Padding = new Padding(4);
            this.Controls.Add(ContentPanel);

            RefreshAccountBanner();
            PopulateAppGrid("");
        }

        private void RunInlineSearch(string query)
        {
            ShowingSearchResults = true;
            ContentPanel.SuspendLayout();
            ContentPanel.Controls.Clear();

            Panel navBar = new Panel();
            navBar.Size = new Size(338, 34);
            navBar.BackColor = Color.FromArgb(36, 38, 44);
            navBar.Margin = new Padding(4, 4, 4, 8);

            Button btnBack = new Button();
            btnBack.Location = new Point(4, 4);
            btnBack.Size = new Size(175, 26);
            btnBack.FlatStyle = FlatStyle.Flat;
            btnBack.FlatAppearance.BorderSize = 0;
            btnBack.BackColor = Color.FromArgb(0, 120, 212);
            btnBack.ForeColor = Color.White;
            btnBack.Font = new Font("Segoe UI Semibold", 8.2f);
            btnBack.Text = "← Zurück zu MS-Apps";
            btnBack.Cursor = Cursors.Hand;
            btnBack.Click += delegate {
                ShowingSearchResults = false;
                PopulateAppGrid("");
            };
            navBar.Controls.Add(btnBack);

            Button btnEdge = new Button();
            btnEdge.Location = new Point(186, 4);
            btnEdge.Size = new Size(148, 26);
            btnEdge.FlatStyle = FlatStyle.Flat;
            btnEdge.FlatAppearance.BorderSize = 0;
            btnEdge.BackColor = Color.FromArgb(55, 58, 66);
            btnEdge.ForeColor = Color.White;
            btnEdge.Font = new Font("Segoe UI", 8.0f);
            btnEdge.Text = "In Bing / Edge öffnen ↗";
            btnEdge.Cursor = Cursors.Hand;
            btnEdge.Click += delegate {
                MSAccountDetector.LaunchTarget("https://www.bing.com/search?q=" + Uri.EscapeDataString(query), Config.UseAppMode);
                this.Hide();
            };
            navBar.Controls.Add(btnEdge);

            ContentPanel.Controls.Add(navBar);

            Label loadingLbl = new Label();
            loadingLbl.Text = "✦ Durchsuche MS Learn, Bing & Wissensbasis nach \"" + query + "\" ...";
            loadingLbl.Font = new Font("Segoe UI Semibold", 9.2f);
            loadingLbl.ForeColor = Color.FromArgb(110, 190, 255);
            loadingLbl.Size = new Size(335, 42);
            loadingLbl.Margin = new Padding(8, 10, 8, 10);
            ContentPanel.Controls.Add(loadingLbl);
            ContentPanel.ResumeLayout();

            ThreadPool.QueueUserWorkItem(delegate {
                List<SearchResultEntry> results = InlineSearchEngine.QueryInline(query);
                try
                {
                    this.BeginInvoke((MethodInvoker)delegate {
                        RenderInlineResults(results);
                    });
                }
                catch { }
            });
        }

        private void RenderInlineResults(List<SearchResultEntry> results)
        {
            if (!ShowingSearchResults) return;

            ContentPanel.SuspendLayout();
            while (ContentPanel.Controls.Count > 1)
            {
                ContentPanel.Controls.RemoveAt(1);
            }

            foreach (SearchResultEntry entry in results)
            {
                Panel card = new Panel();
                card.Width = 338;
                card.BackColor = entry.IsHighlight ? Color.FromArgb(30, 44, 62) : Color.FromArgb(38, 40, 46);
                card.Margin = new Padding(4, 4, 4, 8);
                card.Padding = new Padding(10);
                card.Cursor = Cursors.Hand;

                Label lblTitle = new Label();
                lblTitle.Text = entry.Title;
                lblTitle.Font = new Font("Segoe UI Semibold", entry.IsHighlight ? 9.8f : 9.2f);
                lblTitle.ForeColor = entry.IsHighlight ? Color.FromArgb(100, 200, 255) : Color.FromArgb(150, 205, 255);
                lblTitle.Location = new Point(10, 10);
                lblTitle.MaximumSize = new Size(318, 0);
                lblTitle.AutoSize = true;
                card.Controls.Add(lblTitle);

                Label lblBody = new Label();
                lblBody.Text = entry.Snippet;
                lblBody.Font = new Font("Segoe UI", 8.9f);
                lblBody.ForeColor = Color.FromArgb(230, 232, 236);
                lblBody.Location = new Point(10, lblTitle.Bottom + 8);
                lblBody.MaximumSize = new Size(318, 0);
                lblBody.AutoSize = true;
                card.Controls.Add(lblBody);

                card.Height = lblBody.Bottom + 14;

                EventHandler openLink = delegate {
                    MSAccountDetector.LaunchTarget(entry.Url, Config.UseAppMode);
                    this.Hide();
                };
                card.Click += openLink;
                lblTitle.Click += openLink;
                lblBody.Click += openLink;

                ContentPanel.Controls.Add(card);
            }

            ContentPanel.ResumeLayout();
            ContentPanel.Focus();
        }

        public void RefreshAccountBanner()
        {
            bool loggedIn;
            string acc = MSAccountDetector.DetectActiveAccount(out loggedIn);
            if (loggedIn)
            {
                AccountStatusLabel.Text = "● " + acc;
                AccountStatusLabel.ForeColor = Color.FromArgb(127, 186, 0);
                RewardsActionButton.Text = "🏆 MS Rewards";
                RewardsActionButton.BackColor = Color.FromArgb(0, 120, 212);
            }
            else
            {
                AccountStatusLabel.Text = "● Kein MS-Konto erkannt";
                AccountStatusLabel.ForeColor = Color.FromArgb(242, 139, 130);
                RewardsActionButton.Text = "MS Login";
                RewardsActionButton.BackColor = Color.FromArgb(216, 59, 1);
            }
        }

        public void PopulateAppGrid(string filter)
        {
            ShowingSearchResults = false;
            ContentPanel.SuspendLayout();
            ContentPanel.Controls.Clear();

            bool showHeaders = string.IsNullOrEmpty(filter);

            if (showHeaders)
            {
                ContentPanel.Controls.Add(CreateSectionHeader("Microsoft Favoriten & Rewards"));
            }

            bool addedExtHeader = false;
            foreach (AppItem item in AllApps)
            {
                if (!string.IsNullOrEmpty(filter))
                {
                    if (item.Name.IndexOf(filter, StringComparison.OrdinalIgnoreCase) < 0)
                        continue;
                }
                else if (item.Category == "Ext" && !addedExtHeader)
                {
                    addedExtHeader = true;
                    ContentPanel.Controls.Add(CreateSectionHeader("Microsoft 365, Azure & System-Tools"));
                }

                ContentPanel.Controls.Add(CreateAppTile(item));
            }

            ContentPanel.ResumeLayout();
        }

        private Control CreateSectionHeader(string title)
        {
            Label lbl = new Label();
            lbl.Text = title;
            lbl.Font = new Font("Segoe UI Semibold", 9.5f);
            lbl.ForeColor = Color.FromArgb(210, 214, 220);
            lbl.Size = new Size(335, 26);
            lbl.TextAlign = ContentAlignment.BottomLeft;
            lbl.Margin = new Padding(6, 6, 6, 4);
            return lbl;
        }

        private Control CreateAppTile(AppItem item)
        {
            Panel tile = new Panel();
            tile.Size = new Size(106, 88);
            tile.Margin = new Padding(4);
            tile.BackColor = Color.FromArgb(38, 40, 46);
            tile.Cursor = Cursors.Hand;

            tile.Paint += delegate(object s, PaintEventArgs e) {
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                Rectangle badgeRect = new Rectangle(33, 10, 40, 40);
                using (SolidBrush b = new SolidBrush(item.BadgeColor))
                {
                    // Fluent-Design abgerundetes Quadrat statt Kreis zur optischen Unterscheidung
                    e.Graphics.FillRectangle(b, badgeRect);
                }
                StringFormat sf = new StringFormat();
                sf.Alignment = StringAlignment.Center;
                sf.LineAlignment = StringAlignment.Center;
                using (Font f = new Font("Segoe UI Bold", 11.5f))
                using (SolidBrush tb = new SolidBrush(Color.White))
                {
                    e.Graphics.DrawString(item.BadgeText, f, tb, badgeRect, sf);
                }

                Rectangle textRect = new Rectangle(2, 54, 102, 28);
                using (Font tf = new Font("Segoe UI", 8.5f))
                using (SolidBrush tBrush = new SolidBrush(Color.FromArgb(232, 234, 237)))
                {
                    e.Graphics.DrawString(item.Name, tf, tBrush, textRect, sf);
                }
            };

            tile.MouseEnter += delegate { tile.BackColor = Color.FromArgb(56, 60, 68); };
            tile.MouseLeave += delegate { tile.BackColor = Color.FromArgb(38, 40, 46); };
            tile.Click += delegate {
                MSAccountDetector.LaunchTarget(item.Url, Config.UseAppMode);
                this.Hide();
            };

            return tile;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            using (Pen p = new Pen(Color.FromArgb(0, 120, 212), 1))
            {
                e.Graphics.DrawRectangle(p, 0, 0, this.Width - 1, this.Height - 1);
            }
        }

        protected override void OnDeactivate(EventArgs e)
        {
            base.OnDeactivate(e);
            this.Hide();
        }

        private bool IsAutostartEnabled()
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", false))
                {
                    if (key == null) return false;
                    return key.GetValue("MicrosoftEcosystemHub") != null;
                }
            }
            catch { return false; }
        }

        private void SetAutostart(bool enable)
        {
            try
            {
                using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run", true))
                {
                    if (key == null) return;
                    if (enable)
                        key.SetValue("MicrosoftEcosystemHub", "\"" + Application.ExecutablePath + "\"");
                    else
                        key.DeleteValue("MicrosoftEcosystemHub", false);
                }
            }
            catch { }
        }
    }

    public class LauncherOrbForm : Form
    {
        private ConfigManager Config;
        private HubPopupForm PopupMenu;
        private bool IsDragging = false;
        private Point DragStartPoint;
        private bool DidMove = false;
        private bool IsHovered = false;
        private Rectangle LockButtonRect = new Rectangle(42, 2, 20, 20);
        private ToolTip OrbToolTip;

        private System.Windows.Forms.Timer IdleTimer;
        private System.Windows.Forms.Timer SlideTimer;
        private bool IsDockedCollapsed = false;
        private int TargetX = 0;
        private const int PeekWidth = 26; // Lässt die linke Spalte der MS-Farbkacheln am Rand sichtbar

        public LauncherOrbForm()
        {
            Config = new ConfigManager();
            Config.Load();

            this.FormBorderStyle = FormBorderStyle.None;
            this.ShowInTaskbar = false;
            this.Size = new Size(64, 64);
            this.StartPosition = FormStartPosition.Manual;
            this.BackColor = Color.FromArgb(32, 33, 36);
            this.TopMost = Config.AlwaysOnTop;
            this.DoubleBuffered = true;
            this.Cursor = Cursors.Hand;

            Rectangle wa = Screen.PrimaryScreen.WorkingArea;
            if (Config.PosX >= 0 && Config.PosY >= 0)
            {
                this.Location = new Point(Config.PosX, Config.PosY);
            }
            else
            {
                // Standardmäßig auf Y = Top + 195, damit er sauber unter dem Google-Hub (Top + 120) sitzt
                this.Location = new Point(wa.Right - this.Width, wa.Top + 195);
            }

            OrbToolTip = new ToolTip();
            UpdateTooltipText();

            PopupMenu = new HubPopupForm(Config);
            BuildContextMenu();
            InitSlideTimers();
        }

        private void InitSlideTimers()
        {
            IdleTimer = new System.Windows.Forms.Timer();
            IdleTimer.Interval = 1800;
            IdleTimer.Tick += delegate {
                if (!IsDragging && !PopupMenu.Visible && Config.AutoSlideEdge)
                {
                    Point cursor = Cursor.Position;
                    if (!this.Bounds.Contains(cursor))
                    {
                        IdleTimer.Stop();
                        CollapseToEdge();
                    }
                }
            };

            SlideTimer = new System.Windows.Forms.Timer();
            SlideTimer.Interval = 15;
            SlideTimer.Tick += delegate {
                int diff = TargetX - this.Left;
                if (Math.Abs(diff) <= 4)
                {
                    this.Left = TargetX;
                    SlideTimer.Stop();
                    this.Invalidate();
                }
                else
                {
                    int step = diff / 2;
                    if (step == 0) step = diff > 0 ? 1 : -1;
                    this.Left += step;
                }
            };

            IdleTimer.Start();
        }

        private Screen GetCurrentScreen()
        {
            return Screen.FromPoint(new Point(this.Left + this.Width / 2, this.Top + this.Height / 2));
        }

        private bool IsRightSideOfScreen()
        {
            Screen scr = GetCurrentScreen();
            int center = scr.Bounds.Left + (scr.Bounds.Width / 2);
            return (this.Left + this.Width / 2) >= center;
        }

        private void CollapseToEdge()
        {
            Screen scr = GetCurrentScreen();
            IsDockedCollapsed = true;
            if (IsRightSideOfScreen())
            {
                TargetX = scr.Bounds.Right - PeekWidth;
            }
            else
            {
                TargetX = scr.Bounds.Left - (this.Width - PeekWidth);
            }
            SlideTimer.Start();
        }

        private void ExpandFromEdge()
        {
            Screen scr = GetCurrentScreen();
            IsDockedCollapsed = false;
            if (IsRightSideOfScreen())
            {
                TargetX = scr.WorkingArea.Right - this.Width;
            }
            else
            {
                TargetX = scr.WorkingArea.Left;
            }
            SlideTimer.Start();
        }

        private void UpdateTooltipText()
        {
            string state = Config.IsLocked ? "VERRIEGELT (Fest fixiert)" : "ENTRIEGELT (Frei verschiebbar)";
            OrbToolTip.SetToolTip(this, "Microsoft Ecosystem Hub [" + state + "]\n• Klick: MS 365, Rewards, Xbox & Inline-Learn-Suche\n• Schloss oben rechts: Position sperren/entsperren\n• Rechtsklick: Optionen");
        }

        private void BuildContextMenu()
        {
            ContextMenuStrip cms = new ContextMenuStrip();
            ToolStripMenuItem miLock = new ToolStripMenuItem("Position verriegeln / fixieren");
            miLock.Click += delegate { ToggleLock(); };

            ToolStripMenuItem miSlide = new ToolStripMenuItem("Automatisch seitlich einfahren");
            miSlide.Checked = Config.AutoSlideEdge;
            miSlide.Click += delegate {
                Config.AutoSlideEdge = !Config.AutoSlideEdge;
                miSlide.Checked = Config.AutoSlideEdge;
                Config.Save();
                if (Config.AutoSlideEdge) IdleTimer.Start();
                else ExpandFromEdge();
            };

            ToolStripMenuItem miTop = new ToolStripMenuItem("Immer im Vordergrund");
            miTop.Checked = Config.AlwaysOnTop;
            miTop.Click += delegate {
                Config.AlwaysOnTop = !Config.AlwaysOnTop;
                this.TopMost = Config.AlwaysOnTop;
                miTop.Checked = Config.AlwaysOnTop;
                Config.Save();
            };

            ToolStripMenuItem miExit = new ToolStripMenuItem("Microsoft Hub beenden");
            miExit.Click += delegate { Application.Exit(); };

            cms.Opening += delegate {
                miLock.Checked = Config.IsLocked;
                miSlide.Checked = Config.AutoSlideEdge;
            };

            cms.Items.Add(miLock);
            cms.Items.Add(miSlide);
            cms.Items.Add(miTop);
            cms.Items.Add(new ToolStripSeparator());
            cms.Items.Add(miExit);
            this.ContextMenuStrip = cms;
        }

        private void ToggleLock()
        {
            Config.IsLocked = !Config.IsLocked;
            Config.Save();
            UpdateTooltipText();
            this.Invalidate();
        }

        protected override void OnMouseEnter(EventArgs e)
        {
            base.OnMouseEnter(e);
            IsHovered = true;
            IdleTimer.Stop();
            if (IsDockedCollapsed)
            {
                ExpandFromEdge();
            }
            this.Invalidate();
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            base.OnMouseLeave(e);
            IsHovered = false;
            if (Config.AutoSlideEdge && !PopupMenu.Visible)
            {
                IdleTimer.Start();
            }
            this.Invalidate();
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button == MouseButtons.Left)
            {
                if (!IsDockedCollapsed && LockButtonRect.Contains(e.Location))
                {
                    ToggleLock();
                    return;
                }

                IsDragging = true;
                DidMove = false;
                DragStartPoint = e.Location;
            }
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            if (IsDragging && !Config.IsLocked)
            {
                int dx = Math.Abs(e.X - DragStartPoint.X);
                int dy = Math.Abs(e.Y - DragStartPoint.Y);
                if (dx > 3 || dy > 3)
                {
                    DidMove = true;
                    SlideTimer.Stop();
                    IsDockedCollapsed = false;
                    this.Location = new Point(this.Left + e.X - DragStartPoint.X, this.Top + e.Y - DragStartPoint.Y);
                }
            }
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            base.OnMouseUp(e);
            if (e.Button == MouseButtons.Left && IsDragging)
            {
                IsDragging = false;
                if (DidMove)
                {
                    Screen scr = GetCurrentScreen();
                    if (Config.AutoSlideEdge)
                    {
                        this.Left = IsRightSideOfScreen() ? (scr.WorkingArea.Right - this.Width) : scr.WorkingArea.Left;
                    }
                    Config.PosX = this.Left;
                    Config.PosY = this.Top;
                    Config.Save();
                    IdleTimer.Start();
                }
                else
                {
                    TogglePopupMenu();
                }
            }
        }

        private void TogglePopupMenu()
        {
            if (PopupMenu.Visible)
            {
                PopupMenu.Hide();
                IdleTimer.Start();
            }
            else
            {
                if (IsDockedCollapsed) ExpandFromEdge();
                PopupMenu.RefreshAccountBanner();
                Screen scr = GetCurrentScreen();
                Rectangle wa = scr.WorkingArea;

                int x = IsRightSideOfScreen() ? (wa.Right - PopupMenu.Width - 6) : (wa.Left + 6);
                int y = this.Bottom + 8;

                if (y + PopupMenu.Height > wa.Bottom)
                    y = this.Top - PopupMenu.Height - 8;
                if (y < wa.Top)
                    y = wa.Top + 8;

                PopupMenu.Location = new Point(x, y);
                PopupMenu.Show();
                PopupMenu.Activate();
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Graphics g = e.Graphics;
            g.SmoothingMode = SmoothingMode.AntiAlias;

            Color bg = IsHovered ? Color.FromArgb(48, 50, 56) : Color.FromArgb(32, 33, 36);
            g.Clear(bg);

            Color borderColor = Config.IsLocked ? Color.FromArgb(0, 164, 239) : Color.FromArgb(95, 99, 104);
            using (Pen borderPen = new Pen(borderColor, 2))
            {
                g.DrawRectangle(borderPen, 1, 1, this.Width - 2, this.Height - 2);
            }

            // 4-Farben Microsoft-Logo (so positioniert, dass bei PeekWidth=26 die linke Spalte Rot+Blau sichtbar bleibt)
            int boxSize = 18;
            using (SolidBrush bRed = new SolidBrush(Color.FromArgb(242, 80, 34)))
            using (SolidBrush bGreen = new SolidBrush(Color.FromArgb(127, 186, 0)))
            using (SolidBrush bBlue = new SolidBrush(Color.FromArgb(0, 164, 239)))
            using (SolidBrush bYellow = new SolidBrush(Color.FromArgb(255, 185, 0)))
            {
                g.FillRectangle(bRed,    6, 14, boxSize, boxSize);
                g.FillRectangle(bGreen,  28, 14, boxSize, boxSize);
                g.FillRectangle(bBlue,   6, 36, boxSize, boxSize);
                g.FillRectangle(bYellow, 28, 36, boxSize, boxSize);
            }

            // Verriegelungsschloss oben rechts (nur im ausgefahrenen Zustand sichtbar)
            if (!IsDockedCollapsed)
            {
                Color lockBg = Config.IsLocked ? Color.FromArgb(16, 124, 16) : Color.FromArgb(95, 99, 104);
                using (SolidBrush lb = new SolidBrush(lockBg))
                {
                    g.FillEllipse(lb, LockButtonRect);
                }

                using (Pen shacklePen = new Pen(Color.White, 1.6f))
                using (SolidBrush bodyBrush = new SolidBrush(Color.White))
                {
                    if (Config.IsLocked)
                        g.DrawArc(shacklePen, 49, 5, 6, 7, 180, 180);
                    else
                        g.DrawArc(shacklePen, 52, 4, 6, 7, 180, 180);
                    g.FillRectangle(bodyBrush, 48, 11, 8, 6);
                }
            }
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new LauncherOrbForm());
        }
    }
}
'@

$Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
$Params   = New-Object System.CodeDom.Compiler.CompilerParameters
$Params.GenerateExecutable = $true
$Params.OutputAssembly     = $ExePath
$Params.CompilerOptions    = "/target:winexe /optimize /win32icon:`"$IconPath`""
$Params.ReferencedAssemblies.AddRange(@(
    "System.dll",
    "System.Core.dll",
    "System.Net.dll",
    "System.Drawing.dll",
    "System.Windows.Forms.dll"
))

$Results = $Provider.CompileAssemblyFromSource($Params, $CSharpSource)

if ($Results.Errors.HasErrors) {
    Write-Host "Kompilierungsfehler aufgetreten:" -ForegroundColor Red
    foreach ($err in $Results.Errors) {
        Write-Host $err.ToString() -ForegroundColor Yellow
    }
} else {
    Write-Host "[3/3] Kompilierung erfolgreich! Starte MicrosoftEcosystemHub.exe..." -ForegroundColor Green
    Start-Process -FilePath $ExePath
}