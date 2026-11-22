# H0 Tape · stage1

UTF-8. Blank line between multiline sections. Flat sections use one line each. SP separates instructions. TAB separates adjacent decimals and inline block counts. `#` starts a comment outside literals.

## Compile

- Linux: `mkdir -p build; bootstrap/seed/h0-linux-x64 1 < examples/arithmetic.h0 > build/app; chmod +x build/app; ./build/app`
- Windows (cmd): `mkdir build`, `bootstrap\seed\h0-windows-x64.exe 0 < examples\arithmetic.h0 > build\app.exe`, `build\app.exe`

The result is exit status 46. Modes read stdin and write stdout. `0` Windows x64 PE, `1` Linux x64 ELF, `2` RV64 raw code, `3` expand Hangul to ASCII Tape. `4` prints author information. Native modes receive unsigned decimal arguments and return the entry value as exit status. RV64 receives ABI arguments in `a0…` and returns a u64 in `a0`. Supply mapped memory and a valid stack for raw code.

Use `bootstrap/stage1.h0` as the input to mode `0` or `1` to rebuild either seed.

## Write

- `N` entry, `Nname` named section, `N-` private, `N+name` host binding. N counts logical arguments. Sections are numbered from 0 in source order, including host bindings. `:2ab` calls section 2. Use `::` self, `:<` previous, `:>` next. A trailing `'` forwards remaining positional arguments.
- Arguments and bindings use `a,b,…`. `bx` binds or replaces b. `+bx` adds x to b. `.x` returns x. The final expression returns implicitly. `Y` discards a call result.
- Prefix u64 expressions. `+ - *` wrap, `/ %` trap on zero, `S T` left/right shift modulo 64. `& | ^` bitwise. `E D < > L G` compare eq/ne/lt/gt/le/ge. `A O !` short-circuit logical and/or/not. `\iaxy` chooses x if a is nonzero, else y.
- `?x` conditional, `@n` loop with next register in 0..n, `Wx` while. Default one instruction. For a flat block write TAB then instruction count, TAB then false count if present, SP before body. Multiline blocks put counts on the header and one instruction per line. `'` breaks, backtick continues, optional depth.
- `'a` borrows bytes, `"a` allows writes, `'ab` groups adjacent inputs. `Za` byte length, `Bab` checked read, `Xabc` checked store, `Vabc` slice [b,c), `\vab` tail. `bMn` allocates n zero bytes. `\b"..."` is bytes with `\0 \n \r \t \xHH` escapes.
- `~` result suffix declares Option. `Hx` Some, `J` None. `[x` branches on Some and binds its payload in the next register. `;` return suffix declares Result. `Ix` Ok and `Fx` Err.

```h0
1 b0 @a	1 +bc b
```

Use a literal TAB before `1` in the loop header. Here c is the loop index.

## Build with std

Append the required H0 fragments after your entry, with a blank line between files. Calls use section numbers after concatenation. No import resolution is needed.

| Fragment | Sections in order |
| --- | --- |
| `std/io.h0` | `stdin("a)`, `stdout('a)`, `get()`, `flush()`. Transfers return byte count. `get()` returns 256 at EOF. |
| `std/num.h0` | `parse('a)` → Option<u64>, `format("a,b)` → bytes written, 0 if too short. |
| `std/bytes.h0` | find('bytes,key) → Option<index>, rfind('bytes,key) → Option<index>, starts_with('bytes,'prefix) → 0/1. |

The hello entry uses stdout at section 2 and flush at section 4. Linux `(cat examples/hello.h0; printf '\n'; cat std/io.h0) | bootstrap/seed/h0-linux-x64 1 > build/hello`. Windows cmd `(type examples\hello.h0 & echo. & type std\io.h0) | bootstrap\seed\h0-windows-x64.exe 0 > build\hello.exe`.
