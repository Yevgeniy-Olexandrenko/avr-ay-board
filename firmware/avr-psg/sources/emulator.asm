.include "macrodefs.inc"

; ==============================================================================
; Configuration
; ==============================================================================

; EEPROM Config:
; byte 0 - Serial interface enable (1 - enabled)
; byte 1 - Parallel interface enable (1 - enabled)
; byte 2 - PWM speed depending on AY chip frequency and MCU clock frequency
; byte 3 - USART baud speed depending on MCU clock frequency

; ==============================================================================
; Declarations & definitions
; ==============================================================================

    ; bit numbers:
    .equ b0 = 0x00
    .equ b1 = 0x01
    .equ b2 = 0x02
    .equ b3 = 0x03
    .equ b4 = 0x04
    .equ b5 = 0x05
    .equ b6 = 0x06
    .equ b7 = 0x07

    ; control signals
    .equ PD_BC1  = b2
    .equ PD_BDIR = b3

    ; register variables:
    .def OutA       = r0    ; Channel A output volume
    .def OutC       = r1    ; Channel C output volume
    .def C1F        = r2    ; Constant 0x1F
    .def CntN       = r3    ; Noise counter
    .def OutB       = r4    ; Channel B output volume
    .def BusOut1    = r5
    .def NoiseAddon = r6
    .def C00        = r7    ; Constant 0x00
    .def CC0        = r8    ; Constant 0xC0
    .def BusOut2    = r9
    .def C04        = r10   ; Constant 0x04
    .def TMP        = r11
    .def BusData    = r12   ; IO 8-bit bus data
    .def SREGSave   = r13   ; Save SREG
    .def RNGL       = r14   ; Random Number Generator (low part)
    .def RNGH       = r15   ; Random Number Generator (high part)
    .def TabE       = r16
    .def EVal       = r17   ; Envelope output volume
    .def TabP       = r18   ; Envelope period counter (32 steps)
    .def TNLevel    = r19
    .def CntAL      = r20   ; Tone A counter (low part)
    .def CntAH      = r21   ; Tone A counter (high part)
    .def CntBL      = r22   ; Tone B counter (low part)
    .def CntBH      = r23   ; Tone B counter (high part)
    .def CntCL      = r24   ; Tone C counter (low part)
    .def CntCH      = r25   ; Tone C counter (high part)
    .def CntEL      = r26   ; Envelope counter (low part)
    .def CntEH      = r27   ; Envelope counter (high part)
    .def ADDR       = r30   ; Number of chosen IO register (b0-b3) and flag
                            ; for set up register number/value (b4)

    ; comments on registers:
    ; YH <- 0x02 - high byte of register Y used for fast acces to volume table
    ; ZH <- 0x01 - high byte of register Z used for fast acces to register values

    ; SRAM zones:
    ; --------------------------------------------------------------------------
    ; 0x0100 - 0x010F - register masks
    ; 0x0110 - 0x011F - current registers values
    ; 0x0120 - 0x012F - inverted low bits of register values (D0-D5)
    ; 0x0130 - 0x013F - inverted high bits of register values (D6-D7)
    ; --------------------------------------------------------------------------
    ; 0x0210 - 0x021F - envelope codes
    ; 0x0220 - 0x022F - volume table for tone/noise amplitude
    ; 0x0230 - 0x024F - volume table for envelope amplitude

    ; code section starts here
    .cseg

; ==============================================================================
; Interrupt Vectors Table
; ==============================================================================
    .org    0x0000
    rjmp    RESET

    .org    INT0addr
    rjmp    ISR_INT0

    .org    INT1addr
    rjmp    ISR_INT1

    .org    URXCaddr
    rjmp    ISR_USART_RX

; ==============================================================================
; Constants
; ==============================================================================

; AY_TABLE
#if VOLUME_TABLE == 0
TVolumes:   ; volume table for amplitude
    .db     0x00, 0x03, 0x04, 0x05, 0x08, 0x0C, 0x10, 0x1B
    .db     0x20, 0x34, 0x4B, 0x5F, 0x7E, 0xA2, 0xCD, 0xFF

EVolumes:   ; volume table for envelopes
    .db     0x00, 0x00, 0x03, 0x03, 0x04, 0x04, 0x05, 0x05
    .db     0x08, 0x08, 0x0C, 0x0C, 0x10, 0x10, 0x1B, 0x1B
    .db     0x20, 0x20, 0x34, 0x34, 0x4B, 0x4B, 0x5F, 0x5F
    .db     0x7E, 0x7E, 0xA2, 0xA2, 0xCD, 0xCD, 0xFF, 0xFF

