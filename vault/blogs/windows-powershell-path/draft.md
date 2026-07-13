---
date: 2026-07-08
author: koenig-ai-academy
ticket: KOEA-9619
vendor_tag: microsoft
content_type: explainer
title: "Windows PATH and PowerShell: How Command Resolution Actually Works"
slug: windows-powershell-path
tags:
  - powershell
  - windows
  - environment-variables
  - developer-tools
learning_objectives:
  - Understand how Windows resolves commands in PowerShell using the PATH environment variable
  - Add directories to PATH permanently at the system and user scope
  - Diagnose common PATH problems with PowerShell
whats_new:
  - Sequence diagram of Windows PATH resolution order for PowerShell commands and environment variable updates
description: "How Windows PATH resolution works in PowerShell: system vs user scope, how to add directories permanently, session snapshot behaviour, and commands to inspect and debug PATH entries."
seo_description: "Windows PATH and PowerShell: how PATH works, how to add directories permanently at user or system scope, and commands to diagnose common PATH problems."
faq:
  - question: "How do you permanently add a directory to PATH in Windows PowerShell?"
    answer: "To permanently add a directory to PATH at user scope, run: `[Environment]::SetEnvironmentVariable('PATH', \"$([Environment]::GetEnvironmentVariable('PATH','User'));C:\\MyDir\", 'User')`. This writes to the HKCU\\Environment registry key and persists across sessions [2]. For system-wide scope affecting all users, use 'Machine' instead of 'User' and run PowerShell as Administrator — this writes to HKLM\\SYSTEM\\...\\Environment. Open a new PowerShell window to see the change; running sessions do not automatically pick up registry updates."
  - question: "Why isn't my PATH change visible in the current PowerShell session?"
    answer: "When PowerShell starts, it reads the PATH environment variable once and stores it as a snapshot in the session's in-memory environment block (`$env:PATH`). Changes made via `[Environment]::SetEnvironmentVariable` update the registry (HKCU or HKLM) and broadcast WM_SETTINGCHANGE to notify applications, but running PowerShell processes do not automatically reload [1]. To pick up the change immediately without opening a new window, manually reload: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`."
  - question: "What is the difference between system PATH and user PATH in Windows?"
    answer: "Windows maintains two separate PATH registry entries. System PATH (stored in HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment, modifiable only by Administrators) applies to all users. User PATH (stored in HKCU\\Environment, modifiable by the current user) applies only to that user's sessions [2]. When a PowerShell session starts, Windows merges them — system PATH first, then user PATH — into the combined `$env:PATH`. A directory in user PATH can shadow a system PATH entry if it appears first in the merged result."
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
  - id: stance:ai-credential-files-underprotected
    engagement: neutral
first_60_words_answer: "When you type `python` in PowerShell and press Enter, Windows doesn't search your entire hard drive. It looks through a list of directories called PATH, in order, and runs the first executable it finds with that name. Understanding how PATH is structured — and how PowerShell reads and modifies it — eliminates a category of 'command not found' errors that stump most Windows users."
last_updated: 2026-07-13
hero_image:
  url: /img/blogs/windows-powershell-path/hero.png
  alt: "Sequence diagram showing Windows PATH resolution in PowerShell: HKLM system PATH and HKCU user PATH merging into the session environment block"
status: g0-passed
reading_time_min: 8
sources:
  - "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables"
  - "https://learn.microsoft.com/en-us/windows/win32/procthread/environment-variables"
  - "https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-string-substitutions"
  - "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_provider"
  - "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-command"
  - "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_registry_provider"
references:
  - n: 1
    title: "PowerShell Docs — About Environment Variables"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables"
    retrieved: 2026-07-08
  - n: 2
    title: "Windows Docs — Environment Variables"
    url: "https://learn.microsoft.com/en-us/windows/win32/procthread/environment-variables"
    retrieved: 2026-07-08
  - n: 3
    title: "PowerShell — String Substitutions Deep Dive"
    url: "https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-string-substitutions"
    retrieved: 2026-07-08
  - n: 4
    title: "PowerShell — About Environment Providers"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_provider"
    retrieved: 2026-07-13
  - n: 5
    title: "PowerShell — Get-Command"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-command"
    retrieved: 2026-07-09
  - n: 6
    title: "PowerShell — About Registry Provider"
    url: "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_registry_provider"
    retrieved: 2026-07-09
