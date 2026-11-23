# Project H0

H0 prioritizes reducing the total tokens AI agents use to complete programming tasks. Compare prompt and guide input, code, reasoning, and repair through a passing result on the same tasks. Track native runtime, binary size, and build time separately.

H0 (Human Zero) is a native programming language for AI agents. Its Tape notation uses positional registers and compact Hangul instructions. Separate packed functions with a newline or `;;`. The [calendar example](examples/calendar.h0) fits five functions on one line.

H0 compiles its own compiler source on Windows and Linux x64. See [AGENTS.md](AGENTS.md) for the language reference, native build commands, standard library, and compiler entry points.

For an agent editing an existing program, supply [CORE.md](CORE.md), the program's source, and its scoped glyph records. Run `bootstrap/seed/h0-linux-x64 19 < examples/calendar.h0` on Linux or `bootstrap\seed\h0-windows-x64.exe 19 < examples\calendar.h0` in Windows `cmd.exe`. The compact map is described below. For the selected standard-library contracts, run mode `20` for Windows, `21` for Linux, or `22` for RV64 with the source on stdin. Each mode reads `AGENTS.md` in the repository root and prints only the imported modules and their implicit dependencies for that target. Use check modes `5`, `6`, or `7` to validate target support and source syntax. Use the full guide for extended syntax.

For edits restricted to particular functions, run either native compiler with mode `23` and the original file on stdin. Each output row gives the zero-based section ordinal, inclusive start byte, exclusive end byte, and function name, separated by spaces. `-` marks an unnamed section. Offsets address the original UTF-8 bytes, including in `;;`-packed files. Imports are skipped, so the caller can read them separately if needed. This mode locates sections in one file. It can index a section with unfinished instructions when its header and boundaries are intact. Use the check modes for validation. On a boundary error it reports `E111` and exits with status 2. Discard output after any nonzero exit.

In `o200k_base`, sending the range list and just the file-picker function for the Windows viewer costs 380 tokens, compared with 2,307 for the complete source. Across five files with one function selected per file, input fell from 7,956 to 1,602 tokens. These counts cover the supplied source and range lists. Task success and reasoning tokens require separate measurement.

When the requested function is already known, use mode `24`. Put its exact name or zero-based section ordinal on the first stdin line, followed by the original H0 file. The compiler writes the selected original bytes followed by LF. Use ordinals for unnamed sections or to select among duplicate names. A missing or ambiguous selector reports `E112` and exits with status 2. The excerpt omits imports and other sections, so retain the original file for builds and edits that use numeric or relative calls.

```sh
(printf 'vf\n'; cat examples/bmp-viewer.h0) | bootstrap/seed/h0-linux-x64 24
```

When the function name is unknown, mode `27` lists only the section ordinal and name, one pair per line. It skips imports and unnamed sections and preserves the original ordinals, including when a name occurs more than once. Pass the chosen ordinal to mode `24`. Use mode `23` when you need unnamed sections or byte offsets. Both listing modes use the same scanner and diagnostics.

Across the 11 public examples with named sections, the lists alone fell from 496 to 157 tokens in both `o200k_base` and `cl100k_base`. For the Windows image viewer the list fell from 147 to 48 tokens.

With the selector handled by the calling tool, the same five excerpts cost 877 input tokens in `o200k_base`, including the trailing LF of each excerpt. The viewer's file picker costs 234 tokens.

Mode `28` applies one replacement to the original source. Send `selector LF byteCount LF replacement LF source` on stdin. Use the same name or ordinal as in mode `24`. Count UTF-8 bytes in the replacement and send the exact section bytes, excluding any trailing separator. The compiler writes the patched source to stdout and preserves every byte outside the replaced section. Discard output on a nonzero exit and run the target check (mode `5`, `6`, or `7`) before using a successful result.

For a one-function edit in each of 11 examples, returning the middle named section instead of the whole file would take 998 instead of 6,453 output tokens in `o200k_base`, and 1,007 instead of 6,503 in `cl100k_base`. These counts use the original section text as a proxy for the replacement, with one trailing LF. They exclude instructions, reasoning, and repair.