; YM_TABLE
#elif VOLUME_TABLE == 1
TVolumes:   ; volume table for amplitude
    .db     0x00, 0x02, 0x04, 0x05, 0x08, 0x0A, 0x0F, 0x14
    .db     0x1C, 0x26, 0x36, 0x48, 0x66, 0x88, 0xC1, 0xFF

EVolumes:   ; volume table for envelopes
    .db     0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05
    .db     0x06, 0x08, 0x09, 0x0A, 0x0C, 0x0F, 0x11, 0x14
    .db     0x18, 0x1C, 0x21, 0x26, 0x2D, 0x36, 0x3F, 0x48
    .db     0x55, 0x66, 0x77, 0x88, 0xA2, 0xC1, 0xE0, 0xFF
#endif

; envelope codes:
;   bit0 - attack,
;   bit1 - invert on next cycle,
;   bit2 - stop generator on next cycle
Envelopes:
    .db     0x07, 0x07, 0x07, 0x07, 0x04, 0x04, 0x04, 0x04
    .db     0x01, 0x07, 0x03, 0x05, 0x00, 0x06, 0x02, 0x04

; mask applied to registers values after receiving
RegsMask:
    .db     0xFF, 0x0F, 0xFF, 0x0F, 0xFF, 0x0F, 0x1F, 0xFF ; reg00 - reg07
    .db     0x1F, 0x1F, 0x1F, 0xFF, 0xFF, 0x0F, 0xFF, 0xFF ; reg08 - reg15

; ==============================================================================
; Parallel communication mode (BC1 on PD2/INT0, BDIR on PD3/INT1)
; ==============================================================================
ISR_INT0:                           ; [4] enter interrupt
    sbic    PinD, PD_BDIR           ; [2/1] check BDIR bit, skip next if clear
    rjmp    LATCH_REG_ADDR          ; [0/2]

    ; [ READ MODE ] (BC1=1, BDIR=0)
    ; --------------------------------------------------------------------------
    ; 350ns max to set data bus, 8 cycles to set
    ; 8 * 37ns = 296ns for 27MHz O.K.
    ; 8 * 40ns = 320ns for 25MHz O.K.
    ; 8 * 42ns = 336ns for 24MHz O.K.
    ; 8 * 50ns = 400ns for 20MHz !!!!
    OutReg  DDRC, BusOut1           ; [1] output -> low level on D0-D5
    OutReg  DDRD, BusOut2           ; [1] output -> low level on D6-D7

WAIT_FOR_INACTIVE:                  ; loop while BC1=1
    ; 400ns max for release data bus, 9 cycles min
    ; 9 * 50 = 450ns for 20MHz !!!!
    ; 9 * 42 = 378ns for 24MHz O.K.
    ; 9 * 40 = 360ns for 25MHz O.K.
    ; 9 * 37 = 333ns for 27MHz O.K.
    sbic    PinD, PD_BC1            ; [2/1] check BC1 bit, skip next if clear
    rjmp    WAIT_FOR_INACTIVE       ; [0/2]
    OutReg  DDRC, C00               ; [1] input -> Z-state on D0-D5
    OutReg  DDRD, C00               ; [1] input -> Z-state on D6-D7
    reti                            ; [4] leave interrupt

LATCH_REG_ADDR:                    ; TODO: use common latch reg mode code
    ; [ LATCH ADDRESS MODE ] (BC1=1, BDIR=1)
    ; --------------------------------------------------------------------------
    ; 350ns min, 16 cycles
    ; 16 * 50 = 800ns for 20MHz mb O.K., but hz :)))
    ; 16 * 42 = 672ns for 24MHz mb O.K.
    ; 16 * 40 = 640ns for 25MHz mb O.K.
    ; 16 * 37 = 592ns for 27MHz mb O.K.
    InReg   ADDR, PinC              ; [ ] receive register number
    ldd     BusOut1, Z+0x20         ; [2] load value from SRAM
    ldd     BusOut2, Z+0x30         ; [2] load value from SRAM
    reti                            ; [4] leave interrupt

