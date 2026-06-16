# Kansa Incident Response Toolkit

Kansa is a PowerShell-based incident response and live-response toolkit for Windows environments. This repository includes a GUI launcher, local and remote run handlers, collection modules, saved response configurations, and analysis helpers for packaging results into a repeatable workflow.

This project is a fork of [davehull/kansa](https://github.com/davehull/kansa), with local updates for this repository's workflows and packaging needs.

## What This Project Provides

- A Windows GUI launcher for local or remote incident response runs.
- Saved module configurations for common collection scenarios.
- Local host collection through `Run-KansaLocal.ps1`.
- Remote host collection through `Run-KansaRemoteHost.ps1` and WinRM.
- Module output cleanup, formatting, and archive creation.
- A third-party binary installer so vendor tools do not need to be committed to the repository.

## Repository Layout

```text
.
+-- Analysis/                         # Analysis scripts and report helpers
+-- Modules/                          # Kansa collection modules
|   +-- bin/                          # Third-party tools restored by installer script
+-- ToolBox/                          # Saved configs, host lists, and supporting scripts
+-- Kansa_GUI.ps1                     # PowerShell GUI launcher
+-- kansa.ps1                         # Core Kansa runner
+-- Run-KansaLocal.ps1                # Local collection handler
+-- Run-KansaRemoteHost.ps1           # Remote collection handler
+-- Install-KansaThirdPartyBinaries.ps1
```

## Requirements

- Windows PowerShell 5.1 or newer.
- Administrator privileges for most collection workflows.
- WinRM/PowerShell Remoting enabled for remote host collection.
- Internet access when running `Install-KansaThirdPartyBinaries.ps1`.

## Setup

Clone the repository, then restore the third-party helper tools:

```powershell
.\Install-KansaThirdPartyBinaries.ps1 -Force
```

The installer downloads supported tools from their upstream sources and places them in the paths expected by the existing modules, including:

- `7z.exe` and `7z.dll` in the repository root.
- Tool binaries under `Modules\bin`.
- `pii.zip` for PII audit modules.

Memoryze is not downloaded automatically because its vendor download flow does not provide a stable direct URL. If you have downloaded it separately, run:

```powershell
.\Install-KansaThirdPartyBinaries.ps1 -Force -MemoryzeZipPath C:\Downloads\memoryze.zip
```

## Running Kansa

### GUI Mode

Run the PowerShell GUI:

```powershell
.\Kansa_GUI.ps1
```

From the GUI, choose:

- Local computer or remote host collection.
- Single remote host or host list.
- A saved module configuration.
- `Start Kansa` to begin collection.

### Kansa GUI
![Kansa GUI](https://github.com/ArronJablonowski/Kansa/blob/master/ToolBox/MoreKansaScripts/GUI.png?raw=true)

### Kansa CLI Output (when launched from GUI)
![Kansa CLI](https://github.com/ArronJablonowski/Kansa/blob/master/ToolBox/MoreKansaScripts/CLI.png?raw=true)



### Local Collection

```powershell
.\Run-KansaLocal.ps1
```

### Remote Collection

Create or select a host list, then run:

```powershell
.\Run-KansaRemoteHost.ps1
```

Remote collection requires working WinRM connectivity and administrative privileges on the target hosts.

## Results

Kansa writes collection output to an `Output_*` directory during execution. Near completion, results are archived and moved to:

```text
.\Results\
```

The runner prefers 7-Zip when available. If 7-Zip is unavailable or fails, it falls back to Windows native ZIP compression through `Compress-Archive`.

## Third-Party Tools

Third-party binaries are intentionally excluded from Git by `.gitignore`. Use `Install-KansaThirdPartyBinaries.ps1` to restore them locally.

### Required Third-Party Binaries

The current Kansa modules expect these helper binaries to exist in the paths below. The installer script downloads and places most of them automatically, but they can also be downloaded manually from the listed sources.

| Tool | Manual Download | Expected Project Location |
|---|---|---|
| 7-Zip console files: `7z.exe`, `7z.dll` | [7-Zip download page](https://www.7-zip.org/download.html) | `.\7z.exe`, `.\7z.dll`, `.\Modules\bin\7z.exe`, `.\Modules\bin\7z.dll` |
| 7-Zip helper package: `7z.zip` | Built from `7z.exe` and `7z.dll` by `Install-KansaThirdPartyBinaries.ps1` | `.\Modules\bin\7z.zip` |
| Sysinternals Autoruns: `autorunsc.exe`, `autorunsc64.exe` | [Autoruns for Windows](https://learn.microsoft.com/en-us/sysinternals/downloads/autoruns) | `.\Modules\bin\autorunsc.exe`, `.\Modules\bin\autorunsc64.exe` |
| Sysinternals DU: `du.exe`, `du64.exe` | [DU for Windows](https://learn.microsoft.com/en-us/sysinternals/downloads/du) | `.\Modules\bin\du.exe`, `.\Modules\bin\du64.exe` |
| Sysinternals Handle: `handle.exe`, `handle64.exe` | [Handle](https://learn.microsoft.com/en-us/sysinternals/downloads/handle) | `.\Modules\bin\handle.exe`, `.\Modules\bin\handle64.exe` |
| Sysinternals ProcDump: `procdump.exe` | [ProcDump](https://learn.microsoft.com/en-us/sysinternals/downloads/procdump) | `.\Modules\bin\procdump.exe` |
| Sysinternals PsList: `pslist.exe` | [PsTools](https://learn.microsoft.com/en-us/sysinternals/downloads/pstools) | `.\Modules\bin\pslist.exe` |
| Sysinternals Sigcheck: `sigcheck.exe`, `sigcheck64.exe` | [Sigcheck](https://learn.microsoft.com/en-us/sysinternals/downloads/sigcheck) | `.\Modules\bin\sigcheck.exe`, `.\Modules\bin\sigcheck64.exe` |
| Sysinternals Streams: `streams.exe` | [Streams](https://learn.microsoft.com/en-us/sysinternals/downloads/streams) | `.\Modules\bin\streams.exe` |
| NirSoft BrowserAddonsView: `BrowserAddonsView.exe` | [BrowserAddonsView](https://www.nirsoft.net/utils/web_browser_addons_view.html) | `.\Modules\bin\BrowserAddonsView.exe` |
| NirSoft BrowsingHistoryView: `BrowsingHistoryView.exe` | [BrowsingHistoryView](https://www.nirsoft.net/utils/browsing_history_view.html) | `.\Modules\bin\BrowsingHistoryView.exe` |
| Eric Zimmerman AppCompatCacheParser: `AppCompatCacheParser.exe` | [Eric Zimmerman's Tools](https://ericzimmerman.github.io/) | `.\Modules\bin\AppCompatCacheParser.exe` |
| WinPmem: `winpmem-2.1.post4.exe` | [WinPmem releases](https://github.com/Velocidex/WinPmem/releases) | `.\Modules\bin\winpmem-2.1.post4.exe` |
| Xpdf pdftotext: `pdftotext.exe` | [XpdfReader downloads](https://www.xpdfreader.com/download.html) | `.\Modules\bin\pdftotext.exe` |
| PII helper package: `pii.zip` | Built from `7z.exe`, `7z.dll`, and `pdftotext.exe` by `Install-KansaThirdPartyBinaries.ps1` | `.\Modules\bin\pii.zip` |
| Memoryze: `memoryze.zip` | [FireEye/Trellix Market Memoryze](https://fireeye.market/apps/211368) | `.\Modules\bin\memoryze.zip` |

When installing manually, preserve the exact filenames shown above. Several modules copy these files into `$env:SystemRoot` during execution and expect the names to match.

## GitHub Hygiene

The repository is configured to avoid committing generated or sensitive operational files such as:

- `hostlist*`
- `Output*`
- `Results/`
- Third-party binaries restored into `Modules\bin`

Before publishing, run a final scan for local data, host lists, credentials, and generated archives.

## Notes

Some modules depend on optional Windows logs, registry locations, or vendor tools. Where possible, modules report missing logs or missing parameters as warnings instead of throwing noisy PowerShell errors.

## Disclaimer

This toolkit is intended for authorized incident response, system administration, and defensive security work. Review and test modules in a controlled environment before using them in production.
