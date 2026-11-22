# Project H0

H0 (Human Zero) is a native programming language for AI agents. Its Tape notation uses positional registers and compact Hangul instructions. Separate packed functions with a newline or `;;`. The [calendar example](examples/calendar.h0) fits five functions on one line.

H0 compiles its own compiler source on Windows and Linux x64. See [AGENTS.md](AGENTS.md) for the language reference, native build commands, standard library, and compiler entry points.

The Linux seed is a static ELF that calls the kernel directly. The Windows seed imports `KERNEL32.dll` for operating-system services. Both seeds run without a Python interpreter or C runtime.

The bootstrap compiler is split into [H0 modules](bootstrap/compiler), with [standard I/O](std/io.h0) shared by the compiler and applications. Run `sh bootstrap/rebuild.sh` on Linux or `.\bootstrap\rebuild.ps1` in Windows PowerShell to assemble the compiler sources and build both seeds with H0.

On Windows and Linux x64, `>+1` loads standard I/O. Use `:!42` to print a word in decimal or `:!\b"hello"` to print bytes. The compiler selects the output function from the operand type. Use `:ew` to write a byte view to stderr. The decimal encoder in `std/num.h0` is loaded automatically.

Load the H0 [formatting module](std/fmt.h0) and its decimal encoder with `>+8`. The module uses single-syllable slots `값` for unsigned decimal, `간` for signed decimal, and `개` for hexadecimal in byte templates.

The H0 [scanning module](std/scan.h0) reads those fields from a byte view into little-endian 64-bit words and checks their range.

On Windows and Linux x64 the [file module](std/fs.h0) provides open, read, write, close, seek, and append-only open (`:첨`). It also implements exact reads, complete writes, and file-to-file copying in H0. The [file example](examples/file.h0) takes a hex-encoded UTF-8 path and copies the file to stdout. Its `>+14` header tells the seed to load standard I/O and file operations from the repository.

Use `>+6` for the [arena allocator](std/arena.h0). It allocates aligned byte offsets in a caller-provided buffer and can rewind to a checkpoint. The [arena example](examples/arena.h0) runs on Windows, Linux, and raw RV64.

In one Windows x64 process benchmark, 8,000,019 aligned allocations with periodic rewind took a median of 109 ms in H0 and 30 ms in Rust 1.100.0 at `opt-level=3`. Both produced the same checksum. The executables were 9,216 and 137,728 bytes respectively.

Use `>+7` to include the [buffered stream module](std/stream.h0) and its file dependency. Pass mode `2` to `:s0` for append-only output. Use `:s6` to query the logical position without flushing and `:s7` to read exactly a destination buffer’s length. Use `:s8` to read through a delimiter, preserving unread bytes for the next call. A flush completes partial writes through the file module.

On Windows and Linux x64, `>+0` includes the [TCP module](std/net.h0). The same [echo example](examples/tcp.h0) builds on both targets, binds to loopback, prints its assigned port, and serves one connection. Windows uses the system Winsock DLL.

Use `>+2` for the [HTTP request framing module](std/http.h0). The [loopback example](examples/http.h0) uses `>+012` to receive one HTTP/1.1 request with a bounded Content-Length body.

```sh
mkdir -p build
bootstrap/seed/h0-linux-x64 1 < examples/file.h0 > build/file
chmod +x build/file
./build/file 524541444d452e6d64
```

On Windows, run these commands in `cmd.exe`.

```bat
if not exist build mkdir build
bootstrap\seed\h0-windows-x64.exe 0 < examples\file.h0 > build\file.exe
build\file.exe 524541444d452e6d64
```

Use seed mode `0` to build Windows PE, `1` to build Linux ELF, or `2` for raw RV64 code. For an English diagnostic before building, use modes `5`, `6`, and `7` for the same targets. All modes read the source from standard input. Check modes report success or an error code and message. When available, they also report the one-based function section and original line and column. Columns count Unicode scalars.

## Developer

Hyeonwoo Kim (kookmin20103324@gmail.com) created and maintains Project H0. Run either native compiler seed with argument `4` to display the author credit.

Licensed under [Apache 2.0](LICENSE).
