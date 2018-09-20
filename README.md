# terrisc

This is an incomplete atempt to implement a RV32I(later up to RV64G) emulator.

It uses the terra programming language, which extends Lua by a staticly-typed
language that integrates with normal Lua code.

Terra is great for writing an emulator like this, because you can use Lua
to hide some of the ugly implementation details, making the code more readable,
while still having the performance of a LLVM-compiled native binary.

In the future, it should be possible to export the emulator-part from terra as
either a stand-alone library(As a .so file), or application. Also possible,
allthough in the stand-alone versions not as easily, is a JIT for the
emulator: Terra already has all the facilitys to make that happen(mostly LLVM).



## Files
| Filename            | Description |
| ------------------- | ----------- |
| cpu.t               | Main entry: implements registers, step function, run, ...
| mem.t               | memory functions (e.g. reading a byte or word)
| instruction_decoder | generates an instruction decoder function, to resolve instructions to instruction callback pointers
| instructions_RV32I  | implements the RV32I base instruction set(incomplete). Each instruction registers itself to an instrucion_decoder via a bitmask, bitpattern and a callback pointer
| cpu_test.t          | 


## Current status

IDK how often this status will be updated, the source code is the canonnical
documentation:

### Implemented:

 * instruction decoder
 * decoding of most(all?) immediates for RV32I


### Missing(for base ISA):

 * compressed instruction decoder
