# terrisc

This is an incomplete attempt to implement a RV32I v2.2(later up to RV64G) emulator.

It uses the terra programming language, which extends Lua by a staticly-typed
language that integrates with normal Lua code.

Terra is great for writing an emulator like this, because you can use Lua
to hide some of the ugly implementation details, making the code more readable,
while still having the performance of a LLVM-compiled native binary.

In the future, it should be possible to export the emulator-part from terra as
either a stand-alone library(As a .so file), or application. Also possible,
although in the stand-alone versions not as easily, is a JIT for the
emulator: Terra already has all the facility to make that happen(mostly LLVM).





## Files

| Filename              | Description |
| --------------------- | ----------- |
| cpu_new.t             | Current implementation of CPU. Currently not working
| mem_new.t             | (TODO) will implement memory
| cpu.t                 | old main entry: implements registers, step function, run, ...
| mem.t                 | old memory functions (e.g. reading a byte or word)
| instruction_decoder.t | generates an instruction decoder function, to resolve instructions to instruction callback pointers
| instructions_RV32I.t  | implements the RV32I base instruction set(incomplete). Each instruction registers itself to an instrucion_decoder via a bitmask, bitpattern and a callback pointer
| cpu_test.t            | Some tests for the CPU. Not automated. Also shows how instructions are manually encoded. Might be broken at times.

Please note that github misidentifys the .t files as perl files, so the syntax
highlighting on github might not work properly.




## Current status

IDK how often this status will be updated, the source code is the canonical
documentation:



 ### Implemented:

  * instruction decoder
  * decoding of most(all?) immediates for RV32I
  * some of the instruction callbacks

 ### Missing(for base ISA):

  * missing instruction callbacks
  * traps, interrupts, ...
  * more

 ### General TODO:

  * Floating point library binding(SoftFP?)
  * abstract the register typed away in the instructions and cpu
   * will most likely also mean touching every instruction :/
  * find test cases, run tests
   * write a simple assembler
  * check sign-ness for instructions(sign-extension to spec?)
   * in work, should be mostyl implemented, but untested
  * compressed instruction decoder
  * `grep -nr "TODO:" *.t`
  * Debug functions/interface option(Remove print's, only compile if needed)
  * (interactive) debugger?
  * debugger support?
  * build example C programm & run in emulator