ISR_INT1:                           ; [4] enter interrupt
    sbic    PinD, PD_BC1            ; [2/1] check BC1 bit, skip next if clear
    rjmp    LATCH_REG_ADDR          ; [0/2]

    ; [ WRITE REGISTER MODE ] (BC1=0, BDIR=1)
    ; --------------------------------------------------------------------------
    ; 1950ns min, 33 cycles
    ; 33 * 50 = 1650ns for 20MHz O.K.
    ; 33 * 42 = 1386ns for 24MHz O.K.
    ; 33 * 40 = 1320ns for 25MHz O.K.
    ; 33 * 37 = 1221ns for 27MHz O.K.
    InReg   SREGSave, SREG          ; [1] save SREG

    InReg   BusData, PinC           ; [1]
    InReg   BusOut1, PinD           ; [1]
    and     BusOut1, CC0            ; [1]
    or      BusData, BusOut1        ; [1] construct register value from 2 ports

    ld      BusOut2, Z              ; [2] load register mask from SRAM
    and     BusData, BusOut2        ; [1] apply register mask
    std     Z+0x10, BusData         ; [2] put register value to SRAM

    mov     BusOut1, BusData        ; [1]
    com     BusOut1                 ; [1] invert register value
    std     Z+0x20, BusOut1         ; [2] put inverted register value to SRAM for read mode (6 low bits)

    mov     BusOut2, BusOut1        ; [1]
    and     BusOut2, CC0            ; [1]
    std     Z+0x30, BusOut2         ; [2] put inverted register value to SRAM for read mode (2 high bits)
   
    cpi     ADDR, 0x0D              ; [1] check for register 13
    brne    NO_ENVELOPE_CHANGED_P   ; [1]
    ori     TNLevel, 0x80           ; [1] set flag that register 13 changed

NO_ENVELOPE_CHANGED_P:
    OutReg  SREG, SREGSave          ; [1]
    reti                            ; [4] leave interrupt

; ==============================================================================
; Serial communication mode: URXC Handler
; ==============================================================================
ISR_USART_RX:
    InReg   BusData, UDR0           ; get byte from USART
    sbrs    ADDR, b4                ; check for address/data mode
    rjmp    RECV_REG_VALUE
    sbrc    BusData, b7
    rjmp    USART_SYNC
    mov     ADDR, BusData           ; <= receive register number
    reti

USART_SYNC:                         ; <= synchronization mode
    ldi     ADDR,0x10
    reti

RECV_REG_VALUE:                     ; <= receive register value
    InReg   SREGSave, SREG
    ld      BusOut1, Z              ; load register mask
    and     BusData, BusOut1        ; apply register mask
    std     Z+0x10, BusData         ; put register value to SRAM

    cpi     ADDR, 0x0D              ; check for envelope shape register
    brne    NO_ENVELOPE_CHANGED_S
    ori     TNLevel, 0x80           ; set envelope change flag (bit 7)

NO_ENVELOPE_CHANGED_S:
    ldi     ADDR, 0x10              ; set bit 4 to jump to receive register number on next byte received
    OutReg  SREG, SREGSave
    reti

; ==============================================================================
; Entry point
; ==============================================================================
RESET:
    InReg   r16, MCUCR              ; 1-> PUD for Atmega48/88/168/328
    sbr     r16, PUD
    OutReg  MCUCR, r16

    ; init stack pointer at end of RAM
    ldi     r16, low(RAMEND)
    OutReg  SPL, r16
    ldi     r16, high(RAMEND)
    OutReg  SPH, r16

    ; disable Analog Comparator
    InReg   r16, ACSR               ; for ATMEGA48/88/168/328
    sbr     r16, ACD
    OutReg  ACSR, r16

    ; init constants
    clr     C00
    ldi     r16, 0xC0
    mov     CC0, r16
    ldi     r16, 0x04
    mov     C04, r16
    ldi     r16, 0x1F
    mov     C1F, r16
    ldi     r16, 0xFF
    mov     BusOut1, r16
    mov     BusOut2, CC0
    clr     RNGH

    ; clear register values in SRAM 0x110-0x13F
    ldi     r18, 0x10
    ldi     ZL, 0x10
    ldi     ZH, 0x01