---

# Windows PATH and PowerShell: How Command Resolution Actually Works

When you type `python` in PowerShell and press Enter, Windows doesn't search your entire hard drive. It looks through a list of directories called PATH, in order, and runs the first executable it finds with that name. Understanding how PATH is structured — and how PowerShell reads and modifies it — eliminates a category of "command not found" errors that stump most Windows users.

## What Is PATH?

PATH is a Windows environment variable that holds a semicolon-separated list of directories. When you run a command without a full path, Windows searches each directory in the list left-to-right until it finds a matching `.exe`, `.cmd`, `.bat`, or `.ps1` file.

```
C:\Windows\System32;C:\Windows;C:\Program Files\Git\bin;C:\Users\You\AppData\Local\Microsoft\WindowsApps
```

PowerShell inherits PATH from two sources: the **system-wide** PATH (set in `HKLM` registry, applies to all users) and the **user-level** PATH (set in `HKCU` registry, applies to the current user). Windows merges them — user PATH is appended to system PATH — before exposing the combined result as `$env:PATH` inside your session.

That means PATH is not a database of installed programs. It is only a search list. If `C:\Tools` contains `ripgrep.exe` but `C:\Tools` is not in PATH, typing `ripgrep` fails even though the file exists. If you run `C:\Tools\ripgrep.exe` with the full path, PATH is bypassed entirely. The common mistake is reinstalling a tool when the real problem is that the directory containing the executable was never added to either user PATH or machine PATH.

The order matters as much as the contents. If two directories contain `python.exe`, the first matching directory in the merged PATH wins. A user-level Python installed under `C:\Users\You\AppData\Local\Programs\Python` can beat, or lose to, an older system-level Python depending on the final merged order. PowerShell's `Get-Command` is the fastest way to prove which executable actually wins because it resolves the command the way the shell will resolve it [5].

## How Windows Resolves a PowerShell Command

The diagram below traces what happens when you type a command in PowerShell.

```mermaid
sequenceDiagram
    title Windows PATH Resolution in PowerShell
    actor User
    participant PS as PowerShell
    participant ENV as Environment Block
    participant REG as Registry (HKLM + HKCU)
    participant FS as File System

    User->>PS: Type command (e.g. python)
    PS->>ENV: Read $env:PATH
    ENV->>REG: Load HKLM\SYSTEM\...\PATH (system scope)
    REG-->>ENV: System PATH string
    ENV->>REG: Load HKCU\Environment\PATH (user scope)
    REG-->>ENV: User PATH string
    ENV-->>PS: Combined PATH (system + user, semicolon-joined)
    loop Each directory in PATH order
        PS->>FS: Look for python.exe / python.cmd / python.bat
        FS-->>PS: Found? → execute and stop / Not found? → next dir
    end
    PS-->>User: Run executable or "not recognized" error
```

*Figure 1 — Windows PATH resolution sequence in PowerShell. System PATH loads first from the HKLM registry hive; user PATH loads from HKCU and is appended. PowerShell searches each directory in the merged list in order. The first match wins.*

**Key behaviour**: the session's `$env:PATH` is a snapshot taken when the PowerShell process started. Changes you make in another session (including via System Properties) are not visible until you open a new PowerShell window — unless you reload the variable explicitly.

## PowerShell Checks Shell Commands Before PATH

PATH is only one layer of PowerShell command resolution. Before PowerShell launches an external executable from PATH, it can resolve built-in command types such as aliases, functions, cmdlets, scripts, and applications. That is why `Get-Command` is more useful than manually reading `$env:PATH`: it reports the actual command type and source PowerShell will use [5].