For the 21 public examples with standard-library imports, the complete native standard-library contract table costs 2,666 tokens in `o200k_base` and 2,685 in `cl100k_base`. Target-specific output had medians of 272 and 281. With one copy each of CORE, source, and compact glyph map per example, replacing the full contract table with the scoped output reduced summed input from 89,047 to 39,770 and from 89,617 to 40,052 respectively. The comparison counts supplied reference and source text.

In the scoped guide benchmark across 19 public examples, the median input for the full guide and source was 6,832 tokens in `o200k_base`, compared with 1,154 for CORE, glyph records, and source. In `cl100k_base` the median went from 7,265 to 1,165. These figures count reference and source input.

On both native seeds, mode `17` packs selected standard-library calls whose repetition can offset the cost of a glyph record. It also packs remaining calls when the source already uses that alias. Mode `18` packs every mapped call and suits agents that already have the alias definitions. Both modes read H0 from stdin and emit H0 on stdout. Use mode `19` on the result for a compact map, or mode `10` for individually quoted records.

Across the 20 public examples, mode `17` reduced source plus per-file glyph records from 5,460 to 5,427 tokens in `o200k_base` and from 5,513 to 5,504 in `cl100k_base`. Mode `18` reduced source alone from 5,087 to 4,905 and from 5,125 to 5,076 respectively. With fresh per-file glyph records, mode `18` increased the totals to 5,565 and 5,793. The measurements count input text.

Mode `19` returns two LF-terminated rows. The first maps code glyphs and the second maps escaped Hangul inside byte literals. Each Hangul syllable starts a record whose ASCII expansion continues until the next syllable or the end of the row. Tabs are literal. Backslashes, newlines, carriage returns, and other control bytes use `\\`, `\n`, `\r`, and `\xHH` respectively. Empty rows have no records.

For the 20 public examples in separate sessions, one copy of CORE, the source, and its glyph map per example totaled 27,460 tokens with quoted maps and the previous CORE, and 27,089 with compact maps and the shortened CORE in `o200k_base`. In `cl100k_base` the totals were 27,633 and 27,255. These are input token counts.

The Linux seed is a static ELF that calls the kernel directly. The Windows seed imports `KERNEL32.dll` for operating-system services. Both seeds run without a Python interpreter or C runtime.

The bootstrap compiler is split into [H0 modules](bootstrap/compiler), with [standard I/O](std/io.h0) shared by the compiler and applications. Run `sh bootstrap/rebuild.sh` on Linux or `.\bootstrap\rebuild.ps1` in Windows PowerShell to assemble the compiler sources and build both seeds with H0.

On Windows and Linux x64, `>+1` loads standard I/O. Use `:!42` to print a word in decimal or `:!\b"hello"` to print bytes. The compiler selects the output function from the operand type. Use `:ew` to write a byte view to stderr. The decimal encoder in `std/num.h0` is loaded automatically.

Load the H0 [formatting module](std/fmt.h0) and its decimal encoder with `>+8`. The module uses single-syllable slots `값` for unsigned decimal, `간` for signed decimal, and `개` for hexadecimal in byte templates.

The H0 [scanning module](std/scan.h0) reads those fields from a byte view into little-endian 64-bit words and checks their range.

On Windows and Linux x64 the [file module](std/fs.h0) provides open, read, write, close, seek, and append-only open (`:첨`). Use `:편` for read-write access that preserves file contents. Its second argument is `0` to open an existing file or `1` to create the file if absent. It also implements exact reads, complete writes, and file-to-file copying in H0. The [file example](examples/file.h0) takes a hex-encoded UTF-8 path and copies the file to stdout. Its `>+14` header tells the seed to load standard I/O and file operations from the repository.

Use `>+a` to load file replacement and its file module dependency. Call `:f3<TAB>ab` with path bytes and contents on Windows or Linux x64. It writes and syncs a sibling temporary file before renaming. It returns the byte count or Max and rejects directories and symbolic links. The [example](examples/replace.h0) accepts a hex-encoded path and contents.

