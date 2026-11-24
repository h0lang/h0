# Project H0

H0 prioritizes reducing the total tokens AI agents use to complete programming tasks. Compare prompt and guide input, code, reasoning, and repair through a passing result on the same tasks. Track native runtime, binary size, and build time separately.

## Evidence for agent cost

A paired Codex pilot used the Windows x64 native seed to grade three edits to a five-module dispatch program. Each task ran twice per language in fresh sessions, reversing the language order on the second round. Codex CLI 0.171.0-alpha.13 ran `gpt-6.2-sol` at medium effort with the complete task inputs in one prompt, without tools, compiler feedback, or retries. H0 used its short editing guide. Each submission had to pass all 4,212 shared oracle cases.

| Language | Accepted | Total tokens | Tokens per accepted edit | Median seconds |
| --- | ---: | ---: | ---: | ---: |
| H0 | 6/6 | 148,503 | 24,751 | 14.03 |
| Rust | 6/6 | 147,557 | 24,593 | 17.78 |

H0 used 0.64% more total tokens and took 21% less time at the median. It used 2,018 output tokens, including 722 reasoning tokens, against Rust's 2,792 output tokens, including 152 reasoning tokens. Each language received 65,024 cached input tokens in aggregate. The pilot used fresh sessions with provider-managed caching, one model, and three edits. Time includes Codex startup and local grading. [Per-attempt usage and grades](benchmarks/native-dispatch-codex.json)

- Compare H0 and Rust on the same tasks with equivalent starting programs and an independent correctness oracle. Include both new programs and edits that cross file boundaries. Fix the model snapshot, agent version, reasoning effort, tool access, timeout, and retry budget. Run each attempt in a fresh session. Evaluate cold and warm cache conditions separately.
- Record provider usage for every request, including repair attempts and runs that fail or time out. Normalize input and output once, report cache reads and writes separately, and count reported reasoning within output. Measure elapsed time from task delivery through the final correctness check. Keep raw usage and the per-task outcome for every pair. A run without usage needs an explicit missing-data record and cannot establish a cost result.
- Report passes and attempts, total input and output, total tokens per accepted solution, median elapsed time, and elapsed time per accepted solution. Totals include failed attempts. Claim a token advantage only when paired correctness is at least as high and total tokens per accepted solution are lower. Report billed cost separately when provider rates and cache classes are known.

A follow-up varied only the H0 editing guide. Five added syntax examples cost 164 prompt tokens per edit in `o200k_base`. Both versions passed all six attempts. Examples reduced reported reasoning tokens from 912 to 763 and increased total tokens from 148,725 to 149,515, or 0.53%. The short guide remains the default. One attempt hit provider capacity and returned no usage. Its successful rerun is counted, and the interruption is recorded separately. [Guide variant and per-attempt results](benchmarks/native-edit-guide-codex.json)

A later paired pilot tested three previously unused dispatch changes, twice per language, against the same 5,580 oracle cases. H0 used its short editing guide and submitted only changed functions. Rust submitted complete changed files. All twelve attempts passed on their first response. H0 used 147,777 total tokens versus 150,357 for Rust (1.72% fewer), with median task times of 10.27 s and 14.57 s respectively. The H0 workflow enabled native recovery, and zero submissions needed it. The pilot used Codex with `gpt-6.2-sol` and provider-managed caching.

For accepted executables, H0 was 11,264 bytes versus 140,288 to 140,800 for optimized Rust. With 44,640 framed cases per process on one Windows logical CPU, H0 took 4.4 to 5.2 times as long across the six pairs. The runtime measurements include process startup and binary stdin/stdout. [Held-out tasks, usage, grades, and runtime samples](benchmarks/native-heldout-edits-codex.json)

A replay gave both languages the complete program and required only named function replacements. Ten submissions passed all 5,580 cases each. Two attempts, one per language, timed out after the provider reported capacity limits and returned no usage. Across the four pairs with complete usage, H0 used 72,602 total tokens versus 72,040 for Rust. The visible prompts and JSON answers took 7,018 versus 7,928 tokens in `o200k_base`. Median end-to-end time was 8.60 s for H0 and 11.25 s for Rust. These figures describe the completed pairs. [Matched function-edit trials and interruptions](benchmarks/native-dispatch-fair-function-codex.json)

## Native toolchain

H0 (Human Zero) is a native programming language for AI agents. Its Tape notation uses positional registers and compact Hangul instructions. Separate packed functions with a newline or `;;`. The [calendar example](examples/calendar.h0) fits five functions on one line.

H0 compiles its own compiler source on Windows and Linux x64. See [AGENTS.md](AGENTS.md) for the language reference, native build commands, standard library, and compiler entry points.

Use the `정` prefix or `>+5` header for native numeric functions. For example, `정0 열12` returns 144. `약ab` computes the unsigned greatest common divisor, with `gcd(0, 0) = 0`. `승ab` computes the unsigned least common multiple, returning zero for a zero operand and wrapping the result modulo `2^64`. `열a` computes the Fibonacci number at unsigned index `a` modulo `2^64`, using powers of the Fibonacci recurrence matrix for small indices and fast doubling for large ones. The [integer divisors example](examples/integer-divisors.h0) runs on Windows x64, Linux x64, and bare-metal RV64.

With `정` or `>+5`, `재ab` parses shared byte view `a` as an unsigned decimal integer. It returns the value on success and zero on error. Only the first byte of mutable view `b` is written. Status codes are 0 for success, 1 for empty input, 2 for a nondigit anywhere in the input, and 3 for overflow. Leading zeros are accepted. A nondigit takes precedence over overflow. An empty status view returns zero without writing. The optional-result entry `:pn` uses the same parser.

With the numeric module loaded, `식ab` formats unsigned scalar `b` as decimal into mutable byte view `a`. It returns the number of digits, or zero when the destination is too short. A short buffer is left untouched, and successful formatting preserves the destination tail. The formatter stores groups of up to eight decimal digits using a shared two-digit lookup table.

