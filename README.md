# Project H0

H0 (Human Zero) is a self-hosted native programming language for AI agents. Tape uses positional registers and compact Hangul instructions. H0 aims to reduce the total tokens an agent spends reading, writing, testing, and repairing code.

## Quickstart

Clone the repository and run these commands from its root. The bundled native compiler can build the calendar example directly.

**Windows x64** in Command Prompt

```bat
bootstrap\seed\h0-windows-x64.exe 0 < examples\calendar.h0 > calendar.exe
calendar.exe 2026
```

**Linux x64**

```sh
bootstrap/seed/h0-linux-x64 1 < examples/calendar.h0 > calendar
chmod +x calendar
./calendar 2026
```

## Toolchain and documentation

- Rebuild the Windows and Linux compiler binaries from H0 source with `.\bootstrap\rebuild.ps1` in Windows PowerShell or `sh bootstrap/rebuild.sh` on Linux. [Bootstrap modules](bootstrap/modules.txt)
- For agents writing or editing H0, use the editing guide, the compact Tape reference, and the full language and library contracts. [EDIT.md](EDIT.md) · [CORE.md](CORE.md) · [AGENTS.md](AGENTS.md)
- Explore the standard library and example programs. [Standard library](std/) · [Examples](examples/)
- Review the project’s recorded measurements and grading results. [Benchmark records](benchmarks/)

## Developer and license

Created and maintained by Hyeonwoo Kim (kookmin20103324@gmail.com). Licensed under [Apache 2.0](LICENSE).
