# Project H0

H0 (Human Zero) is a native programming language for AI agents. Its Tape notation uses positional registers, one line per function, and compact Hangul instructions.

H0 compiles its own compiler source on Windows and Linux x64. See [AGENTS.md](AGENTS.md) for the language reference, native build commands, standard library, and compiler entry points.

The Linux seed is a static ELF that calls the kernel directly. The Windows seed imports `KERNEL32.dll` for operating-system services. Both seeds run without a Python interpreter or C runtime.

The bootstrap compiler is split into [H0 modules](bootstrap/compiler), with [standard I/O](std/io.h0) shared by the compiler and applications. Run `sh bootstrap/rebuild.sh` on Linux or `.\bootstrap\rebuild.ps1` in Windows PowerShell to assemble the compiler sources and build both seeds with H0.

Use seed mode `0` to build Windows PE, `1` to build Linux ELF, or `2` for raw RV64 code. For an English diagnostic before building, use modes `5`, `6`, and `7` for the same targets. All modes read the source from standard input. Check modes report success or an error code with a message and the function section when available.

## Developer

Hyeonwoo Kim (kookmin20103324@gmail.com) created and maintains Project H0. Run either native compiler seed with argument `4` to display the author credit.

Licensed under [Apache 2.0](LICENSE).