With the same numeric import, `화abm` computes the exact product modulo `m`, `용aem` computes modular exponentiation, and `해a` tests whether a u64 is prime. Both modular operations return zero for moduli zero and one. Exponentiation uses Montgomery multiplication for wide odd moduli and combines the odd and power-of-two residues for wide even moduli. Primality uses the deterministic seven-witness Miller–Rabin set for the u64 range. [Native modular implementation](std/num-mod.h0) [Witness records](https://miller-rabin.appspot.com/)

The single-line example takes 63 tokens in both measured tokenizers. With ASCII calls and an explicit import it takes 74 in o200k_base and 73 in cl100k_base. In an exploratory Windows x64 run with 8,192 wide-modulus exponentiations per process, H0 took 25.05 ms for odd moduli and 26.90 ms for even moduli. The H0 double-and-add baseline took 426.68 and 432.30 ms. The Rust u128 implementation took 17.85 and 15.86 ms. [Example](examples/modular.h0) [Correctness and timing data](benchmarks/native-modular-arithmetic.json)

`\*ab` returns the upper 64 bits of the full unsigned product. The native compiler emits x64 MUL or RV64 MULHU. The modular library uses this operator in Montgomery reduction. On RV64 the standalone function fell from 156 to 30 bytes and from 63 to 12 executed instructions, including function entry and return. [Intel instruction reference](https://cdrdv2-public.intel.com/835757/325383-sdm-vol-2abcd.pdf) [RISC-V M extension](https://riscv.github.io/riscv-unified-db/manual/html/isa/isa_20240411/chapters/m-st-ext.html)

In the paired Windows x64 rerun, the native operator reduced the odd and even modular exponentiation batches from 22.98 to 20.25 ms and from 23.78 to 20.29 ms. The Rust u128 reference took 14.02 and 14.05 ms. [Operator validation and paired samples](benchmarks/native-mulhi.json)

Modular exponentiation now obtains the Montgomery setup for wide residues through six squarings. It groups adjacent exponent bits when doing so reduces multiplication and shortens the power-of-two part of even-modulus calculations. The existing numeric calls retain the same input and result contracts.

On four Windows batches of 8,192 exponentiations, the revised implementation used 25–36% fewer process CPU cycles than the previous H0 build. The Rust reference had lower median elapsed time in each batch. In separate RV64 emulation, wide odd and even cases used about 21% and 28% fewer executed instructions. [Measurements and correctness](benchmarks/native-montgomery-window.json) [Windows cycle counter](https://learn.microsoft.com/en-us/windows/win32/api/realtimeapiset/nf-realtimeapiset-queryprocesscycletime)

The primality routine selects its Miller–Rabin bases without allocating a writable table. The two-bit exponent path shares the same function frame as the basic path. For the same Stage 1 wrapper and 1,036 inputs, peak RV64 stack write depth fell from 5,792 to 3,440 bytes and the raw executable from 3,312 to 2,718 bytes. The revised test ran within a 4 KiB mapped stack. [RV64 stack and correctness checks](benchmarks/native-prime-stack.json)

For editing existing native H0 code, start with [EDIT.md](EDIT.md) and the source plus its scoped glyph and module records. [CORE.md](CORE.md) and [AGENTS.md](AGENTS.md) provide the remaining operations and contracts on demand. Count any later reference reads in end-to-end agent usage. For a new task with known standard modules, run mode `60` from the repository root. Send the target on the first line (0 for Windows, 1 for Linux, 2 for RV64), followed by H0 source or a minimal entry such as `째0 0`. The command writes `EDIT.md`, a blank separator, and the selected standard-library contracts. Discard the output on a nonzero exit.

Native binary64 values use one scalar containing the IEEE 754 bit pattern. Use `\F+`, `\F-`, `\F*`, and `\F/` for arithmetic, `\F^` for square root, and `\F<`, `\F=`, and `\F>` for ordered comparisons. Comparisons involving NaN return zero. Use `\Fi` or `\Fu` to convert signed or unsigned 64-bit integers to binary64. The inverse operators `\FI` and `\FU` truncate toward zero and saturate at the destination limits. NaN converts to zero.

Use `\Fd0.1`, `\Fd-5e-324`, or `\Fd"1.e2"` for decimal constants. The compiler rounds the decimal value to the nearest binary64 value, breaking ties toward an even significand. It preserves signed zero, handles subnormals, and produces signed infinity on overflow. The [decimal example](examples/decimal64.h0) writes the little-endian binary64 values 0.1 and 1.5 to stdout.

For decimal text received at runtime, import `>+5` and call `:n7` with the input bytes and an output view of at least eight bytes. It consumes the entire input, accepts a sign and decimal exponent, and writes one little-endian binary64 value using the same rounding code as `\Fd`. On malformed input or a short output view it returns `0` and leaves the output untouched. The [runtime example](examples/parse64.h0) takes one command-line argument and writes its eight result bytes to stdout.

Use `:nf` from `>+5` to format finite binary64 values as decimal ASCII. It selects the fewest significant digits that round back to the original bits, chooses the shorter of fixed notation and an integer significand with a decimal exponent, and preserves `-0`. Pass a mutable output view and the value's bits. It returns the bytes written, up to 23, or zero for infinity, NaN, or insufficient space. A zero result leaves the view untouched. [Round-trip CLI example](examples/format64.h0) [Burger and Dybvig's rounding-interval algorithm](https://legacy.cs.indiana.edu/~dyb/pubs/FP-Printing-PLDI96.pdf)

For bit-preserving binary64 text, use `:nX(out,bits)` and `:nY(text,out)` from `>+5`. Finite values use the same decimal representation as `:nf`. Infinity and NaN use a tilde followed by the complete 16-digit lowercase hexadecimal bit pattern, which preserves the NaN sign, quiet bit, and payload. `:nX` returns the byte count and `:nY` returns 1 after writing eight little-endian bytes. Both leave output untouched on failure and return 0. This text format is separate from JSON numbers.

The [float text CLI](examples/float-text.h0) reads little-endian binary64 records from stdin and emits one ASCII record per line. Pass `-d` to decode back to binary64. Decode input lines can contain up to 4,096 bytes.

Import `>+j` and parse a JSON document with `:j0`. Convert a number node to finite binary64 with `:ja`, read a number by object key with `:jb`, or read one by array index with `:jc`. These calls return `Max` for a missing or non-number node, an invalid span, or a decimal that rounds to infinity. Use `:ji` to write an exact little-endian `u64` or `i64` from an integer token, including values outside binary64's exact integer range. `>+j` also provides `:nf` to write finite numbers in JSON number syntax. [JSON calculation example](examples/json-number.h0) [RFC 8259 number syntax](https://www.rfc-editor.org/rfc/rfc8259.html#section-6)

The JSON calculation example takes 115 source tokens with `:jb`, compared with 203 for the same program using a local helper over `:j2`, `:j5`, and `:n7` in `o200k_base`. In `cl100k_base` it takes 117 versus 204. The Windows executable takes 45,568 bytes versus 44,544 for the local helper. The counts cover source text and the executable.

The compiler emits SSE2 on Windows and Linux x64, and floating-point instructions on RV64D. Enable floating-point state before calling RV64D code from a bare-metal entry. The [ratio example](examples/binary64.h0) divides two unsigned decimal arguments and sends the eight little-endian result bytes to stdout. Arguments `3 2` produce the binary64 encoding of 1.5. [Intel SSE2 instruction reference](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-2a-manual.pdf) [RISC-V D extension](https://docs.riscv.org/reference/isa/unpriv/d-st-ext.html)

The compact glyph records describe only aliases used in the supplied source. Run `bootstrap/seed/h0-linux-x64 19 < examples/calendar.h0` on Linux or `bootstrap\seed\h0-windows-x64.exe 19 < examples\calendar.h0` in Windows `cmd.exe`. The compact map is described below. For the selected standard-library contracts, run mode `20` for Windows, `21` for Linux, or `22` for RV64 with the source on stdin. Each mode reads `AGENTS.md` in the repository root and prints only the imported modules and their implicit dependencies for that target. Use check modes `5`, `6`, or `7` to validate target support and source syntax. Use the full guide for extended syntax.

For a shared agent context covering several files, run mode `39` for Windows, `40` for Linux, or `41` for RV64. Send a positive decimal file count followed by LF, then one decimal byte length, LF, and exact UTF-8 source for each file. Each source must have at least one byte. Records follow one another immediately, and the entire request must fit in 128 KiB. The compiler prints two compact glyph rows followed by the selected standard-library contracts. Each row contains one definition per glyph in first-use order across the files, and each selected module contract appears once. Run from the repository root and discard output on a nonzero exit. Invalid framing reports `E120`.

For 38 Windows examples in one context, the combined glyph and contract output fell from 12,779 tokens to 2,920 in `o200k_base` and from 12,799 to 2,927 in `cl100k_base`. The comparison runs modes `19` and `20` for each file against one run of mode `39`. With the same single copy of `CORE.md` and all 38 source files in both inputs, totals fell from 21,890 to 12,032 and from 21,965 to 12,094 respectively. These figures cover input text.

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

Mode `29` applies several replacements together. Send the decimal record count followed by LF, then one `ordinal LF byteCount LF replacement LF` record per section, and finally the original source. Sort records by distinct ascending section ordinal from the original file. Byte counts use UTF-8 and exclude separators. The compiler verifies every replacement range before writing the patched source. Run the target check on the result.

Modes `43`, `44`, and `45` take the same batch and check the edited program for Windows x64, Linux x64, and RV64, respectively. A successful check writes the patched source. A failed check returns status 2 and the same diagnostic as modes `30`, `31`, or `32`, including the failing section when its source span is available. The tool checks the batch against the original section boundaries before applying it.

For six failed example edits, the combined patch and check output took 189 tokens in `o200k_base` and 190 in `cl100k_base`. When both the intermediate source and the diagnostic from separate commands were included, the same edits took 5,199 and 5,242 tokens respectively. For a valid two-section batch in the Windows image viewer, one checked command took a median of 9.54 ms versus 16.08 ms for two commands over 14 paired runs, including process startup.

Mode `42` extracts several sections in one pass. Send a positive decimal count followed by LF, then that many distinct ascending zero-based ordinals, one per LF-terminated line, followed by the original source. The compiler writes the count and one `ordinal LF byteCount LF section LF` record per selection. Append the original source to the records and pass them to mode `29` to apply replacements. Update each byte count after editing its section. Invalid requests report `E121` and missing ordinals report `E112`.

```sh
(printf '2\n1\n2\n'; cat examples/atomic-threads.h0) | bootstrap/seed/h0-linux-x64 42
```

For the six public examples with at least two named functions, extracting the middle two with mode `42` took 1,360 tokens versus 5,682 for complete source in `o200k_base`, including the extraction metadata. In `cl100k_base` it took 1,373 versus 5,730. Extracting the first five named sections of the Windows viewer took a median of 7.47 ms in one call versus 37.40 ms in five mode `24` calls over 12 paired runs, including process startup.

Mode `46` takes the mode `42` request and prefixes its extraction records with the two compact glyph rows from mode `19`. The rows include only glyphs present in the selected sections, once per row in first-use order. Skip the first two LF-terminated rows to pass the records to mode `29` or modes `43`–`45`. Use modes `20`–`22` for contracts of imported modules and modes `33`–`35` for callee headers when needed.

Across 107 single-section selections from the public examples, the glyph rows and extraction records totaled 10,952 tokens in `o200k_base`, down from 12,395 with whole-file glyph rows. In `cl100k_base` they totaled 11,051, down from 12,403. Both tokenizers showed savings in 54 selections. These counts cover the requested excerpts, their framing, and the glyph rows.

Mode `49` reads `target LF selector LF source`, with targets `0` (Windows x64), `1` (Linux x64), and `2` (RV64). Use a unique function name or a zero-based section ordinal from mode `23` on valid source. The compiler emits direct call and callback neighbors by ordinal as `>ordinal header` (callee), `<ordinal header` (caller), or `=ordinal header` (both). A blank line ends the list. Next come two section-local glyph rows, the selected ordinal, and the exact section followed by LF. For an edit, apply the changed section with mode `28` and check the result with mode `5`, `6`, or `7`. Invalid framing reports `E124` and a missing or ambiguous selection reports `E112`.

Across 44 named sections selected from Windows x64 examples, providing mode `49` output once per selection used 5,072 input tokens versus 52,233 for providing the whole source and its glyph rows in `o200k_base`. In `cl100k_base` it used 5,095 versus 52,420. These counts exclude task instructions, reasoning, and edits.

For a two-function edit in each of the five public examples with at least two named sections, returning just the two sections would take 1,040 instead of 5,110 output tokens in `o200k_base`, and 1,047 instead of 5,146 in `cl100k_base`. The estimate uses the two middle named sections as replacement text and counts one LF after each.

For the 21 public examples with standard-library imports, the complete native standard-library contract table costs 2,666 tokens in `o200k_base` and 2,685 in `cl100k_base`. Target-specific output had medians of 272 and 281. With one copy each of CORE, source, and compact glyph map per example, replacing the full contract table with the scoped output reduced summed input from 89,047 to 39,770 and from 89,617 to 40,052 respectively. The comparison counts supplied reference and source text.

In the scoped guide benchmark across 19 public examples, the median input for the full guide and source was 6,832 tokens in `o200k_base`, compared with 1,154 for CORE, glyph records, and source. In `cl100k_base` the median went from 7,265 to 1,165. These figures count reference and source input.

On both native seeds, mode `17` packs selected standard-library calls whose repetition can offset the cost of a glyph record. It also packs remaining calls when the source already uses that alias. Mode `18` packs every mapped call and suits agents that already have the alias definitions. When an import contains only modules `1`, `5`, and `z` and is immediately followed by a function header, mode `18` packs it using `문`, `정`, and `째`. Put the syllables next to each other to import several modules. For example, `문째0` starts a zero-argument function with I/O and packed ordering loaded. Both modes read H0 from stdin and emit H0 on stdout. Use mode `19` on the result for a compact map, or mode `10` for individually quoted records.

Across the 20 public examples, mode `17` reduced source plus per-file glyph records from 5,460 to 5,427 tokens in `o200k_base` and from 5,513 to 5,504 in `cl100k_base`. Mode `18` reduced source alone from 5,087 to 4,905 and from 5,125 to 5,076 respectively. With fresh per-file glyph records, mode `18` increased the totals to 5,565 and 5,793. The measurements count input text.

Mode `19` returns two LF-terminated rows. The first maps code glyphs and the second maps escaped Hangul inside byte literals. Each Hangul syllable starts a record whose ASCII expansion continues until the next syllable or the end of the row. Tabs are literal. Backslashes, newlines, carriage returns, and other control bytes use `\\`, `\n`, `\r`, and `\xHH` respectively. Empty rows have no records.

For the 20 public examples in separate sessions, one copy of CORE, the source, and its glyph map per example totaled 27,460 tokens with quoted maps and the previous CORE, and 27,089 with compact maps and the shortened CORE in `o200k_base`. In `cl100k_base` the totals were 27,633 and 27,255. These are input token counts.

Native builds validate every function and then omit local functions unreachable from the entry and target-specific roots. The reachability pass follows direct calls and Windows callback addresses and retains an installed RV64 machine trap handler. It regenerates machine code and relocations for the retained functions. Across the public examples accepted by each target, total binary bytes fell from 286,208 to 246,784 on Windows x64 (22), from 261,129 to 212,204 on Linux x64 (21), and from 16,292 to 14,744 for raw RV64 (8). These totals include file headers and alignment where the target emits them.

On x64, the compiler checks a literal byte offset by comparing the view length to the constant end of the access when the offset and end fit the instruction operands. The load or store uses that displacement directly. A literal store value that fits the instruction is encoded as an immediate. An invalid store traps before evaluating the value. Across the current examples, Windows x64 output totaled 367,616 bytes versus 385,024 before this change across 31 builds, and Linux x64 totaled 284,534 versus 297,932 across 30 builds. An isolated Windows loop with eight million checked record reads and writes took a median of 11 ms versus 15 ms across seven timed runs.

For x64 scalar compound assignments with a single scalar register as the right operand, addition, subtraction, AND, OR, and XOR use a load, an arithmetic or logic instruction with a memory source, and a store. The compiler omits the intermediate expression spills. A Windows loop running `^bc +cd -db |cb &dc +bd` for 24 million iterations took a median of 37.75 ms versus 65.72 ms before this change across eight paired runs pinned to one logical CPU. Both binaries produced the same three result words. Across the public examples, Windows x64 binaries (36) totaled 465,408 bytes versus 467,456, while Linux x64 binaries (35) totaled 358,430 bytes versus 359,490. [Intel instruction set reference](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-2a-manual.pdf)

The same x64 lowering applies inside addition, subtraction, multiplication, AND, OR, and XOR expressions with a scalar right operand. The compiler evaluates the left operand first, then reads the right scalar directly from its frame slot. Functions with dynamic stack allocation use the stable frame pointer for this read, including in compound assignments. [Dynamic-frame regression example](examples/scalar-expression.h0)

A Windows loop running `b^Tb7c c+*c13b d-+dcb b+^bdc c^|cbd d+*dcb` for 12 million iterations took a median of 38.43 ms versus 43.20 ms across eight paired runs on one logical CPU. The results matched. For the same set of existing public examples, Windows x64 binaries totaled 459,264 bytes versus 465,408, and Linux x64 binaries totaled 352,366 bytes versus 358,430.

For x64 byte and little-endian word loads indexed by a scalar register, the compiler keeps the view address and length in registers throughout the load. Both span and index checks are retained. On one logical Windows CPU, 1,500 comparisons of equal 64 KiB buffers through the same H0 prefix function took a median of 16.0 ms versus 18.5 ms before the compiler change. Across the public examples, Windows output (41 builds) went from 528,384 to 520,704 bytes and Linux output (40 builds) went from 379,517 to 374,438 bytes.

x64 byte and little-endian word stores with a register index and a register or immediate value also keep the address and index in registers. On one logical Windows CPU, 2,500 copies of 64 KiB using an eight-byte H0 store loop took a median of 29 ms versus 37 ms before the change. The byte store loop took 192 ms versus 210 ms. Optimized Rust `copy_from_slice` took 2 ms for the same buffer and repetition count.

Simple x64 `?` and `W` comparisons now jump directly on the flags from `CMP`. The left operand must be a bound scalar and the right operand a bound scalar or a decimal constant from 0 to 2,147,483,647. The compiler also handles a single negation. [Branch and dynamic-frame example](examples/compare-branch.h0)

The x64 backend also compares a byte view's length directly against a decimal constant in that range. This applies to parameter and local views, including mutable views. The conditional expression `\i` shares the same comparison lowering. In entry functions with explicit register operands, a view length read preserves that view's argument slots and allows unrelated unused argument stores to be dropped.

On x64 and RV64, reading a named view's length as a value loads the length slot directly into the result register. Subviews and literals still compute their lengths from their bounds or contents.

For a constant-index load from a named view, x64 compares the required size directly against the length slot before loading the pointer. Computed views and dynamic indices retain bounds checking through the existing lowering.

Packed x64 calls retain their argument layout. The function entry skips storing unused arguments when the body uses only supported explicit-register operations. It keeps all argument stores for bodies outside that subset.

On Windows, a 24-million-iteration loop with a scalar loop condition and a mix of taken and untaken branches took a median of 40.12 ms versus 61.39 ms across eight paired runs on one logical CPU. Both binaries produced the same result. Across the existing examples, Windows x64 output (37 builds) fell from 460,800 to 452,608 bytes and Linux x64 output (36 builds) from 353,451 to 343,940 bytes.

RV64 uses the same comparison syntax with a scalar or any `u64` decimal constant on the right. The hardware branch compares the operands and skips an adjacent `JAL` on the true path. The `JAL` handles false destinations beyond the conditional branch's 4 KiB reach. For a 10,000-iteration loop with one comparison at the loop head and two in the body, RV64 emulation counted 290,010 instructions versus 380,013. Across 11 existing raw RV64 examples, output fell from 23,882 to 23,026 bytes. [RISC-V conditional branches](https://docs.riscv.org/reference/isa/unpriv/rv32#_conditional_branches)

Native x64 and RV64 builds lower unsigned multiplication, division, and remainder by a constant power of two to shifts or bit masks. The compiler evaluates the left operand before applying the operation, including when the divisor is one. In raw RV64 output for a single unary function, division and remainder by eight each fell from 36 to 20 bytes and from 12 to 8 executed instructions in emulation. Multiplication by 1,024 fell from 12 to 4 bytes and from 4 to 2 instructions.

For other nonzero unsigned constant divisors below `2^63`, x64 builds compute an integer reciprocal at compile time and emit a high multiply, a shift, and a correction when required. Remainder reconstructs the quotient product and subtracts it from the dividend. Divisors above `2^63` use a comparison on x64 and RV64, since the quotient can only be zero or one. RV64 keeps native division for the remaining non-power-of-two constants. [Multiply-and-shift integer division](https://libdivide.com/)

One Windows x64 machine ran each program with affinity to one logical CPU. The benchmark starts with `a=11995408973635179863` and `sum=0`. For `i` from zero to 23,999,999 it performs `a ^= a >> 7`, `a += i`, `a ^= a OP divisor`, and `sum += a` with u64 wrapping, then prints the sum. The table reports median elapsed milliseconds over six runs after warm-up, including process startup. Rust 1.100.0 used `-C opt-level=3 -C target-cpu=native`.

| Operation | Previous H0 | H0 | Rust |
| --- | ---: | ---: | ---: |
| / 3 | 106.76 | 57.47 | 59.22 |
| / 7 | 105.21 | 71.26 | 74.87 |
| / 10 | 107.06 | 56.15 | 59.19 |
| % 10 | 127.60 | 78.12 | 74.54 |
| / 18,446,744,073,709,551,557 | 104.98 | 55.35 | 38.50 |

The Linux seed is a static ELF that calls the kernel directly. The Windows seed imports `KERNEL32.dll` for operating-system services. Both seeds run without a Python interpreter or C runtime.

Mode `47` builds an ordered list of H0 source files. Write the target mode on the first line, followed by one UTF-8 path per line. Paths with spaces work as written, and relative paths resolve from the working directory. Files share one function namespace in list order. Use named calls across files. The compiler merges the leading `>+` declarations from all files into one standard-library selection.

Mode `48` takes the same path list without the target line and returns the assembled source. Source and loaded standard-library modules must fit within the compiler’s 512 KiB source capacity. Direct builds and checks use the same capacity. Expanded source and emitted code each have a separate 1 MiB limit. When a diagnostic points into a listed file, mode `47` reports its original line and column and adds a `File <path>` line. Section ordinals follow the assembled source. For the failing section’s ordinal and source, use modes `30`–`32` through mode `47`; they follow the file line when available. Invalid lists report `E122`; file read failures, empty or oversized source, and invalid import headers report `E123` with the path.

A build can record up to 8,192 call sites for native linking. Exceeding the limit reports `E135` at the first excess call.

For project syntax repair, send mode `47` a target line of `14` (Windows x64), `15` (Linux x64), or `16` (RV64), followed by the same ordered path list. A valid project produces empty output. A unique passing candidate in an original file produces `byteOffset op LF File path LF`. The offset is zero-based and accounts for merged import lines and mixed line endings. The tool leaves project files intact. With no unique mapped repair it returns the original project diagnostic and status 2.

The project bundler moves each source body as a contiguous span after stripping its import line. Source normalization also copies quoted byte literals as spans. In 12 paired Windows runs pinned to one logical CPU, bundling 16 files with import lines into 491,054 bytes took a median of 10.96 ms versus 11.72 ms. Compiling the same 118,425-byte bootstrap source took 34.56 ms versus 35.70 ms. Both measurements include process startup and I/O, and the paired outputs were byte-identical.

Mode `50` reads `target LF selector LF paths` for one section of a valid project. Use the function name directly or the ordinal from mode `23` on the mode `48` bundle. The caller and callee rows from mode `49` end at a blank line. The next three lines give the original path, zero-based byte offset, and byte count. Two scoped glyph rows and the ordinal precede the exact section bytes and a final LF. The original range accounts for merged import lines and preserves the source file’s encoding and line endings. Verify that the range still matches the returned bytes before replacing it, then check the project with mode `47`. Mode `50` uses the list errors from modes `47` and `48`, selection errors from mode `49`, and `E125` if the section crosses a project file boundary.

```sh
printf '1\napp.h0\nlogic.h0\n' | bootstrap/seed/h0-linux-x64 47 > app
```

Mode `55` extracts several sections from one project. Send a positive count, ascending distinct bundle ordinals, and the ordered project paths, each on its own line. Use mode `48` followed by mode `23` to find the ordinals. The response begins with two shared glyph rows and a count line. Each record has `ordinal fileIndex byteOffset byteCount` followed by LF, exactly `byteCount` source bytes, and another LF. File indices and byte offsets are zero-based and refer to the supplied path list and original files. Compare the bytes with the current source before preparing a mode `53` or `54` edit. Discard output on nonzero exit.

Mode `56` takes a count, distinct function names, and the ordered project paths, each on its own line. It emits the mode `55` packet in request order and resolves the ordinals during extraction. A missing or ambiguous name or a repeated selector reports `E112`.

Mode `59` writes a compact editing context for a list of named functions. Send `policy LF count LF names LF paths`, with one name or path per line. Choose 0 for Windows, 1 for Linux, 2 for RV64, or 3 for source with glyph definitions only. Two shared glyph rows come first. For policies 0 through 2 the selected module contracts follow, using the full project imports. A blank line separates this context from the exact function bodies in request order. Select any supporting functions alongside the edit targets. Numeric and relative calls keep their meaning in the original project. Use mode `56` for original offsets and ordinals, and mode `57` to build named replacements.

For the bootstrap compiler, 149 named functions took 11,376 tokens through mode `59` versus 12,715 through mode `56` in `o200k_base`. The editing guide fell from 633 to 507 tokens after moving duplicate CLI instructions and adding a prefix-operator example. [Context verification and both tokenizers](benchmarks/native-edit-input-context.json)

In a paired Codex pilot on three dispatch edits, selected functions and the shorter guide cut explicit prompt size by 726 to 813 tokens per task. Across five pairs with usage on both sides, whole-project prompts passed 5/5 and selected prompts passed 4/5. Total provider usage was 90,979 and 87,247 respectively, including the failed response. One full-context attempt timed out at provider capacity and returned no usage. A separate fresh attempt with the extra prefix example passed the failed task, and the pilot totals exclude that attempt. [Prompt and grading results](benchmarks/native-compact-edit-input-codex.json)

Mode `51` evaluates a proposed file in place of one source in a project. Send `target LF fileIndex LF candidatePath LF projectPaths`. The file index is zero-based in the original ordered path list. The accepted targets are `0–2, 5–9, 14–16, 25–26, 30–32` and the result uses the mode `47` build, check, or repair format. The compiler reads the candidate from its own path and leaves every file intact. For compiler diagnostics it names the original logical path and uses line and column positions from the candidate. Bad framing or a missing index reports `E126`. An unreadable replacement reports `E123` with its candidate path.

```sh
printf '5
1
scratch/logic.h0
app.h0
logic.h0
' | bootstrap/seed/h0-linux-x64 51
```

Mode `52` checks or builds several proposed files in one project. Send `target LF count LF (fileIndex LF candidatePath LF)×count originalPaths`. Use a positive count and distinct zero-based indices in increasing order. The original path list keeps its usual order. All replacements take effect in the same build, with the same target modes, logical paths, diagnostics, and source limits as mode `51`.

Mode `53` checks or builds several in-memory edits to the original project. Send `target LF count LF (fileIndex LF offset LF oldBytes LF newBytes LF replacement LF) x count originalPaths`. Count is positive. File indices and UTF-8 byte offsets are zero-based. Use ascending file indices and ordered, nonoverlapping ranges within each file. Offsets always address the original file. Use zero `oldBytes` to insert at an offset or at EOF, or zero `newBytes` to delete. Consecutive insertions at the same offset are applied in request order. The replacement is exactly `newBytes` bytes followed by one LF. Numeric header lines and path lines also accept CRLF. The compiler uses the targets, output, and logical paths of mode `47`. Compiler errors point into the proposed source. Invalid edit framing, out-of-bounds ranges, and missing file indices report `E127`. Total request and source limits are 512 KiB each.

Declare a finite tag domain with a line such as `#%E N A M V`. Tags are zero-based in declaration order. A line such as `#@E 5-edisp'bc"d eother N=enum A=eadd M=emul V=evar` defines a checked dispatcher. The header uses ordinary H0 calling conventions with a scalar tag as the first argument. Each named handler and the fallback receive all of the same arguments. The compiler generates the branches and checks ordinary call types. The fallback handles numeric tags outside the domain. It is still required to list every named case in declaration order.

Directives start at the first column and end at LF or CRLF. A domain supports up to 256 unique names. Declarations can live in a different project file from dispatchers. The compiler reports E132 with the missing handler's tag name when a declaration gains a case and a dispatcher omits it. Invalid, duplicate, or extra declarations or bindings report E131 or E132. The [expression tree example](examples/expression-tree.h0) reads a little-endian node count and variable count, followed by 24-byte postorder nodes and eight-byte variable values. It evaluates wrapping u64 arithmetic and writes the root value.

Use modes `23` or `50` to find original byte ranges. Check that the current bytes still match the snapshot used to choose the ranges. The caller can then submit only the changed text and coordinates, and the compiler reads the remaining bytes from disk. The compiler leaves the source files intact.

With mode `53`, targets `14` (Windows x64), `15` (Linux x64), and `16` (RV64) check the proposed project and try to repair operand spacing. A valid proposal returns empty output. A verified repair returns one or more `byteOffset 4 LF File path LF` records. Each offset addresses the proposed file before repair, and operation `4` replaces one ASCII space with a TAB. Apply all records and run the target tests. The compiler tries single substitutions at each failed instruction and pairs when at most 16 spaces are eligible. It returns the original diagnostic and status 2 when it cannot find an unambiguous sequence that passes the whole project check. Use the framing of mode `53` with the revised proposal to build or check it.

Mode `54` uses the same edit frame with build/check targets `0–2, 5–9, 25–26, 30–32`. On an operand error, it can apply verified space-to-TAB repairs to the submitted replacement bytes in memory and finish the requested build or check in the same invocation. Every repair must fall inside a replacement. Otherwise the compiler returns the original diagnostic. It leaves the source files intact and uses the same stdout format as a regular build or check. Use mode `53` with repair targets `14–16` to inspect proposed repairs.

Mode `57` builds or checks named section replacements in memory using the targets and verified operand-spacing repair from mode `54`. Send `target LF count LF (name LF byteCount LF exactSection LF)×count originalPaths`. Each name identifies one existing project function, and each replacement is one complete section with the same name. Put edits in any order. Use byte counts and omit the section separator from the replacement. The compiler sorts edits by their original ranges, checks the original section bytes before applying them, and leaves source files intact. Framing or a mismatched replacement header reports `E129`; a missing or ambiguous function reports `E112`.

Mode `58` applies exact byte replacements within named functions. Send `target LF count LF (name LF oldBytes LF newBytes LF old+new LF)×count originalPaths`. The old and new payloads are consecutive, with no separator between them. Use one edit per function. The old payload must be nonempty and match exactly once, including overlapping matches. A zero-length new payload deletes the old bytes. The result must remain one section with the original name. The compiler checks the source snapshot and uses the same build, check, and spacing repair as mode `57`. An invalid, absent, or ambiguous byte match reports `E130`. An unknown, ambiguous, or repeated function name reports `E112`.

Replaying six accepted dispatch edits gave identical Windows and Linux binaries to whole-section replacement. With compact JSON arrays, the same changes took 218 versus 339 output tokens in `o200k_base`, and 216 versus 339 in `cl100k_base`. One very short edit was smaller as a whole-section replacement. These counts cover the submitted edit text. [Replay results](benchmarks/native-anchored-project-edits.json)

In a separate Codex writing pilot, ten responses passed all 5,580 checks each. Two anchored attempts timed out at provider capacity and returned no usage. Across the four pairs with usage in both conditions, exact byte edits used 379 output tokens versus 325 for whole functions, including 49 versus zero reasoning tokens. Total provider usage was 72,722 versus 74,068. These figures describe the four paired results. [Fresh agent trials](benchmarks/native-anchor-author-codex.json)

The native edit modes also built equivalent Windows and Linux binaries for tested requests up to about 524 kB. The previously failing requests now complete without changing the original source. [Large-project build checks](benchmarks/native-anchor-large-project.json)

Replaying the six initial section-edit submissions with mode `54` accepted 6/6 without a model retry. Their recorded usage totaled 146,454 tokens, compared with 145,535 for the pilot's whole-file submissions. The original failed submission's executable passed all 4,212 oracle cases on Windows and Linux.

Re-encoding the six accepted H0 dispatch submissions above as JSON byte edits reduced replacement output from 1,140 to 362 tokens in `o200k_base` and from 1,132 to 362 in `cl100k_base`. Both encodings used compact JSON and identical submitted source changes. Each mode `53` build matched the complete-file build byte for byte and passed all 4,212 oracle cases for its task. The counts cover the submitted JSON.

A follow-up asked Codex to generate these edits by function name, with mode `23` resolving byte ranges and mode `53` building them. The control asked for complete changed files. Both used the same input files and guide, with two runs for each of three dispatch edits. Function submissions used 1,147 output tokens versus 1,976 for whole files. The first attempts accepted 5/6 versus 6/6 and used 146,454 versus 145,535 total tokens. A separate repair request provided the native diagnostic and recovered the failed edit. Including that request, function submissions accepted 6/6 and used 172,323 total tokens. Two provider capacity interruptions returned no usage and are recorded separately. [Per-attempt usage, grades and repair](benchmarks/native-section-edits-codex.json)

On the compiler’s own project, mode 50 returned the exact original slice for all 435 sections. The median packet was 147 tokens in o200k_base and 149 in cl100k_base, including caller and callee headers, the file range, and glyph rows. The complete bundle plus its glyph rows was 75,309 and 76,283 tokens respectively. These figures measure the text exposed for one selection and exclude tool inputs and agent work.

The [bootstrap source list](bootstrap/modules.txt) orders the compiler’s H0 modules and shared standard I/O. Run `sh bootstrap/rebuild.sh` on Linux or `.\bootstrap\rebuild.ps1` in Windows PowerShell. Both scripts use mode `48` to assemble the source list, then build both seeds with H0.

On Windows and Linux x64, `>+1` loads standard I/O. Use `:!42` to print a word in decimal or `:!\b"hello"` to print bytes. The compiler selects the output function from the operand type. Use `:ew` to write a byte view to stderr. The decimal encoder in `std/num.h0` is loaded automatically.

Import `>+3` for [Unicode text](std/utf.h0). Use `:u4` to read one UTF-8 scalar at a byte offset. Its result packs the next byte offset above the low 21 scalar bits. Use `:u5` to write one scalar at a byte offset, `:u6` to count scalars in a UTF-8 view, and `:u7` to find the byte offset of a zero-based scalar index. `:u7` validates the prefix it traverses and accepts the end position. Invalid input returns `Max`. `스a` (also `:u3`) checks the entire view for valid UTF-8 and returns 1 or 0. It accepts NUL and Unicode noncharacters and leaves the input bytes intact.

Use `:u8(dst, src)` for UTF-8 to UTF-16LE and `:u9(dst, src)` for UTF-16LE to UTF-8. Supply disjoint buffers. The result is a byte count. An empty destination queries the size, and malformed text or a nonempty short destination returns `Max` before modifying the buffer. NUL and U+FEFF are preserved as data. JSON and Windows argument handling share this H0 implementation. [Runnable example](examples/utf.h0) [UTF-8 specification](https://www.rfc-editor.org/rfc/rfc3629.html)

The byte-prefix check "`:pb`" compares full eight-byte words and handles the final bytes individually. On Windows x64, 1,500 repeated comparisons of equal 64 KiB buffers took a median of 18 ms versus 134 ms before the change. Rust 1.100.0 "`starts_with`" compiled with "`-C opt-level=3 -C target-cpu=native`" took 2 ms. For two million equal 7-byte prefixes, the same measurements were 37.5, 30, and 4 ms, respectively. These timings exclude input and process startup.

Use `:b2<TAB>ab` from `>+3` to copy source `a` into the start of a disjoint mutable destination `b`. The function returns the byte count, preserves the remaining destination bytes, and returns Max before writing if the destination is too short. For equal-length views, `]ba` directly uses the native bulk copy on x64 and RV64. The byte-key map uses the same primitive to store keys. [Byte copy example](examples/byte-copy.h0)

On one logical Windows CPU, 8,000 copies of 64 KiB took a median of 10 ms through `:b2`, 80 ms through the eight-byte H0 loop, and 8 ms through optimized Rust `copy_from_slice`. Replacing that loop with the bulk call used 5 source tokens versus 19 in both o200k_base and cl100k_base. The H0 benchmark executable grew from 9,728 to 10,240 bytes.

With `>+3`, `복ab` copies the shared byte view `a` in reverse order into the prefix of mutable view `b` and returns the count. A short destination or overlap with the written prefix returns `Max` without writing. x64 reverses eight-byte words with BSWAP and handles the remainder byte by byte. RV64 uses byte loads and stores from the base instruction set. [Intel instruction reference](https://intel.github.io/SDM/sdm.html) [RISC-V instruction reference](https://docs.riscv.org/reference/isa/unpriv/b-st-ext.html)

With `>+3`, `면a` returns `1` when shared byte view `a` is identical to its reverse and `0` otherwise. It compares the two ends in place and returns `1` for an empty view. x64 compares reversed eight-byte words and uses byte comparisons for the remaining pairs. RV64 compares pairs with base-instruction-set byte loads.

`생ab` (also `:b9`) counts words in a byte view. ASCII bytes 09–0D and 20 separate words. It writes the LF count and byte count as two little-endian u64 values to the first 16 bytes of the destination and returns the word count. A short destination returns `u64::MAX` and stays intact.

Use `:bW` with repeat chunks and the same zeroed 25-byte state. The state stores word, LF, and byte totals as three little-endian u64 values, then one continuation byte. Keep input and state disjoint. A short or invalid state or count overflow returns `u64::MAX` without modifying the state. The [word count CLI](examples/wc.h0) reads stdin and prints LF, word, and byte totals in that order.

`태abc` (also `:b6`) converts bytes between binary and ASCII hexadecimal. Mode 0 writes lowercase digits and mode 1 decodes either case. It returns the number of bytes written and preserves the rest of the destination. Invalid input or a short destination returns `u64::MAX` and leaves the destination intact.

Import `>+3` for byte reductions. `셈a` sums the shared byte view `a` with wrapping arithmetic, `밑a` returns its minimum, and `윗a` returns its maximum. An empty view sums to zero and has minimum and maximum of 256. The native compiler lowers these operations to bounded 16-byte SSE2 loops on x64 and a register-only byte loop on RV64. An empty view never reads memory, and the x64 loop processes the final partial block byte by byte. [Intel SSE2 instruction reference](https://intel.github.io/SDM/sdm.html)

Use `>+3` for Base64 on Windows x64, Linux x64, and freestanding RV64. Call `:b0<TAB>ab` to encode and `:b1<TAB>ab` to decode, with source `a` and disjoint mutable destination `b`. The result is the byte count. An empty destination queries the size and validates the input. Malformed input or insufficient space returns Max before writing any bytes. The decoder requires the standard alphabet, padding, and zero pad bits. `튼abc` (also `:bc`) selects encoding with mode 0 or decoding with mode 1 using the same source and destination. [Base64 example](examples/base64.h0) · [RFC 4648, section 4](https://www.rfc-editor.org/rfc/rfc4648.html#section-4)

Load `>+3` and use `주abc` (also `:bw`) to parse one CSV record. The input may contain arbitrary bytes. Quoted fields accept commas, CR, LF, and doubled quotes. Mode 0 writes each field as a little-endian 32-bit length followed by its decoded bytes and returns the field count. Mode 1 validates and returns the required byte count. Malformed records and insufficient output space return Max and preserve the destination.

For a bounded byte FIFO, allocate a zeroed mutable buffer of 24 bytes plus the desired capacity and load `>+3`. `:rq0` resets it, `:rq1` returns its length, `:rq2` appends a byte, and `:rq3` removes the oldest byte. Push returns 1 when full, and pop returns 256 when empty. `야abc` (also `:bp`) applies pairs of operation bytes from a to queue c and writes a pair for each result to b. Enqueue uses opcode 0 and its byte, and dequeue uses opcode 1. Results use status 0 for success, 1 for full, and 2 for empty, followed by the dequeued byte or zero. A malformed batch or insufficient destination returns Max and preserves the queue and destination. Mutations require exclusive access to the queue.

The same module provides byte run-length encoding through 신abc (also :bd). Mode 0 writes (count, value) pairs, splitting runs at 255. Mode 1 expands those pairs. A zero-length destination queries the output size. Odd encoded lengths, zero counts, unsupported modes, and insufficient space return Max and leave the destination intact.

Load the H0 [formatting module](std/fmt.h0) and its decimal encoder with `>+8`. The module uses single-syllable slots `값` for unsigned decimal, `간` for signed decimal, and `개` for hexadecimal in byte templates.

The H0 [scanning module](std/scan.h0) reads those fields from a byte view into little-endian 64-bit words and checks their range.

On Windows and Linux x64 the [file module](std/fs.h0) provides open, read, write, close, seek, and append-only open (`:첨`). Use `:편` for read-write access that preserves file contents. Its second argument is `0` to open an existing file or `1` to create the file if absent. Windows executables share one compiler-emitted UTF-8 to UTF-16LE path decoder across these open modes and pass the result to `CreateFileW`. It also implements exact reads, complete writes, and file-to-file copying in H0. The [file example](examples/file.h0) takes a hex-encoded UTF-8 path and copies the file to stdout. Its `>+14` header tells the seed to load standard I/O and file operations from the repository.

Use `>+a` to load file replacement and its file module dependency. Call `:f3<TAB>ab` with path bytes and contents on Windows or Linux x64. It writes and syncs a sibling temporary file before renaming. On Windows, H0 validates and converts the UTF-8 path to UTF-16LE. It returns the byte count or Max and rejects directories and symbolic links. The [example](examples/replace.h0) accepts a hex-encoded path and contents.

To replace a file incrementally, allocate `152 + 4 * pathBytes` zeroed state bytes. Call `:f7(path, state)` to open a sibling temporary file and `:f8(state, bytes)` for each block. Finish with `:f9(state, 1)` to sync and replace the destination, or `:f9(state, 0)` to abort. Begin and finish return zero on success. Each successful append returns the block length. All three return `Max` on error. A failed append prevents commit. Retain the state until finish succeeds, so a failed cleanup can be retried with abort. [Linux rename](https://man7.org/linux/man-pages/man2/rename.2.html) [Windows MoveFileExW](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-movefileexw)

The [atomic copy CLI](examples/atomic-copy.h0) streams stdin into a sibling temporary file and commits after a clean EOF. Existing destination files are replaced as a single name operation. A process killed before commit can leave its temporary file beside the untouched destination. This contract covers process termination. Crash consistency after power loss depends on filesystem and directory metadata persistence.

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

Load `>+u` for the [heap allocator](std/heap.h0). It manages a caller-owned byte buffer and returns offsets aligned to eight bytes relative to that buffer. `:y0` initializes or resets the heap, `:y1` allocates, `:y2` frees and coalesces neighboring free blocks, and `:y3` returns the usable size of a live allocation. Allocation uses a first-fit scan. The heap and each block use eight bytes of metadata. Reused payloads retain their previous bytes. The [heap example](examples/heap.h0) demonstrates freeing objects out of order and allocating across the merged space.

Use `:y4(mutHeap, offset, size)` to resize a live allocation. The returned offset identifies the resized payload. The allocator reuses the current offset when enough contiguous space is available, and otherwise moves the data into a new block. A successful resize preserves the first `min(oldUsableSize, size)` bytes. A return of `u64::MAX` leaves the original allocation in place. End all payload views before resizing and use the returned offset after success. The [resize example](examples/heap-resize.h0) exercises both paths.

Use `>+v` for [growable byte buffers](std/buffer.h0), which load the heap module automatically. Create a buffer with `:l0`, append with `:l1`, truncate with `:l2`, and release with `:l4`. End payload views before mutation and use the offset returned by a successful append. Append leaves the original buffer live on failure. The [portable buffer example](examples/buffer.h0) exercises relocation and reuse.

Use the same vector functions for fixed-width records of any byte width. Initialize a 16-byte state with its first word set to zero, then call `:lv(heap,state,width,initialElements)`. `:lp` appends one element, and `:la` appends a whole number of elements from a byte view. `:ln` returns the element count, `:li` returns an element's byte offset in the heap, `:lt` truncates by element count, and `:ld` releases storage and clears its state. Mutators return 0 on success, and errors return Max. A failed append preserves the existing vector. End heap views before mutating it, since growth can move the payload.

The [vector example](examples/vector.h0) uses these functions for u64 values and 13-byte records in the same heap. Each caller defines the record's byte layout. The core vector operations use the caller-provided heap on Windows, Linux, and RV64.

The [stable priority queue](std/priority.h0) also comes with `>+v`. Initialize a 24-byte state with its first word zero and call `:pq(heap,state,initialEntries)`. Add unsigned u64 priority and payload with `:pa`. Smaller priorities come first, and equal priorities leave in insertion order. `:pr(heap,state,out)` removes the minimum and `:pv` reads it without removing it. Both need 16 output bytes and return 1 with the little-endian priority and payload, 0 when empty, or Max on error. `:pl` counts and `:pf` releases the queue. The queue grows in the caller's heap, and a failed insert preserves its contents. It resets the insertion counter when drained. [Priority queue example](examples/priority.h0)

The [stdin example](examples/buffer-stdin.h0) reads arbitrary bytes until EOF using a caller-owned heap. Against an equivalent example with explicit heap growth and copying, using the buffer reduced source from 140 to 86 tokens in `o200k_base` and from 141 to 87 in `cl100k_base`. The Windows executable grew from 9,728 to 11,776 bytes and the Linux executable from 8,729 to 10,479 bytes.

In one Windows x64 process benchmark, 8,000,019 aligned allocations with periodic rewind took a median of 109 ms in H0 and 30 ms in Rust 1.100.0 at `opt-level=3`. Both produced the same checksum. The executables were 9,216 and 137,728 bytes respectively.

Load `>+z` or put `째` before the first function header on Windows x64, Linux x64, or RV64. `:zd(words, scratch, signed)` sorts a mutable view of little-endian 64-bit words in ascending order. Pass zero for unsigned order or one for signed order. Both views must be disjoint. The function detects ordered inputs, uses counting sort when all varying bits are in one byte, and uses insertion sort on short inputs. Other inputs use radix sort if scratch covers the input byte length. With less scratch, x64 uses an in-place most-significant-digit radix sort with bounded tables, and RV64 uses in-place heapsort. It returns zero or `u64::MAX` for an invalid mode or input length. When there are at least 16,384 words and byte offsets fit in 32 bits, radix sort uses 13-bit groups if that saves at least two passes over 8-bit groups. The wider path uses a 32 KiB histogram.

`름ab` (also `:zs`) sorts the mutable packed word view `a` in place and returns its word count. Pass `b=0` for unsigned order or `b=1` for signed order. It returns `u64::MAX` without changing the view for an invalid mode or a byte length that is not a multiple of eight. No caller scratch is required.

`소a` (also `:zz`) removes consecutive duplicates from mutable packed 64-bit words. It returns the number of words in the compacted prefix and preserves all bytes after it. With sorted input the prefix contains every distinct value in order. On x64, arrays of at least 32 words scan the distinct prefix in SSE2 pairs. Arrays of at least 512 words use a branchless compaction loop after the first duplicate. An invalid byte length returns `u64::MAX` and preserves the view.

`:ze(words, key, mode)` returns the lower bound for modes 0 and 1 or the upper bound for modes 2 and 3. Even modes use unsigned order and odd modes use signed order. The lower bound is the first index whose value is at least the key. The upper bound is the first index whose value is greater than the key. The result may equal the number of words. The [sort filter](examples/sort.h0) takes a word count and a signed flag, reads that many words from standard input, and writes the sorted words.

With `>+z`, `호ab` searches an ascending shared view `a` of packed little-endian `u64` words for scalar key `b`. It returns the first matching index by binary search, or `Max` for a missing key or a view with a partial trailing word. It performs no writes.

The original 8-bit sort filter benchmark on Windows included process startup and pipe I/O. With 262,144 full-width random words it took 27.42 ms in H0 and 16.22 ms in Rust. On reversed input it took 12.02 ms and 12.91 ms. The filter executables were 14,848 and 150,528 bytes, and filter source using the respective standard libraries cost 96 and 207 tokens with `o200k_base`.

A separate Windows benchmark times only sorting, excluding input, output, and copying the original array between iterations. With 262,144 full-width random words, median time per sort was 15.08 ms for the original H0 radix sort, 12.46 ms for the adaptive radix sort, and 3.04 ms for Rust. Each timed run used 24 sorts, with five runs after warmup. Both benchmarks used Rust 1.100.0 `sort_unstable` with `opt-level=3` and `target-cpu=native`. The adaptive Windows filter is 17,408 bytes.

Use `:zK(records,scratch,keys,stride)` from `>+z` for stable multikey record sorting. Records have a fixed byte stride of at least eight. Key descriptors use three bytes each, in order of precedence. The first two bytes give a little-endian offset to an eight-byte key. The last byte uses bit 0 for signed interpretation and bit 1 for descending order. Equal keys preserve input order. For `n >= 2` records, provide at least `16 * n + stride` disjoint scratch bytes. The function returns 0 on success or Max for invalid layout or short scratch. Invalid input leaves records intact. [Five-field example](examples/record-sort.h0)

Use `>+w` for [directory iteration on Windows](std/dir-windows.h0) and [Linux](std/dir-linux.h0) x64. Pass a path and a zero-initialized view of at least 4,160 bytes to `:f4`. `:f5` advances the iterator and needs at least 1,025 output bytes. A positive result is the name length, with the type byte at offset zero and the name starting at offset one. The type codes are 0 unknown, 1 file, 2 directory, 3 link or reparse point, and 4 other. `:f5` returns zero at EOF. `:f6` closes the iterator. Open and close return zero on success, and all three calls return `u64::MAX` on error.

The iterator skips `.` and `..` and follows the operating system enumeration order. On Windows, H0 converts the input path to UTF-16LE and returned names to UTF-8 using its native Unicode module. Linux returns the original name bytes supplied by the kernel. The [directory example](examples/directory.h0) prints entries in the current directory. [Win32 directory enumeration](https://learn.microsoft.com/en-us/windows/win32/fileio/listing-the-files-in-a-directory) [Linux directory records](https://man7.org/linux/man-pages/man2/getdents.2.html)

`:fy(state,out)` advances the same iterator with at least 1,033 output bytes and the same name and type fields. It writes the logical byte size of a regular file as little-endian u64 at offset 1,025, or zero for other entry types. On Linux the lookup is relative to the open directory and also resolves unknown entry types without following symbolic links.

The [tree size CLI](examples/tree-size.h0) prints the sum of regular file sizes under a supplied directory. It counts hard links once per directory entry, uses logical sizes for sparse files, and skips discovered links and reparse points. Paths are limited to 4,095 UTF-8 bytes. Windows accepts an extended-length absolute path for deep trees. The sum represents a walk of the tree, so keep inputs stable for a reproducible result.

Use `>+x` to start native threads on Windows and Linux x64. Define a local `1-tt` worker that takes one scalar and returns one scalar. Each call to `:ta(state, argument, stack_bytes)` starts that worker with its own argument. Allocate at least 64 zeroed bytes aligned to 8 for each thread state. A stack size of 0 requests the default 8 MiB. An explicit stack size must be at least 64 KiB.

Call `:tb(state)` to wait for completion and release the thread resources. Keep the state and any memory the worker accesses live through the join. After joining, `:tc(state, output)` writes the worker's full 64-bit result into an output view of at least 8 bytes. Each operation returns zero on success or `u64::MAX` on failure. The [thread example](examples/threads.h0) starts two workers and checks both results. [Windows CreateThread](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createthread) [Linux clone](https://man7.org/linux/man-pages/man2/clone.2.html)

Load `>+s` for `:at(address, increment)`, `:ax(address, value)`, and `:ac(address, expected, replacement)`. Fetch-add, exchange, and compare-exchange return the previous u64 value. Fetch-add wraps modulo 2⁶⁴. Compare-exchange updates the word only when the returned value equals the expected value. The address must be nonzero, eight-byte aligned, and in live coherent memory. Use atomic accesses for a word shared with a running thread. The [shared counter example](examples/atomic-threads.h0) runs four workers and verifies a counter for each update method. Windows and Linux x64 use locked instructions. [Intel instruction set reference](https://cdrdv2-public.intel.com/671110/325383-sdm-vol-2abcd.pdf)

Load `>+y` for a mutex shared by threads in one Windows or Linux x64 process. Allocate 32 zeroed bytes at a stable, eight-byte-aligned address. Pass that address to `:ua` to initialize the mutex, `:ub` to acquire it, `:uc` to try acquiring it, `:ud` to release it, and `:ue` to destroy it after all users are done. Calls return zero on success or `u64::MAX` on error. Try-acquire also returns one when the mutex is busy. Each acquisition requires a release by its owner. The mutex is nonrecursive. Acquisition order is unspecified.

Acquiring a free mutex uses an atomic compare-exchange. Contending threads wait through Linux futexes or Windows WaitOnAddress, available from Windows 8. The [mutex example](examples/mutex-threads.h0) uses four threads to increment an ordinary counter inside critical sections. [Linux futex](https://www.man7.org/linux/man-pages/man2/futex.2.html) [Windows WaitOnAddress](https://learn.microsoft.com/en-us/windows/desktop/api/synchapi/nf-synchapi-waitonaddress)

Use `>+7` to include the [buffered stream module](std/stream.h0) and its file and standard I/O dependencies. Compact calls include `즈` for read, `즌` for write, and `튀` for reading through a delimiter. Pass mode `2` to `:s0` for append-only output. Modes `3` and `4` allow buffered reads and in-place writes on the same stream. Mode `4` also creates a missing file. Switching to writes discards read-ahead after restoring the logical position. Switching to reads flushes pending writes. Use `:s6` to query the logical position without flushing and `:s7` to read exactly a destination buffer’s length. Use `:s8` to read through a delimiter, preserving unread bytes for the next call. Its x64 byte search uses 64-byte SSE2 blocks for long spans. A flush completes partial writes through the file module.

Bind a zeroed stream with `:sd(state, selector)` for stdin (`0`), stdout (`1`), or stderr (`2`). Use `:s1`, `:s7`, or `:s8` to read from stdin and `:s2` to write to stdout or stderr. Flush with `:s3` or close the wrapper with `:s5`. Closing flushes pending output and preserves the process handle. Seeking and querying position are unsupported. Keep one buffer per standard stream while it is in use.

Import buffered standard I/O with `>+1` or use `문` immediately before the first function header. The buffered operations have compact spellings `목` (`:ir`), `장` (`:iw`), `터` (`:if`), `색` (`:ip`), `분` (`:ic`), `적` (`:iq`). Allocate zeroed caller-owned views with 16 bytes of reader state or 8 bytes of writer state plus the desired buffer capacity. A buffer needs at least one payload byte. Linux x64 executables that link stdout, stderr, or file writes ignore SIGPIPE at startup so a write to a closed pipe returns an I/O error. `:ir(state, dst)` fills the destination or returns the bytes read before EOF. `:iw(state, src)` returns bytes accepted. It submits pending bytes and the incoming span together once the span reaches twice the buffer capacity, or once it reaches the buffer capacity while the buffer is already full. Linux uses vectored output for this pair. `:if(state)` flushes stdout and returns zero. Errors return Max. Reads may copy a prefix before an error. A failed write or flush discards the writer for further use until its state is reset. [Buffered stdin-to-stdout example](examples/buffered-stdio.h0)

`메abc` (also `:ig`) appends shared views `b` and `c` to buffered stdout state `a` in that order. It returns the total byte count or `u64::MAX` on error. Flush with `:if`.

With `>+1`, `져ab` (also `:iz`) writes two spans to stdout in order and returns their combined byte count or Max. Linux x64 uses native vectored output without joining the spans in memory. Windows x64 uses complete writes. A failure can follow a partial transfer. Use `은ab` (also `:iy`) for byte streams when separate write boundaries are unnecessary. It can join two nonempty spans up to 1,024 bytes in total on Windows and Linux x64. Larger pairs use the ordinary two-span output path.

Use `:ip` on the zeroed stdin buffer to get the offset of a contiguous byte span. It returns zero at clean EOF and `Max` on a short span, read error, or invalid buffer state. `:ic` consumes pending bytes. A zero-byte preview returns the current offset. Use the offset before mutating the input state again. `의abn` (also `:ij`) transfers exactly `n` bytes from the buffered input state `a` to the buffered output state `b`. Keep the two states disjoint and size the input payload buffer for at least `n` bytes. It returns the byte count, zero at clean EOF or for an empty request, or Max for a short or failed transfer. The logical input position advances only after the writer accepts the complete span. For transfers larger than the buffers, use `젝abn` (also `:iT`). It copies up to `n` bytes, or drains to EOF with `수`, using the two supplied buffers. It returns the count on success or `u64::MAX` on error. Each accepted chunk advances the input and a later failure may leave a partial transfer. Flush the output when required. `:iq` writes a little-endian u64 to the buffered stdout state, and `:if` flushes it. The [framed echo example](examples/framed-stdio.h0) reads a little-endian u16 payload length followed by up to 4,096 bytes, then echoes the complete frame.

On the same six held-out H0 solutions, the compact driver used 111 `o200k_base` source tokens versus 130 for the shared stream driver. The Windows executable dropped from 20,992 to 15,360 bytes, and each Linux executable dropped by 5,033 bytes. With 44,640 oracle-checked requests per process, the compact driver's WSL Linux medians were 12.48 to 14.22 ms, compared with 13.35 to 15.30 ms for the shared driver. The Windows median of the six pair medians was 22.17 ms for compact H0 and 23.07 ms for optimized Rust. Measurements include startup and binary stdin/stdout. [Paired compact I/O samples](benchmarks/native-compact-stdio.json)

Reusing the accepted held-out dispatch solutions with 16 KiB buffers reduced replay time by a factor of 4.4 to 4.9 in three WSL Linux comparisons. Each process handled 44,640 identical framed requests. All outputs matched the oracle. In a separate loaded-host Windows pass, buffered H0 medians ranged from 23.33 to 37.31 ms across six pairs, and optimized Rust ranged from 23.32 to 28.81 ms. The Windows H0 executable grew from 11,264 to 20,992 bytes. Its benchmark driver grew from 97 to 130 `o200k_base` source tokens. These runs measure the accepted programs with process startup and binary stdin/stdout. [Paired runtime samples](benchmarks/native-buffered-stdio.json)

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

For `:j1` and `:j4`, use disjoint buffers. An empty destination validates the input and returns the required byte count. Malformed input or a nonempty destination that is too short returns Max without changing the destination. The [quoting example](examples/json-quote.h0) uses the byte count to turn up to 4 KiB of UTF-8 from stdin into a JSON string.

Use `>+jm` for [indexed JSON lookup](std/json-index.h0) when reading many keys from the same object. Pass the source and used tape from `:j0` to `:jx(src, tape, object, slots, index, scratch)`. It initializes a byte-key map, copies decoded keys, and returns the distinct key count or `Max`. If indexing fails after initialization, it clears the partial index. Use `:jz(tape, object)` to count direct members including duplicates. Choose a power-of-two slot count of at least four with room for at least four-thirds of that count. The index needs `40 + 32 * slots` bytes plus the key storage described by the map contract. Scratch can be empty for keys without escapes. For escaped keys, it must hold the largest decoded escaped key. Use `:jy(index, key)` for the value’s tape ordinal or `Max`. The first occurrence wins, including when escaped and unescaped spellings decode to the same bytes.

On one machine, a 1,024-member object with 2,048 distributed lookups took a median of 159 ms with `:j2` and 8.1 ms with the index on Windows. Under Linux in WSL, it took 154 ms and 4.9 ms. Each median covers 11 runs after warm-up and includes process startup, parsing, index construction, and lookup. The index used 81,960 bytes and required no escape scratch for this input. The Windows benchmark binary grew from 17,408 to 30,208 bytes.

This two-line program prints the exact source text for the value associated with `n`.

```text
>+1j
0 a\b"{\"n\":42}" bM48 c:j0	ab ?Ec수.2 d:j2	aVb0*c16	0\b"n" ?Ed수.3 e:j5	Vb0*c16d Y:wr	VaTe32&e4294967295 :fl
```

Load `>+e` for the [BMP decoder](std/bmp.h0). It reads uncompressed 24-bit BGR and 32-bit BGRX BMP images with DIB headers of at least 40 bytes. It handles bottom-up and top-down rows and strips row padding. Call `:p0` with a byte view to validate the image and get the width in the high 32 bits and height in the low 32 bits. Call `:p1` with the image and a disjoint writable buffer to decode packed RGB8 in top-down row order. Both return zero on failure.

Load `>+h` for [DEFLATE and zlib decoding](std/deflate.h0). `:z0` reads raw DEFLATE and `:z1` reads a zlib stream and verifies Adler-32. Both take the compressed byte view and a disjoint writable output view and return the decoded length or `u64::MAX`. Each call expects exactly one stream. The decoder rejects preset dictionaries, truncated input, trailing bytes, and short output buffers. Discard output on failure. The same H0 module builds for Windows x64, Linux x64, and RV64. [DEFLATE specification](https://www.rfc-editor.org/rfc/rfc1951) and [zlib specification](https://www.rfc-editor.org/rfc/rfc1950).

The same `>+e` selector loads the [GIF decoder](std/gif.h0). Call `:g0` for the logical screen dimensions in the same packed format as BMP, and `:g1` with disjoint encoded and output views for the first raster frame as top-down BGRA8. The decoder handles GIF87a and GIF89a, local and global palettes, transparency, frame offsets, and interlaced rows. Decode failure returns zero and may leave partial output. [GIF89a specification](https://www.w3.org/Graphics/GIF/spec-gif89a.txt)

Load `>+i` for the [PNG decoder](std/png.h0). It reconstructs noninterlaced and Adam7 grayscale, RGB, indexed, grayscale-alpha, and RGBA images at all legal sample depths. It checks every chunk CRC, combines split IDAT payloads, and decodes transparency from alpha samples or the transparency chunk. [PNG specification](https://www.w3.org/TR/png-3/).

Call `:q0` with the file bytes to read the checked header and return the width in the high 32 bits and height in the low 32 bits. `:q2` returns the required scratch capacity. Call `:q1` with the file, disjoint scratch, and a disjoint pixel buffer of at least `4 * width * height` bytes. It returns the dimensions and fills packed top-down BGRA8 with straight alpha. Zero means failure. Discard output on failure. Windows and Linux x64 and RV64 use the same module.

The [BMP example](examples/bmp.h0) builds for Windows and Linux x64. It takes a hex-encoded UTF-8 file path and writes a binary PPM image to standard output. The example accepts files up to 120 KiB. The decoder uses the caller's buffer sizes.

The [Win32 module](std/win.h0) is available with `>+f` on Windows x64. It opens a system DLL by its null-terminated UTF-16LE basename, looks up an ASCII export by its null-terminated name, and calls scalar or pointer signatures using sixteen little-endian 64-bit argument slots. Zero unused slots. A buffer address returned by the module is valid while the caller keeps that buffer live. Release DLL handles after the last call.

Load `>+5` for rectangular matrix multiplication with `션abcdef` (also `:nx`). The inputs are finite, row-major little-endian binary64 matrices with dimensions d×e and e×f. The operation writes d×f cells to the start of the destination, returns the byte count, and keeps the destination tail. Each multiplication and addition rounds separately in increasing inner-index order under round-to-nearest, ties-to-even. Use inputs for which products and sums stay finite. An insufficient buffer returns Max and leaves the destination intact. The x64 implementation uses SSE2 and RV64 uses scalar binary64 instructions.

On Windows and Linux x64, load `>+g` for [operating-system memory](examples/memory.h0). Call `:m0` with the byte count for a zero-initialized region and `:m1` with its address and original size to release it. Allocation returns zero on failure. Release each live region once, using its exact original byte count. The Windows x64 allocator uses the process heap below 64 KiB and virtual memory for larger regions. Allocations are at least 16-byte aligned. The binding `b\!an` gives a fresh mutable byte view `b` of the address `a` and length `n`. Byte accesses are bounds-checked. The caller must provide a live, exclusive memory range and end all accesses through the view before releasing that range.

For repeatedly cleared scratch memory, hold an exclusive 24-byte zero-initialized state. `습ab` (also `:m2`) takes that state and a positive byte count and returns the address of a zeroed span. It reuses the mapping when it fits and grows the mapping when needed. End every view into the previous span before reacquiring or calling `을a` (`:m3`) to release it. Acquisition failure returns 0 with the prior state and contents intact. Release returns 1 on success and can be repeated.

Load `>+m` for the [u64 map](std/map.h0) on Windows x64, Linux x64, or RV64. Supply a writable buffer of exactly `8+17n` bytes, where `n` is a power of two and at least 4. Initialize or reset it with `:k0`. The map holds up to `3n/4` entries and accepts every u64 key and value. Insert or update with `:k1`, read into an eight-byte output view with `:k2`, remove with `:k3`, and count with `:k4`. The library uses the caller's buffer for the entire lifetime of the map.

The integer map uses each existing occupancy byte as a short hash fingerprint. It checks the full key on fingerprint matches and moves the fingerprint with its entry when deleting. The current module also accepts buffers initialized with the earlier occupancy format.

The [u64 map CLI](examples/u64-map.h0) accepts an eight-byte little-endian slot count followed by 17-byte records (operation byte, little-endian key, little-endian value). Operations 0 through 4 reset, insert or update, look up, remove, and count. Each reply contains a status byte and eight little-endian result bytes. Status 1 means inserted, found, or removed. Status 0 covers updates, misses, reset, and count. Status 255 reports a map error such as a full map. The result bytes carry the value or count and are zero for other replies.

The same `>+m` selector provides a [byte-key map](std/byte-map.h0). Pass `:k5(storage, slots, seed)` a buffer of at least `40 + 32 * slots + 16` bytes and a power of two slot count of at least four. The map supports up to three quarters of the slots. Key bytes use the remaining space, rounded to a multiple of 16 bytes with a 16-byte minimum. The map copies keys, accepts empty keys and embedded NUL, and compares bytes even when hashes match. Deletions merge adjacent free key ranges.

Use `:kw(storage,key,delta)` to insert a counter or increment an existing one with one lookup. It returns 1 for insertion, 0 for an update, `Max - 1` when more capacity is needed, or `Max` for invalid state or overflow. Use `:kA(storage,cursor,record)` to enumerate entries in slot order. Start at cursor 0 and feed each returned cursor into the next call. The 24-byte record contains the key offset, key length, and value as little-endian u64 fields. Keep the map unchanged during enumeration and use key views before mutating the map. The iterator returns 0 at EOF or `Max` on invalid input.

The [word frequency CLI](examples/word-frequency.h0) reads stdin, treats ASCII whitespace as a separator, and writes each original byte string followed by a tab, decimal count, and newline. It grows the table as needed and accepts words of up to 65,536 bytes. Output order follows the map's slot order.

The [ordered u64 map](std/ordered-map.h0) also comes with `>+m`. Initialize `:o0` with a mutable view of at least `32 + 40 * capacity` bytes and room for at least one entry. `:o1` inserts or updates, `:o2` looks up into eight output bytes, and `:o3` removes. These return 1 for inserted, found, or removed, 0 for updated or absent, and Max on error. An update can succeed even when the map is full. Removed slots are reused. `:o5` returns the entry count and `:o6` returns the AVL tree height.

Use `:o4(map,lower,upper,out)` to emit ascending key-value pairs as 16-byte little-endian records with inclusive bounds. It returns the number of complete records written, limited by output capacity, or Max for invalid state. The remaining output bytes are untouched. To continue paging, use one more than the last returned key as the next lower bound. Stop if the page is empty or the last key is already Max. Keep the map unchanged between pages. [Ordered map example](examples/ordered-map.h0)

Use `:k6(storage, key, value)` to insert or update a u64 value. It returns one on insertion and zero on update. Use `:kj` to insert only when absent, with zero on an existing key. Use `:k7(storage, key, out)` to look up a value in a disjoint eight-byte view, `:k8(storage, key)` to remove it, and `:k9(storage)` to count entries. Lookup and deletion return one on a hit and zero on a miss. Initialization returns zero. Errors return `Max`, including when an insert runs out of slots or contiguous key space. A lookup miss leaves the output view untouched.

The [Windows image viewer](examples/bmp-viewer.h0) opens uncompressed 24-bit and 32-bit BMP, PNG including Adam7, and the first frame of GIF at original pixel size. H0 reads and decodes files, composites transparency against gray, and calls Windows to display the result. It accepts files up to 64 MiB, pixel buffers up to 256 MiB, and PNG scratch buffers up to 320 MiB.

The [Linux image viewer](examples/image-viewer-linux.h0) uses the same BMP, PNG, and GIF decoders and connects directly to X11. It reads `DISPLAY` for a local display such as `:0` or `unix:0.0` and selects an applicable `MIT-MAGIC-COOKIE-1` entry from `XAUTHORITY`, or from `$HOME/.Xauthority` when `XAUTHORITY` is unset or empty. The window closes on a key press or a window manager close request. [X.Org client authentication](https://www.x.org/guide/communication/)

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

Load `>+q` in Windows and Linux x64 executables. `:a4` copies the argument at a zero-based index and `:a5` copies a value for an exact, case-sensitive environment key. Both return the byte count excluding the NUL terminator. `u64::MAX - 1` means absent. `u64::MAX` means an error or insufficient output space. The [process input example](examples/process-input.h0) prints argument 1 and the value of `H0_VALUE`.

The [options module](std/options.h0) comes with `>+q`. Initialize a mutable view of at least 49 bytes using `:oi(state,mode)`. Mode 0 keeps recognizing options after operands. Mode 1 stops at the first operand. `:op(state,flags,valued)` reads the next event from two byte sets of short option letters. A letter in both sets takes a value. Use the returned ASCII option byte or event 256 for an operand, 0 for EOF, 257 for an unknown option, 258 for a missing value, or 259 for a state or argument read error. Treat errors as terminal. The result span starts at the offset stored at byte 24 and has the length stored at byte 32, both little-endian u64. Use that span before the next call.

Short flags can be grouped. The first option that takes a value consumes the rest of its group, or the next argument if the group is exhausted. A bare dash is an operand. Two dashes stop option parsing. Long option names produce an unknown-option event while option parsing is active. The caller controls the per-argument capacity through the state size minus 48. See the [options example](examples/options.h0) and [hex dump CLI](examples/hexdump.h0).

On Windows, H0 parses the native command line using Windows rules for spaces, quotes, and backslashes. The module reads a copy of the current environment and converts both results from UTF-16LE with the H0 text codec. [Windows argument parsing](https://learn.microsoft.com/en-us/cpp/c-language/parsing-c-command-line-arguments?view=msvc-170)

On Linux, both calls return raw bytes from the original ELF startup stack and work without procfs. The executable reserves one 4 KiB writable page for the saved startup pointer. In WSL, 20,000 argument lookups and 20,000 environment lookups in the same program took a median of 4.82 ms across 11 runs, down from 62.03 ms with procfs. The program shrank from 3,774 to 3,611 bytes. [System V AMD64 process startup ABI](https://gitlab.com/x86-psABIs/x86-64-ABI/-/blob/master/x86-64-psABI/low-level-sys-info.tex)

In Windows x64 builds, `\@q` gives the Win64 callback address of the local H0 function `q`. The function can take up to eight integer or pointer arguments and return a scalar. References to the same function in one executable yield the same address. The [callback example](examples/win-callback.h0) registers an H0 window procedure, sends it a message, and checks the result.

Use `>+2` for the [HTTP request framing module](std/http.h0). The [loopback example](examples/http.h0) uses `>+012` to receive one HTTP/1.1 request with a bounded Content-Length body.

Load `>+d` for the [HTTP response module](std/http-response.h0). Call `:r0` with the TCP socket, a zeroed reader buffer of at least 17 bytes, the method flag (`0` ordinary or `1` HEAD), and a disjoint writable body buffer. The result packs the status code in the high 32 bits and the body length in the low 32 bits. Reuse the reader buffer on the same socket to preserve bytes read ahead. A result of `Max` invalidates the reader state. Close the connection and discard the output on failure.

To stream a response, call `:r1(socket, state, method)` with at least 33 zeroed state bytes. It returns the final status code or `Max`. Call `:r2(socket, state, output)` with a nonempty, disjoint writable view. It returns the number of decoded body bytes, zero when the response is complete, or `Max` on error. Keep the state with the same socket so the next response can use bytes read ahead. Drain the body before starting the next response. If framing or I/O fails, close the connection and discard any partial body.

The module handles Content-Length, chunked transfer, and responses ending at EOF. It limits headers and trailers to 16 KiB and supports fixed lengths and chunk sizes up to `u64::MAX - 1`. The [HTTP GET example](examples/http-get.h0) takes a decimal IPv4 DNS resolver address, its TCP port, the HTTP port, and the hex-encoded hostname. It writes the decoded body to standard output through an 8 KiB buffer. An optional fifth argument is a destination path. In this mode the example replaces the destination only after successfully receiving a complete 2xx response. [RFC 9112 HTTP/1.1 message framing](https://www.rfc-editor.org/rfc/rfc9112.html)

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

The `>+s` atomic operations also target RV64 with the RISC-V A extension and use acquire/release ordering. [RISC-V atomic instructions](https://docs.riscv.org/reference/isa/unpriv/a-st-ext.html)

The [RV64 multicore example](examples/rv64-smp.h0) uses four harts with a 4 KiB stack each. It checks both 40,000 fetch-add updates and 40,000 compare-and-exchange updates, then reads per-hart values published in the shared page.

```sh
(printf '@2147483648 4 4\n'; cat examples/rv64-smp.h0) | bootstrap/seed/h0-linux-x64 25 > h0-smp.elf
qemu-system-riscv64 -machine virt -smp 4 -m 16M -bios none -kernel h0-smp.elf -display none -serial stdio -monitor none
```

Load `>+t` for [RV64 machine traps](std/trap-rv64.h0). Define a local `3-ti` function that receives `mcause`, `mepc`, and the hart's scratch word, and returns the resume PC. `:t3` sets the scratch word and installs the direct trap vector with interrupts disabled. It returns `1` if the hardware rejects the vector. Use `:t4` to set the `mie` mask, `:t5` to toggle global machine interrupts, and `:t8` and `:t9` to write and read the scratch word. `:t6` and `:t7` perform fenced, aligned 64-bit MMIO reads and writes. The trap entry saves the integer registers on the interrupted stack and supports non-nested machine traps. [RISC-V machine-level architecture](https://docs.riscv.org/reference/isa/priv/machine.html)

The [timer example](examples/rv64-timer.h0) programs the QEMU `virt` machine timer for three interrupts, resumes H0 after each one, then writes `H0 MTI 3` to UART. Build it in mode `25`, using the same QEMU command as the UART example above. [QEMU RISC-V virt board](https://www.qemu.org/docs/master/system/riscv/virt.html)

For functions with fixed-size byte buffers, the native seed sizes the stack arena from the buffer declarations. Aligned fixed declarations above 4 MiB in one function report `E108`. The compiler sums declarations conservatively across branches. When an RV64 frame would exceed the range of its stack offsets, the compiler places the affected fixed buffers in a separate stack arena sized from those declarations. Functions with runtime-sized allocations keep a 512 KiB arena by default and can grow it through fixed declarations. On Windows and Linux x64, use `>+g` for larger or independently sized buffers.

Modes `30`, `31`, and `32` check Windows x64, Linux x64, and RV64 source and return repair context. Success prints `ok`. An error exits with status 2 and prints the same diagnostic as the corresponding check mode. When the location matches an identifiable section in the root source, the output continues with its zero-based ordinal on a separate line and its exact source bytes followed by LF. Use that ordinal with mode `28` to apply a replacement, then check again. For recognized missing standard calls, the error context can end with a hint naming the module to import.

For unknown calls injected into 18 Windows-compatible public examples, sending the diagnostic and selected section instead of the diagnostic and full file reduced input from 5,678 to 3,155 tokens in `o200k_base`, and from 5,734 to 3,216 in `cl100k_base`. The counts cover the diagnostic and source sent to the agent.

Modes `33`, `34`, and `35` report direct H0 call dependencies on Windows x64, Linux x64, and RV64. Send a zero-based section ordinal, LF, and the full valid source on stdin. Each row gives a callee ordinal and its header, including argument and result markers. The ordinals follow the compiler bundle, with root sections before imported sections. Rows are unique and sorted by ordinal. The list includes Windows callback addresses and reflects references surviving native lowering.

Across seven Windows-compatible examples with local callees in the entry function, supplying the entry and local callee headers took 1,382 tokens instead of 1,990 in `o200k_base` and 1,396 instead of 2,016 in `cl100k_base`. The comparison uses full local callee bodies on the baseline side.

Modes `36`, `37`, and `38` take the same input and return all direct and indirect callers for Windows x64, Linux x64, and RV64. Rows contain the bundled ordinal and source header, sorted by ordinal. The selected function is excluded even in a call cycle. The compiler follows references recorded during native lowering, including Windows callback addresses. Targets chosen only at runtime fall outside this index. Use mode `23` to identify root-file ordinals and mode `24` to fetch the relevant bodies.

Across 33 named functions with local callers in 10 Windows-compatible examples, sending the import prefix and the indexed bodies of the selected function and its local callers took 15,300 tokens versus 43,441 for the full files in `o200k_base`. In `cl100k_base`, it took 15,348 versus 43,536. The scoped input was smaller in 26 of 33 cases in both tokenizers. These counts measure source input, with task success and reasoning cost still to be measured.

Use modes `11`, `12`, and `13` to repair source for Windows x64, Linux x64, and RV64. The compiler tries one edit for a repeated view parameter marker, a missing space after a block count, or a missing tab after a call label. For an operand error with no passing candidate from those rules, it tries replacing a single space with a TAB on the failing line. For a recognized missing standard call, it can add one import. It rejects the import if module order could change a positional call or if the source still fails the target check. It writes the original source when valid or the repaired source when exactly one candidate passes the target check. Otherwise it reports the original diagnostic and status `2`. Check the program behavior with its tests after applying a repair.

Modes `14`, `15`, and `16` cover single-byte syntax repairs and emit `offset op` followed by a newline. The offset is a zero-based UTF-8 byte index in the original input. Operation `1` deletes the byte at that index. Operations `2` and `3` insert a space or TAB before it, respectively. Operation `4` replaces an ASCII space with a TAB. Valid input produces empty output. A rejected repair returns the original diagnostic and status `2`.

With a missing block separator injected into each of 16 public examples, the median repair output went from 138 tokens to 4 in `o200k_base` and from 143.5 to 4 in `cl100k_base`. These counts cover compiler output only.

The [file concatenation CLI](examples/cat.h0) copies files to stdout in argument order. With no paths or with `-`, it copies stdin. It reports missing files on stderr, continues to later inputs, and exits nonzero if an input fails. `트a` (also `:fk`) in `>+4` tries native Linux file transfer at the current offset when stdout is seekable. A result of 1 requests a buffered continuation, and 0 reports EOF. The CLI copies through one reusable buffer on both hosts. Use distinct files for input and redirected output.

The [fixed-string grep CLI](examples/grep.h0) searches stdin or named files, prints 1-based line numbers, and returns 0 on a match, 1 when no line matches, or 2 for usage and I/O errors. The search is byte-exact and carries a line across read boundaries. Use `할ab` from `>+3` to build a little-endian prefix table for needle a, then `에abc` to find needle b in data a using its table c. The result is the first byte offset or Max. An empty needle matches at offset zero.

The [external line sorter](examples/sort-lines.h0) reads stdin and writes a bytewise sort to stdout. Give it two distinct scratch paths to create or overwrite, separate from the input and any redirected output. It sorts runs in a 4 MiB data buffer and merges them through disk files. Lines may contain up to 65,536 bytes before LF. Duplicate and empty lines are preserved, and an unterminated final line receives LF.

The [SHA-256 CLI](examples/sha256.h0) hashes a file or stdin and prints its lowercase hexadecimal digest. In `>+3`, `아a` initializes a 104-byte state, `여ab` adds bytes, and `오ab` snapshots the 32-byte digest into b without consuming the state. `와ab` hashes a byte span in one call. The compiler emits x64 SHA instructions for CPUs that advertise them and uses scalar H0 on other targets. The algorithm follows [FIPS 180-4](https://csrc.nist.gov/pubs/fips/180-4/upd1/final).

The [checksum CLI](examples/checksums.h0) reads a file or stdin and prints CRC-32 and Adler-32. With `>+3`, `를a` prepares a reusable CRC table, `으abc` updates an IEEE CRC-32 from initial value 0, and `임ab` updates Adler-32 from initial value 1. The zlib decoder uses the same Adler-32 implementation. On x64, Adler-32 uses SSE2 and CRC-32 uses carry-less multiplication when available. CRC-32 also has a table-based path.

The [hex dump CLI](examples/hexdump.h0) emits the canonical `hexdump -C` layout on Windows and Linux x64. It reads stdin by default and treats multiple files as one stream, preserving partial rows across file boundaries. Use a single dash to read stdin among the paths, `-v` to show every row, and `--` to end option parsing. Place options before paths.

## Developer

Hyeonwoo Kim (kookmin20103324@gmail.com) created and maintains Project H0. Run either native compiler seed with argument `4` to display the author credit.

Licensed under [Apache 2.0](LICENSE).