For example, `where` in PowerShell may not behave like `where.exe` in `cmd.exe` because PowerShell has its own aliases and command discovery rules. When you need the external Windows executable, call it explicitly as `where.exe`. When you need to know whether a name is an alias, function, cmdlet, or external application, run:

```powershell
Get-Command where -All
Get-Command python -All
```

The `-All` flag is useful for shadowing bugs. It shows every command PowerShell can find with that name, not just the winner. If an old `node.exe` appears before the version you just installed, the fix is not "repair Node"; it is to move, remove, or correct the earlier PATH entry.

## How to View Your Current PATH

```powershell
# View the combined PATH (system + user merged)
$env:PATH -split ';'

# View system PATH only
[Environment]::GetEnvironmentVariable('PATH', 'Machine')

# View user PATH only
[Environment]::GetEnvironmentVariable('PATH', 'User')
```

The `-split ';'` converts the semicolon-delimited string into an array, making it easier to read and search.

<KnowledgeCheck
  question="What happens to a permanently added PATH entry when you run `[Environment]::SetEnvironmentVariable('PATH', '...', 'User')` while a PowerShell session is already open?"
  options={[
    "The current session immediately sees the new PATH entry",
    "The new entry is added to the current session and all future sessions",
    "The registry is updated, but the current session's $env:PATH is a snapshot — you need a new PowerShell window to see the change",
    "The command requires administrator rights to update user-scope PATH"
  ]}
  correctIndex={2}
  explanation="The session's `$env:PATH` is a snapshot taken when the PowerShell process started. `[Environment]::SetEnvironmentVariable` writes to the HKCU registry and broadcasts WM_SETTINGCHANGE to notify applications, but running PowerShell processes do not automatically reload. Open a new PowerShell window to pick up the change, or manually reload: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`."
/>

## Adding a Directory to PATH

### Temporary (current session only)

```powershell
$env:PATH += ";C:\MyTools"
```

This modifies the in-memory environment block for the current PowerShell process. It is lost when the session closes.

### Permanent (user scope, persists across sessions)

```powershell
$current = [Environment]::GetEnvironmentVariable('PATH', 'User')
[Environment]::SetEnvironmentVariable('PATH', "$current;C:\MyTools", 'User')
```

Changes at user scope write to `HKCU\Environment`. Windows broadcasts a `WM_SETTINGCHANGE` message so open applications can reload; PowerShell sessions that are already running will NOT automatically pick up the change. Open a new window to see it.

### Permanent (system scope, requires admin)

```powershell
# Run PowerShell as Administrator
$current = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
[Environment]::SetEnvironmentVariable('PATH', "$current;C:\SharedTools", 'Machine')
```

System scope writes to `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment`. This affects all users on the machine [6].

## Diagnosing PATH Problems

**Problem: `python` is not recognised**
```powershell
# Find where python.exe is hiding
Get-Command python -ErrorAction SilentlyContinue
# Check if it's in PATH at all
$env:PATH -split ';' | Where-Object { Test-Path "$_\python.exe" }
```

**Problem: wrong version of a tool is running**
```powershell
# See which python.exe wins the PATH race
Get-Command python | Select-Object -ExpandProperty Source
```

**Problem: a PATH change isn't visible in the current session**
```powershell
# Reload user PATH into current session without restarting
$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' +
            [Environment]::GetEnvironmentVariable('PATH','User')
```

**Problem: PATH is too long** (Windows has a 2048-character limit for user PATH in some tools)
```powershell
$env:PATH.Length
# If > 2000, audit and remove stale directories
$env:PATH -split ';' | Where-Object { -not (Test-Path $_) }
```

**Problem: PATH contains duplicates**
```powershell
$env:PATH -split ';' |
  Where-Object { $_ } |
  Group-Object |
  Where-Object Count -gt 1 |
  Select-Object Count, Name
```

Duplicates usually do not break command resolution, but they make PATH harder to reason about and waste space in the environment block. Remove duplicate entries from the user or machine scope that actually owns them instead of editing only `$env:PATH`, because `$env:PATH` changes disappear when the current process exits [1].