L0:
    std     Z+0x20, CC0
    std     Z+0x10, r16
    st      Z+, C00
    dec     r18
    brne    L0

    ; load envelope codes to SRAM 0x210, 16 bytes
    ldi     xh, 0x02
    ldi     xl, 0x10
    ldi     zl, low(2*Envelopes)
    ldi     zh, high(2*Envelopes)
    ldi     r18, 0x10
    rcall   COPY

    ; load volume table for amplitude to SRAM 0x220, 16 bytes
    ldi     xl, 0x20
    ldi     zl, low(2*TVolumes)
    ldi     zh, high(2*TVolumes)
    ldi     r18, 0x10
    rcall   COPY

    ; load volume table for envelopes to SRAM 0x230, 32 bytes
    ldi     xl, 0x30
    ldi     zl, low(2*EVolumes)
    ldi     zh, high(2*EVolumes)
    ldi     r18, 0x20
    rcall   COPY

    ; load register masks to SRAM 0x100, 16 bytes
    clr     xl
    ldi     xh, 0x01
    ldi     zl, low(2*RegsMask)
    ldi     zh, high(2*RegsMask)
    ldi     r18, 0x10
    rcall   COPY

    ldi     ZH, 0x01                ; set high byte of register Z for fast acces to register values
    ldi     YH, 0x02                ; set high byte of register Y for fast acces to volume table
    mov     NoiseAddon, ZH          ; load default value = 1 to high bit of noise generator

    ; get byte 0 from EEPROM, check value > 0 or skip USART initialization if value = 0
    OutReg  EEARH, C00              ; is absent in Atmega48
    OutReg  EEARL, C00
    sbi     EECR, b0
    InReg   r16, EEDR
    cp      r16, C00
    breq    NO_USART

    ; --------------------------------------------------------------------------
    ; Init USART
    ; --------------------------------------------------------------------------
    clr     r16
    OutReg  UBRR0H, r16
    ldi     r16, 0x06
    OutReg  UCSR0C, r16
    ldi     r16, 0x02
    OutReg  UCSR0A, r16
    ldi     r16, 0x90
    OutReg  UCSR0B, r16

    ldi     r16, 0x03
    OutReg  EEARL, r16
    sbi     EECR, b0
    InReg   r18, EEDR
    OutReg  UBRR0L, r18
NO_USART:

    ; --------------------------------------------------------------------------
    ; Init Timer0
    ; --------------------------------------------------------------------------

    ; Fast PWM, TOP = OCR0A
    ldi     r16, (1 << WGM01) | (1 << WGM00)
    OutReg  TCCR0A, r16
    ldi     r16, (1 << WGM02) | (1 << CS00);
    OutReg  TCCR0B, r16

    ; 219512 Hz internal update clock
    ;ldi     r16, (27000000 / (1750000 / 8) - 1)
    ;out     OCR0A, r16
    OutReg  EEARL, YH               ; set EEPROM address 2
    sbi     EECR, b0
    InReg   r18, EEDR               ; load byte 2 from EEPROM to r18
    OutReg  OCR0A, r18              ; set PWM speed from byte 2 of EEPROM (affect AY chip frequency)

    ; --------------------------------------------------------------------------
    ; Init Timer1
    ; --------------------------------------------------------------------------
    ;sts     OCR1AH, C00             ; clear OCR values
    ;sts     OCR1AL, C00
    ;sts     OCR1BH, C00
    ;sts     OCR1BL, C00
    sbi     DDRB, DDB1              ; set port B pin 1 to output for PWM (AY channel A)
    sbi     DDRB, DDB2              ; set port B pin 2 to output for PWM (AY channel C)

    ; Waveform generation mode: 5 (Fast PWM 8-bit, TOP = 0xFF)
    ; Clear OC1A/OC1B on Compare Match, set OC1A/OC1B at BOTTOM (non-inverting mode)
    ; No prescaling
    ldi     r16, (1 << WGM10) | (1 << COM1A1) | (1 << COM1B1)
    OutReg  TCCR1A, r16
    ldi     r16, (1 << WGM12) | (1 << CS10)
    OutReg  TCCR1B, r16

    ; --------------------------------------------------------------------------
    ; Init Timer2
    ; --------------------------------------------------------------------------
    sbi     DDRB, DDB3              ; set port B pin 3 to output for PWM (AY channel C)

    ; Waveform Generation Mode: 3 (Fast PWM, TOP = 0xFF)
    ; Clear OC2 on Compare Match, set OC2 at BOTTOM (non-inverting mode)
    ; No prescaling
    ldi     r16, 0x83               ; COM2A1+WGM21+WGM20
    OutReg  TCCR2A, r16
    ldi     r16, 0x01               ; CS20
    OutReg  TCCR2B, r16

    ; check for parallel interface enabled in byte 1 of EEPROM
    OutReg  EEARL, ZH
    sbi     EECR, b0
    InReg   r16, EEDR
    cp      r16, C00
    breq    NO_EXT_INT

    ; --------------------------------------------------------------------------
    ; Init external interrupts INT0 and INT1
    ; --------------------------------------------------------------------------
    ldi     r16, 0x0F               ; fallen edge of INT0, INT1
    OutReg  EICRA, r16
    ldi     r16, 0x03
    OutReg  EIFR, r16
    OutReg  EIMSK, r16
