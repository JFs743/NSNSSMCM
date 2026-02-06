# NSNSSMM

Non-Sucking "Non-Sucking Service Manager" Manager

Because NSSM kinda sucks, actually

## Preamble

This script is a wrapper for the good ol' nssm.exe and actually requires it. I found it very silly to have to open the cmd, then run a command just to open a GUI (`nssm install <ServiceName>`).
Running multiple commands with `nssm set <ServiceName> option value` isn't much better.

In my job, I find myself doing lots of service installs with similar configs and having to manually enter the same values over and over.
That's why I decided to make a tool to make installs more repeatable.

## Important note

NSNSSMM assumes a simple, predictable structure:

- `nssm.exe`, `nsnssmm.ps1`, and your service folders live under a common root (e.g. `C:\InstalledServices\`)
- Each service has its own folder named after the service
- Each service folder contains a `nsnssmm.json` file

Example:

```plaintext
C:\InstalledServices\
   ├─ nssm.exe
   ├─ nsnssmm.ps1
   ├─ MyService\
   │  ├─ nsnssmm.json
   │  └─ (app files here)
   └─ AnotherService\
      ├─ nsnssmm.json
      └─ (...)
```

This structure is opinionated, but it keeps things reproducible and predictable.
You can deviate — just don’t expect sympathy.

## Recommended setup

### Scenario 1: Creating a Service From Scratch (No Template)

If the service does not exist yet:

1. Create a folder named after your future service.
2. Place your application files inside (if applicable).
3. Run:

   `.\nsnssmm.ps1 -New -ServiceName "MyService" -ApplicationPath "C:\Path\To\App.exe" -AppParameters "-arg1 -arg2"`

This will:

- Install the service via NSSM
- Export its configuration to `./MyService/nsnssmm.json`
- Start the service

After this point, the JSON file becomes the source of truth.

You can now version-control it, copy it, or replicate it elsewhere.

### Scenario 2: Using an Existing Template (Recommended)

If you already have a working `nsnssmm.json`:

1. Create a folder named after the service.
2. Drop the `nsnssmm.json` file inside.
3. Run:

   `.\nsnssmm.ps1 -Import "MyService"`

This will:

- Create the service if it doesn’t exist
- Apply all stored settings
- Start the service

To fully rebuild from config:

   `.\nsnssmm.ps1 -Reset "MyService"`

This removes and recreates the service from the JSON definition.

---

### Scenario 3: Exporting Existing Services

If you created a service manually (using the GUI or CLI), you can bring it under NSNSSMM's control:

   `.\nsnssmm.ps1 -Export "MyService"`

This generates a `nsnssmm.json` for an existing NSSM-managed service.

Once exported, the configuration becomes portable and reproducible.

## Philosophy

The GUI is a bootstrap tool.
The JSON file is the truth.
The script is the enforcement layer.

If something changes, change the JSON.
If you want to be certain, use `-Reset`.

Clicking through dialogs repeatedly is not a deployment strategy.

## Special request

Someone please make a GUI wrapper and call it NSNSNSSMMM.