```sh
mkdir -p build
bootstrap/seed/h0-linux-x64 1 < examples/replace.h0 > build/replace
chmod +x build/replace
./build/replace 6275696c642f6e6f74652e747874 48300a
```

```bat
if not exist build mkdir build
bootstrap\seed\h0-windows-x64.exe 0 < examples\replace.h0 > build\replace.exe
build\replace.exe 6275696c642f6e6f74652e747874 48300a
```

Use `>+6` for the [arena allocator](std/arena.h0). It allocates aligned byte offsets in a caller-provided buffer and can rewind to a checkpoint. The [arena example](examples/arena.h0) runs on Windows, Linux, and raw RV64.

In one Windows x64 process benchmark, 8,000,019 aligned allocations with periodic rewind took a median of 109 ms in H0 and 30 ms in Rust 1.100.0 at `opt-level=3`. Both produced the same checksum. The executables were 9,216 and 137,728 bytes respectively.

Use `>+7` to include the [buffered stream module](std/stream.h0) and its file dependency. Pass mode `2` to `:s0` for append-only output. Modes `3` and `4` allow buffered reads and in-place writes on the same stream. Mode `4` also creates a missing file. Switching to writes discards read-ahead after restoring the logical position. Switching to reads flushes pending writes. Use `:s6` to query the logical position without flushing and `:s7` to read exactly a destination buffer’s length. Use `:s8` to read through a delimiter, preserving unread bytes for the next call. A flush completes partial writes through the file module.

On Windows and Linux x64, `>+0` includes the [TCP module](std/net.h0). The same [echo example](examples/tcp.h0) builds on both targets, binds to loopback, prints its assigned port, and serves one connection. Windows uses the system Winsock DLL.

Use `>+b` for outbound IPv4 TCP. `:n1<TAB>ab` opens a blocking connection to address word `a` and port `b` in 1–65535, returning a socket or Max. The first IPv4 octet occupies the high byte. The [HTTP client example](examples/connect.h0) accepts the decimal address word and port. For a local peer, pass `2130706433` and its listening port.