NO_EXT_INT:

    ; init constants and variables second part
    ldi     ADDR, 0x10
    clr     TNLevel
    clr     OutA
    clr     OutB
    clr     OutC
    mov     TabP, CC0               ; set envelope generator disablet by default
    clr     TabE
    clr     BusData
    clr     CntN
    clr     CntAL
    clr     CntAH
    movw    CntBL, CntAL
    movw    CntCL, CntAL
    movw    CntEL, CntAL
    clr     EVal
    sei                             ; enable global interrupts

; ==============================================================================
; Main Loop
; ==============================================================================
MAIN_LOOP:
    InReg   YL, TIFR0               ; check timer0 overflow flag TOV0
    sbrs    YL, TOV0
    rjmp    MAIN_LOOP               ; jump if not set
    OutReg  TIFR0, YL               ; clear timer overflow flag

    ; --------------------------------------------------------------------------
    ; ENVELOPE GENERATOR
    ; --------------------------------------------------------------------------
    sbrs    TNLevel, b7
    rjmp    NO_ENVELOPE_CHANGED

    ; initialize envelope generator after change envelope shape register,
    ; only first 1/32 part of the first period!
    lds     YL, AY_REG13            ; load envelope shape register value to TabE
    ldd     TabE, Y+0x10            ; get envelope code from SRAM
    ldi     TabP, 0x1F              ; set counter for envelope period
    andi    TNLevel, 0x7F           ; clear envelope shape change flag
    rjmp    E_NEXT_STEP

NO_ENVELOPE_CHANGED:
    sbrc    TabE, b7                ; check if envelope generator is disabled
    rjmp    ENVELOPE_GENERATOR_END
    sbiw    CntEL, 0x01
    brcs    E_NEXT_PERIOD           ; jump to init next envelope value if counter overflow (if initial value was 0)
    brne    ENVELOPE_GENERATOR_END  ; go to the next step if zero value is not reached

E_NEXT_PERIOD:
    dec     TabP
    brpl    E_NEXT_STEP             ; jump to next step if envelope period >= 0

    ; init new envelope period
    ldi     TabP, 0x1F
    sbrc    TabE, b1
    eor     TabE, ZH                ; invert envelope ATTACK bit
    sbrc    TabE, b2
    or      TabE, CC0               ; disable envelope generator until new envelope shape register recived

E_NEXT_STEP:
    lds     CntEL, AY_REG11
    lds     CntEH, AY_REG12
    mov     YL, TabP
    sbrs    TabE, b0
    eor     YL, C1F                 ; invert envelope value if ATTACK bit is not set
    ldd     EVal, Y+0x30            ; translate envelope value to volume, read volume value from SRAM 0x230+YL
ENVELOPE_GENERATOR_END:

    ; --------------------------------------------------------------------------
    ; NOISE GENERATOR
    ; --------------------------------------------------------------------------
    dec     CntN                    ; decrease noise period counter
    brpl    NOISE_GENERATOR_END     ; skip if noise period is not finished (CntN>=0)
    lds     CntN, AY_REG06          ; init noise period counter with value in AY register 6
    dec     CntN

    lsr     NoiseAddon
    mov     NoiseAddon, RNGL
    ror     RNGH
    ror     RNGL

    ori     TNLevel, 0x38           ; set noise bits
    sbrs    RNGL, b0
    andi    TNLevel, 0xC7           ; reset noise bits

    ; make input bit
    lsl     NoiseAddon
    eor     NoiseAddon, RNGL
    lsr     NoiseAddon
NOISE_GENERATOR_END:

    ; --------------------------------------------------------------------------
    ; TONE GENERATOR
    ; --------------------------------------------------------------------------
    ; all counters are Int16 values (signed)

    ; Channel A
    subi    CntAL, 0x01             ; CntA - 1
    sbci    CntAH, 0x00
    brpl    CH_A_NO_CHANGE          ; CntA >= 0
    lds     CntAL, AY_REG00         ; update channel A tone period counter
    lds     CntAH, AY_REG01
    subi    CntAL, 0x01             ; CntA - 1
    sbci    CntAH, 0x00
    eor     TNLevel, ZH             ; TNLevel xor 1 (change logical level of channel A)