Stale entries are more important than duplicates. A deleted tool directory near the front of PATH forces every command lookup to test a location that can never match, and a stale entry can hide the real issue when a later installer adds the correct directory. A quick health check is to split PATH, drop empty strings, and test each directory:

```powershell
$env:PATH -split ';' |
  Where-Object { $_ } |
  Where-Object { -not (Test-Path $_) }
```

If this returns old SDK folders, deleted package-manager directories, or typoed paths, remove them from the user or machine scope where they are stored. That keeps the permanent PATH shorter, easier to audit, and less likely to hit older tools that still impose practical length limits.

**Problem: a directory contains spaces**
```powershell
[Environment]::SetEnvironmentVariable(
  'PATH',
  "$([Environment]::GetEnvironmentVariable('PATH','User'));C:\Program Files\My Tool\bin",
  'User'
)
```

Do not wrap PATH entries in quotes just because the directory has spaces. PATH is split on semicolons, not spaces. Quoting the directory can become part of the stored value and cause tool lookup bugs in programs that do not normalize entries the same way PowerShell does.

## Virtual Environments Change PATH Temporarily

Python virtual environments, Conda environments, Node version managers, and similar tools usually work by prepending a tool-specific directory to the current process PATH. That is intentional. Activating a Python virtual environment does not rewrite your permanent user PATH; it changes the current shell session so `python` resolves to the environment-local interpreter first.

You can see the effect directly:

```powershell
Get-Command python | Select-Object -ExpandProperty Source
.\.venv\Scripts\Activate.ps1
Get-Command python | Select-Object -ExpandProperty Source
```

Before activation, `python` may resolve to the Windows Store shim, a system install, or a user install. After activation, it should resolve under `.\.venv\Scripts\python.exe`. When you close the terminal or deactivate the environment, that temporary PATH prefix goes away because it was process-scoped, not registry-scoped [1].

This is also why "fixing" virtual environment PATH changes by writing `.venv\Scripts` into your permanent user PATH is usually wrong. It makes one project's interpreter leak into unrelated shells. Treat project environments as session-local state: activate them when you work in the project, then let the activation script manage the PATH prefix.

<KnowledgeCheck
  question="What PowerShell command tells you exactly which executable file will run when you type `python`?"
  options={[
    "`$env:PATH -split ';'` — lists all directories in PATH order",
    "`Get-Command python | Select-Object -ExpandProperty Source` — returns the full path of the winning executable",
    "`Test-Path python.exe` — checks if python.exe exists",
    "`Where-Object { Test-Path python.exe }` — filters PATH directories"
  ]}
  correctIndex={1}
  explanation="`Get-Command python | Select-Object -ExpandProperty Source` returns the full filesystem path of the python executable that wins the PATH resolution race. This is the fastest diagnostic for 'wrong version' problems — you see exactly which Python (system, venv, Anaconda, winget-installed) is first in PATH without manually inspecting every directory."
/>

## Environment Variable Scopes at a Glance

| Scope | Registry hive | Who can modify | When effective |
|---|---|---|---|
| Process | In-memory only | Current process | Immediately, current session |
| User | `HKCU\Environment` | Current user | New sessions |
| Machine (system) | `HKLM\SYSTEM\...\Environment` | Administrators | New sessions (all users) |

<Callout type="info">
PowerShell 7+ on Windows reads PATH the same way as Windows PowerShell 5.1. The `[Environment]::SetEnvironmentVariable` .NET method works identically in both [4]. If you use `winget` or `scoop` to install tools, they typically update the user PATH automatically — but you still need a new PowerShell window to see the change.
</Callout>

## Learn More

- [Claude Tool Use From Zero](/learn/claude-tool-use-from-zero) — build automation agents that run PowerShell commands via tool use.
- [Secure Coding With Claude](/learn/secure-coding-with-claude) — best practices for safe scripting, including environment variable handling.
