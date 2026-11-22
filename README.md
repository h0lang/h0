# Project H0

H0 (Human Zero) is a native programming language for AI agents. Its Tape notation uses positional registers and compact Hangul instructions. Separate packed functions with a newline or `;;`. The [calendar example](examples/calendar.h0) fits five functions on one line.

H0 compiles its own compiler source on Windows and Linux x64. See [AGENTS.md](AGENTS.md) for the language reference, native build commands, standard library, and compiler entry points.

The Linux seed is a static ELF that calls the kernel directly. The Windows seed imports `KERNEL32.dll` for operating-system services. Both seeds run without a Python interpreter or C runtime.

The bootstrap compiler is split into [H0 modules](bootstrap/compiler), with [standard I/O](std/io.h0) shared by the compiler and applications. Run `sh bootstrap/rebuild.sh` on Linux or `.\bootstrap\rebuild.ps1` in Windows PowerShell to assemble the compiler sources and build both seeds with H0.

On Windows and Linux x64, `std/io.h0` provides separate stdout and stderr writes. Call `:wr` for stdout or `:ew` for stderr, passing a byte view.

The H0 [formatting module](std/fmt.h0) uses single-syllable slots `값` for unsigned decimal, `간` for signed decimal, and `개` for hexadecimal in byte templates.

The H0 [scanning module](std/scan.h0) reads those fields from a byte view into little-endian 64-bit words and checks their range.

On Windows and Linux x64 the [file module](std/fs.h0) provides open, read, write, close, and seek. The [file example](examples/file.h0) takes a hex-encoded UTF-8 path and copies the file to stdout.

Append the [buffered stream module](std/stream.h0) with `std/fs.h0` to use caller-owned read and write buffers. The stream position accounts for unread buffered bytes.

```sh
mkdir -p build
cat examples/file.h0 std/fs.h0 std/io.h0 | bootstrap/seed/h0-linux-x64 1 > build/file
chmod +x build/file
./build/file 524541444d452e6d64
```

On Windows, run these commands in `cmd.exe`.

```bat
if not exist build mkdir build
copy /b /y examples\file.h0+std\fs.h0+std\io.h0 build\file.h0
bootstrap\seed\h0-windows-x64.exe 0 < build\file.h0 > build\file.exe
build\file.exe 524541444d452e6d64
```

Use seed mode `0` to build Windows PE, `1` to build Linux ELF, or `2` for raw RV64 code. For an English diagnostic before building, use modes `5`, `6`, and `7` for the same targets. All modes read the source from standard input. Check modes report success or an error code and message. When available, they also report the one-based function section and original line and column. Columns count Unicode scalars.

## Developer

Hyeonwoo Kim (kookmin20103324@gmail.com) created and maintains Project H0. Run either native compiler seed with argument `4` to display the author credit.

Licensed under [Apache 2.0](LICENSE).