CH_A_NO_CHANGE:

    ; Channel B
    subi    CntBL, 0x01             ; CntB - 1
    sbci    CntBH, 0x00
    brpl    CH_B_NO_CHANGE          ; CntB >= 0
    lds     CntBL, AY_REG02         ; update channel B tone period counter
    lds     CntBH, AY_REG03
    subi    CntBL, 0x01             ; CntB - 1
    sbci    CntBH, 0x00
    eor     TNLevel, YH	            ; TNLevel xor 2 (change logical level of channel B)
CH_B_NO_CHANGE:

    ; Channel C
    sbiw    CntCL, 0x01             ; CntC - 1
    brpl    CH_C_NO_CHANGE          ; CntC >= 0
    lds     CntCL, AY_REG04         ; update channel C tone period counter
    lds     CntCH, AY_REG05
    sbiw    CntCL, 0x01             ; CntC - 1
    eor     TNLevel, C04            ; TNLevel xor 4 (change logical level of channel C)
CH_C_NO_CHANGE:

    ; --------------------------------------------------------------------------
    ; MIXER
    ; --------------------------------------------------------------------------
    lds     TMP, AY_REG07           ; Load Mixer AY Register from SRAM
    or      TMP, TNLevel            ; Mixer formula = (Mixer Register Tone | TNLevel Tone) & (Mixer Register Noise | TNLevel Noise)
    mov     YL, TMP
    lsl     YL
    swap    YL
    and     TMP, YL

    ; --------------------------------------------------------------------------
    ; AMPLITUDE CONTROL
    ; --------------------------------------------------------------------------

    ; Channel A
    lds     YL, AY_REG08            ; Load Channel A Amplitude register
    mov     OutA, EVal              ; set envelope volume as default value
    sbrs    YL, b4                  ; if bit 4 is not set in amplitude register then translate it to volume
    ldd     OutA, Y+0x20            ; load volume value from SRAM 0x220 + YL
    sbrs    TMP, b0                 ; if channel is disabled in mixer - set volume to zero
    clr     OutA
    
    ; Channel B
    lds     YL, AY_REG09            ; Load Channel B Amplitude register
    mov     OutB, EVal              ; set envelope volume as default value
    sbrs    YL, b4                  ; if bit 4 is not set in amplitude register then translate it to volume
    ldd     OutB, Y+0x20            ; load volume value from SRAM 0x220 + YL
    sbrs    TMP, b1                 ; if channel is disabled in mixer - set volume to zero
    clr     OutB

    ; Channel C
    lds     YL, AY_REG10            ; Load Channel C Amplitude register
    mov     OutC, EVal              ; set envelope volume as default value
    sbrs    YL, b4                  ; if bit 4 is not set in amplitude register then translate it to volume
    ldd     OutC, Y+0x20            ; load volume value from SRAM 0x220 + YL
    sbrs    TMP, b2                 ; if channel is disabled in mixer - set volume to zero
    clr     OutC

    ; update PWM counters
    OutReg  OCR1AL, OutA
    OutReg  OCR2A,  OutB
    OutReg  OCR1BL, OutC
    rjmp    MAIN_LOOP

; ==============================================================================
; Subroutines
; ==============================================================================
COPY:                       ; copy from flash to SRAM
    lpm     r16, Z+
    st      X+, r16
    dec     r18
    brne    COPY
    ret

    ; data segment starts here
    .dseg

; ==============================================================================
; PSG Registers in SRAM
; ==============================================================================
    .org    0x0110
AY_REG00:
    .byte   1
AY_REG01:
    .byte   1
AY_REG02:
    .byte   1
AY_REG03:
    .byte   1
AY_REG04:
    .byte   1
AY_REG05:
    .byte   1
AY_REG06:
    .byte   1
AY_REG07:
    .byte   1
AY_REG08:
    .byte   1
AY_REG09:
    .byte   1
AY_REG10:
    .byte   1
AY_REG11:
    .byte   1
AY_REG12:
    .byte   1
AY_REG13:
    .byte   1
AY_REG14:
    .byte   1
AY_REG15:
    .byte   1
