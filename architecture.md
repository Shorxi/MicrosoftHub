# 📘 architecture.md  
### *Technische Architektur – Microsoft Ecosystem Desktop Hub V1*

---

## 🟦 **Überblick**
Der **Microsoft Ecosystem Desktop Hub V1** ist ein kompakter Windows‑Launcher, der vollständig über ein PowerShell‑Build‑Script (`build.ps1`) generiert wird.  
Das Tool besteht aus **einem einzigen C#‑Quellcodeblock**, der zur Laufzeit kompiliert wird, sowie einer dynamisch erzeugten Icon‑Datei.

Es ist **kein klassisches Visual‑Studio‑Projekt**, sondern ein **self‑contained Build‑System**, das alles automatisch erzeugt.

---

## 🧩 **Architekturkomponenten**

### 🔹 **1. PowerShell‑Buildsystem (`build.ps1`)**
Das Build‑Script übernimmt:

- Erzeugung des Microsoft‑Icons (4‑Farben‑Quadrat)
- Schreiben des kompletten C#‑Quellcodes in eine temporäre Datei
- Kompilierung der EXE über `Add-Type` / `csc.exe`
- Platzierung der fertigen EXE auf dem Desktop
- Beenden alter Instanzen, damit die EXE überschrieben werden kann

Das Buildsystem ist der **Kern des Projekts**.

---

### 🔹 **2. C#‑Anwendung (dynamisch kompiliert)**
Der gesamte C#‑Code wird im Build‑Script als String gespeichert und kompiliert.  
Die Anwendung besteht aus mehreren Klassen:

#### **MSAccountDetector**
- Erkennung von Microsoft‑Konten (MSA / Entra ID)
- Registry‑Scan (`IdentityCRL`)
- Edge‑Profil‑Scan (`Local State`)
- Starten von URLs im Edge‑App‑Modus (`--app`)
- Unterstützung nativer Windows‑Protokolle (`ms-settings:` / `windowsdefender:`)

#### **InlineSearchEngine**
- Wikipedia Summary API  
- Microsoft Learn / Docs API  
- Bing News RSS  
- Bing Web Fallback  
- HTML‑Stripper  
- JSON‑Decoder  
- Stopword‑Cleaner  
- Ergebnisliste für Inline‑Suche

#### **AppItem**
- Struktur für App‑Kacheln (Name, Kategorie, URL, Badge, Farbe)

#### **HubPopupForm**
- Hauptfenster des Launchers  
- App‑Grid  
- Inline‑Search‑Ansicht  
- Account‑Banner  
- Rewards‑Button  
- Autostart‑Option  
- AppMode‑Option  
- Dark‑Mode Fluent‑UI

#### **LauncherOrbForm**
- Kleines Orb‑Fenster  
- Auto‑Slide‑Docking  
- AlwaysOnTop  
- Öffnet den Hub per Klick

#### **ConfigManager**
- Speichert Einstellungen in `settings.ini`:
  - Position  
  - AlwaysOnTop  
  - AppMode  
  - AutoSlideEdge  

---

## 🔹 **3. Icon‑Generator**
Das Icon wird im Build‑Script erzeugt:

- 64×64 Bitmap  
- Microsoft‑Farben (Rot, Grün, Blau, Gelb)  
- ICO‑Header manuell geschrieben  
- Speicherung im TEMP‑Ordner  

---

## 🔹 **4. Build‑Output**
Nach dem Build entsteht:

```
MicrosoftEcosystemHub.exe
ms_ecosystem_icon.ico
settings.ini (wird automatisch erzeugt)
```

---

## 🏗 **Projektstruktur (vereinfacht)**

```
MicrosoftEcosystemHub/
│
├── build/
│   └── build.ps1
│
├── README.md
├── architecture.md
├── LICENSE
└── .gitignore
```