On Linux x64, load `>+o` for [Unix-domain streams](std/unix-linux.h0). Call `:u0` with a pathname of 1–107 bytes without NUL or an abstract address of 1–108 bytes beginning with NUL. It returns a connected blocking descriptor or `u64::MAX`. Use `:n0` to send, `:찬` to receive, and `:찍` to close. [Unix socket interface](https://man7.org/linux/man-pages/man7/unix.7.html)

The [X11 probe](examples/x11-probe.h0) uses that module to connect to a local display. Its stdin contains one address-length byte, the address bytes, and an optional 16-byte `MIT-MAGIC-COOKIE-1` value. It prints the X11 version after the server accepts the setup request. [X11 connection setup](https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.html)

Load `>+p` for [native X11 windows](std/x11-linux.h0) on Linux x64. `:x0` takes a dedicated connected Unix descriptor, an empty or 16-byte authorization view, top-down BGRX8 pixels, and the dimensions packed as width in the high 32 bits and height in the low 32 bits. It displays an original-size window, repaints after exposure, and returns zero on close. The caller closes the descriptor. The display must support a little-endian 24-bit TrueColor root with 32-bit pixels. [X11 requests and pixel formats](https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.html)

Use `>+c` for DNS over TCP on Windows and Linux x64. Call `:d0<TAB>abcd` with the resolver's IPv4 word and port, a 16-bit query ID, and an ASCII hostname. It returns an IPv4 word or Max. It validates the response against the question and follows up to 15 CNAME hops in the answer. The [hostname client](examples/connect-name.h0) accepts the resolver address word, resolver TCP port, HTTP port, and hex-encoded hostname.

Use `>+k` for nonblocking TCP and socket readiness on Windows and Linux x64. Call `:n3(socket, 1)` to enable nonblocking mode or pass `0` to restore blocking mode. `:n4` reads once, `:n5` sends once, and `:n6` accepts a nonblocking socket from a nonblocking listener. Reads and sends can return partial counts. The top three u64 values indicate failure, would-block, and interruption, in descending order.

`:n2` waits for readiness and returns the number of rows with events. It takes up to 1,024 contiguous 16-byte records and a timeout in milliseconds. Use `0` to return immediately or `u64::MAX` to wait indefinitely. An empty or fully disabled set returns immediately. Each row stores a little-endian u64 socket at byte 0, a u16 interest mask at byte 8, and the returned u16 event mask at byte 10. Interest bits are `1` for read and `2` for write. Event bits also include `4` for hangup, `8` for error, and `16` for an invalid socket when the OS reports it. Set the socket field to `u64::MAX` to disable a row. [Linux poll](https://www.man7.org/linux/man-pages/man2/poll.2.html) and [Winsock WSAPoll](https://learn.microsoft.com/en-us/windows/win32/api/winsock2/nf-winsock2-wsapoll).

The [polling HTTP example](examples/http-poll.h0) binds to an ephemeral IPv4 loopback port and prints it. It handles up to eight clients with one event loop, reads complete requests up to 8 KiB, and closes each connection after its response. It closes connections after five seconds without I/O progress or fifteen seconds from acceptance.

Load `>+l` for monotonic time on Windows and Linux x64. `:t0` returns milliseconds from a system-dependent origin, excluding suspend. `:t1` sleeps for a relative duration up to 2,147,483,647 ms. `:t2` sleeps until an absolute deadline in the same clock. An expired deadline returns immediately. Both sleep calls return zero on success, and all three calls return `u64::MAX` on failure. Actual wake time depends on scheduling. [Linux monotonic clock and sleep](https://man7.org/linux/man-pages/man2/clock_nanosleep.2.html) and [Windows unbiased interrupt time](https://learn.microsoft.com/en-us/windows/win32/sysinfo/interrupt-time).

Load `>+j` for [JSON](std/json.h0). Parse UTF-8 once into a caller-owned tape with `:j0`. Each 16-byte record contains four little-endian u32 fields for the source start, exclusive source end, index after the subtree, and kind. Root is node 0. Object keys and values alternate in the tape. Use `:j2` to look up a UTF-8 key, `:j3` for a zero-based array index, and `:j5` for the source span. Pass the used portion of the tape to all three functions. Numbers stay exact in the source, including exponent notation. `:j1` decodes a quoted string and `:j4` quotes UTF-8. The parser supports up to 64 nested containers with a constant call stack and rejects malformed UTF-8 and unpaired surrogate escapes. [JSON specification](https://www.rfc-editor.org/rfc/rfc8259).

This two-line program prints the exact source text for the value associated with `n`.

```text
>+1j
0 a\b"{\"n\":42}" bM48 c:j0	ab ?Ec수.2 d:j2	aVb0*c16	0\b"n" ?Ed수.3 e:j5	Vb0*c16d Y:wr	VaTe32&e4294967295 :fl
```

Load `>+e` for the [BMP decoder](std/bmp.h0). It reads uncompressed 24-bit BGR and 32-bit BGRX BMP images with DIB headers of at least 40 bytes. It handles bottom-up and top-down rows and strips row padding. Call `:p0` with a byte view to validate the image and get the width in the high 32 bits and height in the low 32 bits. Call `:p1` with the image and a disjoint writable buffer to decode packed RGB8 in top-down row order. Both return zero on failure.

Load `>+h` for [DEFLATE and zlib decoding](std/deflate.h0). `:z0` reads raw DEFLATE and `:z1` reads a zlib stream and verifies Adler-32. Both take the compressed byte view and a disjoint writable output view and return the decoded length or `u64::MAX`. Each call expects exactly one stream. The decoder rejects preset dictionaries, truncated input, trailing bytes, and short output buffers. Discard output on failure. The same H0 module builds for Windows x64, Linux x64, and RV64. [DEFLATE specification](https://www.rfc-editor.org/rfc/rfc1951) and [zlib specification](https://www.rfc-editor.org/rfc/rfc1950).

Load `>+i` for the [PNG decoder](std/png.h0). It reconstructs noninterlaced and Adam7 grayscale, RGB, indexed, grayscale-alpha, and RGBA images at all legal sample depths. It checks every chunk CRC, combines split IDAT payloads, and decodes transparency from alpha samples or the transparency chunk. [PNG specification](https://www.w3.org/TR/png-3/).

Call `:q0` with the file bytes to read the checked header and return the width in the high 32 bits and height in the low 32 bits. `:q2` returns the required scratch capacity. Call `:q1` with the file, disjoint scratch, and a disjoint pixel buffer of at least `4 * width * height` bytes. It returns the dimensions and fills packed top-down BGRA8 with straight alpha. Zero means failure. Discard output on failure. Windows and Linux x64 and RV64 use the same module.

The [BMP example](examples/bmp.h0) builds for Windows and Linux x64. It takes a hex-encoded UTF-8 file path and writes a binary PPM image to standard output. The example accepts files up to 120 KiB. The decoder uses the caller's buffer sizes.

The [Win32 module](std/win.h0) is available with `>+f` on Windows x64. It opens a system DLL by its null-terminated UTF-16LE basename, looks up an ASCII export by its null-terminated name, and calls scalar or pointer signatures using sixteen little-endian 64-bit argument slots. Zero unused slots. A buffer address returned by the module is valid while the caller keeps that buffer live. Release DLL handles after the last call.

On Windows and Linux x64, load `>+g` for [operating-system memory](examples/memory.h0). Call `:m0` with the byte count for a zero-initialized region and `:m1` with its address and original size to release it. Allocation returns zero on failure. The binding `b\!an` gives a fresh mutable byte view `b` of the address `a` and length `n`. Byte accesses are bounds-checked. The caller must provide a live, exclusive memory range and end all accesses through the view before releasing that range.

Load `>+m` for the [u64 map](std/map.h0) on Windows x64, Linux x64, or RV64. Supply a writable buffer of exactly `8+17n` bytes, where `n` is a power of two and at least 4. Initialize or reset it with `:k0`. The map holds up to `3n/4` entries and accepts every u64 key and value. Insert or update with `:k1`, read into an eight-byte output view with `:k2`, remove with `:k3`, and count with `:k4`. The library uses the caller's buffer for the entire lifetime of the map.

The [Windows image viewer](examples/bmp-viewer.h0) opens uncompressed 24-bit and 32-bit BMP and PNG, including Adam7, at original pixel size. H0 reads and decodes files, composites PNG transparency against gray, and calls Windows to display the result. It accepts files up to 64 MiB, pixel buffers up to 256 MiB, and PNG scratch buffers up to 320 MiB.

The [Linux image viewer](examples/image-viewer-linux.h0) uses the same BMP and PNG decoders and connects directly to X11. It reads `DISPLAY` for a local display such as `:0` or `unix:0.0` and selects an applicable `MIT-MAGIC-COOKIE-1` entry from `XAUTHORITY`, or from `$HOME/.Xauthority` when `XAUTHORITY` is unset or empty. The window closes on a key press or a window manager close request. [X.Org client authentication](https://www.x.org/guide/communication/)

```sh
bootstrap/seed/h0-linux-x64 1 < examples/image-viewer-linux.h0 > h0-image-linux
chmod +x h0-image-linux
./h0-image-linux './my photo.png'
```

With no arguments, the viewer still accepts an address-length byte, address bytes, cookie-length byte (`0` or `16`), optional cookie bytes, and the image path on stdin.

Build and run the viewer from the repository root in `cmd.exe`.

```bat
if not exist build mkdir build
bootstrap\seed\h0-windows-x64.exe 8 < examples\bmp-viewer.h0 > build\h0-bmp-viewer.exe
build\h0-bmp-viewer.exe
build\h0-bmp-viewer.exe "C:\Pictures\my image.png"
```

With one path argument, the viewer opens that file directly. Quote a path containing spaces. Relative paths are resolved from the current working directory. With no argument, the viewer opens the file picker.

On Linux, `bootstrap/seed/h0-linux-x64 8 < examples/bmp-viewer.h0 > h0-bmp-viewer.exe` creates the Windows executable.

The [Win32 example](examples/win.h0) creates a hidden window, checks its position and size, and destroys it. Mode `8` builds it as a GUI executable.

Load `>+n` to copy the Windows command line into a caller-owned UTF-16LE buffer with `:w5`. The result is the byte count before the trailing UTF-16 NUL, or `u64::MAX` on failure. The viewer parses its path argument in H0. [Windows command-line API](https://learn.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-getcommandlinew)

On Linux x64, load `>+q` for the [process input module](std/process-linux.h0). `:a4` copies the argument at a zero-based index and `:a5` copies the value for an exact environment key. Both use caller-owned buffers and return the byte count. `u64::MAX - 1` means absent and `u64::MAX` means an error or insufficient output space. The module reads the initial argument and environment records from procfs. [Linux procfs environment](https://man7.org/linux/man-pages/man5/proc_pid_environ.5.html)

In Windows x64 builds, `\@q` gives the Win64 callback address of the local H0 function `q`. The function can take up to eight integer or pointer arguments and return a scalar. References to the same function in one executable yield the same address. The [callback example](examples/win-callback.h0) registers an H0 window procedure, sends it a message, and checks the result.

Use `>+2` for the [HTTP request framing module](std/http.h0). The [loopback example](examples/http.h0) uses `>+012` to receive one HTTP/1.1 request with a bounded Content-Length body.

Load `>+d` for the [HTTP response module](std/http-response.h0). Call `:r0` with the TCP socket, a zeroed reader buffer of at least 17 bytes, the method flag (`0` ordinary or `1` HEAD), and a disjoint writable body buffer. The result packs the status code in the high 32 bits and the body length in the low 32 bits. Reuse the reader buffer on the same socket to preserve bytes read ahead. A result of `Max` invalidates the reader state. Close the connection and discard the output on failure.

The module handles Content-Length, chunked transfer, and responses ending at EOF. It limits both headers and trailers to 16 KiB and accepts only the chunked transfer coding. The [HTTP GET example](examples/http-get.h0) takes a numeric IPv4 DNS resolver address, its TCP port, the HTTP port, and the hex-encoded hostname. It writes the decoded body to standard output with a 64 KiB limit.

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

Use seed mode `0` to build Windows console PE, `1` to build Linux ELF, `2` for raw RV64 code, `8` for a Windows GUI PE, or `25` for an RV64 machine-mode boot ELF. For an English diagnostic before building, use modes `5`, `6`, `7`, `9`, and `26` respectively. All modes read the source from standard input. Check modes report success or an error code and message. When available, they also report the one-based function section and original line and column. Columns count Unicode scalars.

Mode `25` emits an RV64 machine-mode boot entry. It defaults to load address `0x80000000`, a 1 MiB stack, and one active hart. An optional first line `@<decimal load address> <stack KiB> [hart count]` selects a page-aligned 32-bit load address, a stack from 4 to 16,384 KiB in 4 KiB increments, and 1–64 active harts. Each enabled hart gets its own stack. With more than one enabled hart, the H0 entry receives the hart ID, the firmware's second argument, and the address of a zero-initialized 4 KiB shared page. The ELF loader must zero its writable segment. Harts outside the configured range and harts that return park in a wait-for-interrupt loop. Mode `2` emits a callable routine for a host that supplies the stack.

The [RV64 UART example](examples/rv64-uart.h0) initializes a 16550-compatible UART at the QEMU `virt` board's address and sends `H0 RV64`. The `>+r` module takes the MMIO base as an argument so other memory-mapped 16550 devices can use it. RV64 mapped byte views use `B` and `X` for byte transactions. [QEMU RISC-V virt board](https://www.qemu.org/docs/master/system/riscv/virt.html)

```sh
(printf '@2147483648 4\n'; cat examples/rv64-uart.h0) | bootstrap/seed/h0-linux-x64 25 > h0-uart.elf
qemu-system-riscv64 -machine virt -smp 4 -m 16M -bios none -kernel h0-uart.elf -display none -serial stdio -monitor none
```

Load `>+s` for [RV64 atomics](std/atomic-rv64.h0). `:at` fetches and adds, `:ax` exchanges, and `:ac` compares and exchanges. Each returns the previous u64 value. The address must be nonzero and eight-byte aligned in live coherent RAM. The module requires the RISC-V A extension and uses acquire/release ordering. [RISC-V atomic instructions](https://docs.riscv.org/reference/isa/unpriv/a-st-ext.html)

The [RV64 multicore example](examples/rv64-smp.h0) uses four harts with a 4 KiB stack each. It checks both 40,000 fetch-add updates and 40,000 compare-and-exchange updates, then reads per-hart values published in the shared page.

```sh
(printf '@2147483648 4 4\n'; cat examples/rv64-smp.h0) | bootstrap/seed/h0-linux-x64 25 > h0-smp.elf
qemu-system-riscv64 -machine virt -smp 4 -m 16M -bios none -kernel h0-smp.elf -display none -serial stdio -monitor none
```

Load `>+t` for [RV64 machine traps](std/trap-rv64.h0). Define a local `3-ti` function that receives `mcause`, `mepc`, and the hart's scratch word, and returns the resume PC. `:t3` sets the scratch word and installs the direct trap vector with interrupts disabled. It returns `1` if the hardware rejects the vector. Use `:t4` to set the `mie` mask, `:t5` to toggle global machine interrupts, and `:t8` and `:t9` to write and read the scratch word. `:t6` and `:t7` perform fenced, aligned 64-bit MMIO reads and writes. The trap entry saves the integer registers on the interrupted stack and supports non-nested machine traps. [RISC-V machine-level architecture](https://docs.riscv.org/reference/isa/priv/machine.html)

The [timer example](examples/rv64-timer.h0) programs the QEMU `virt` machine timer for three interrupts, resumes H0 after each one, then writes `H0 MTI 3` to UART. Build it in mode `25`, using the same QEMU command as the UART example above. [QEMU RISC-V virt board](https://www.qemu.org/docs/master/system/riscv/virt.html)

For functions with fixed-size byte buffers, the native seed sizes the stack arena from the buffer declarations. Aligned fixed declarations above 4 MiB in one function report `E108`. The compiler sums declarations conservatively across branches. Functions with runtime-sized allocations keep a 512 KiB arena by default and can grow it through fixed declarations. On Windows and Linux x64, use `>+g` for larger or independently sized buffers.

Use modes `11`, `12`, and `13` to repair source for Windows x64, Linux x64, and RV64. The compiler tries one edit for a repeated view parameter marker, a missing space after a block count, or a missing tab after a call label. It writes the original source when valid or the repaired source when exactly one candidate passes the target check. Otherwise it reports the original diagnostic and status `2`. Check the program behavior with its tests after applying a repair.

Modes `14`, `15`, and `16` use the same checks and emit only `offset op` followed by a newline. The offset is a zero-based UTF-8 byte index in the original input. Operation `1` deletes the byte at that index, `2` inserts a space before it, and `3` inserts a tab before it. Valid input produces empty output. A rejected repair returns the original diagnostic and status `2`.

With a missing block separator injected into each of 16 public examples, the median repair output went from 138 tokens to 4 in `o200k_base` and from 143.5 to 4 in `cl100k_base`. These counts cover compiler output only.

## Developer

Hyeonwoo Kim (kookmin20103324@gmail.com) created and maintains Project H0. Run either native compiler seed with argument `4` to display the author credit.

Licensed under [Apache 2.0](LICENSE).
