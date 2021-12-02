; AVR {in/lds} - {out/sts} automatic selection macros 
; The device include file must be used to define SRAM_START 

; usage: InReg reg, addr 
.macro InReg 
    .if @1 < 0x40 
        in @0, @1 
    .elif ((@1 >= 0x60) && (@1 < SRAM_START)) 
        lds @0,@1 
    .else 
       .error "InReg: Invalid I/O register address" 
    .endif 
.endmacro 

; usage: OutReg addr, reg 
.macro OutReg 
    .if @0 < 0x40 
        out @0, @1 
    .elif ((@0 >= 0x60) && (@0 < SRAM_START)) 
        sts @0,@1 
    .else 
       .error "OutReg: Invalid I/O register address" 
    .endif 
.endmacro 
