; AY-3-8912 IC emulator version 26.0 for ATMega8/48/88/168/328 16.04.2020
;
; Sources for Atmel AVRStudio 5
;
; visit our site for more information
; These source codes are distributed under the GPL v3 license
; If you share these sources you should put the link to web site www.avray.ru
;
; ORIGIN: http://www.avray.ru

; ==============================================================================
; Configuration
; ==============================================================================
#define CHANNELS     2 ; choose 2 or 3 channel version
#define SPEAKER      0 ; use SPEAKER port input on PD1 (0 - no, 1 - yes)
#define VOLUME_TABLE 0 ; 0 - AY, 1 - YM, 2 - ALTERNATE volume table
#define MCU_TYPE     2 ; 0 - Atmega8, 1 - Atmega48, 2 - Atmega88/168/328

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

    ; register variables:
    .def OutA       = r0
    .def OutC       = r1
    .def C1F        = r2
    .def CntN       = r3
    .def OutB       = r4
    .def BusOut1    = r5
    .def NoiseAddon = r6
    .def C00        = r7
    .def CC0        = r8
    .def BusOut2    = r9
    .def C04        = r10
    .def TMP        = r11
    .def BusData    = r12
    .def SREGSave   = r13
    .def RNGL       = r14
    .def RNGH       = r15
    .def TabE       = r16
    .def EVal       = r17
    .def TabP       = r18
    .def TNLevel    = r19
    .def CntAL      = r20
    .def CntAH      = r21
    .def CntBL      = r22
    .def CntBH      = r23
    .def CntCL      = r24
    .def CntCH      = r25
    .def CntEL      = r26
    .def CntEH      = r27
    .def ADDR       = r30

    ; code section starts here
    .cseg

; ==============================================================================
; Interrupt Vectors Table
; ==============================================================================
    .org    0x0000
    rjmp    _RESET

    .org    INT0addr
    rjmp    _INT0_Handler

    .org    INT1addr
    rjmp    _INT1_Handler

    .org    URXCaddr
    rjmp    _USART_RX_COMPLETE

; ==============================================================================
; Constants
; ==============================================================================

; AY_TABLE
#if VOLUME_TABLE == 0
Volumes:    ; volume table for amplitude
    .db     0, 1, 1, 1, 2, 2, 3, 5, 6, 9, 13, 17, 22, 29, 36, 45
EVolumes:   ; volume table for envelopes
    .db     0, 0, 1, 1,  1,  1,  1,  1,  2,  2,  2,  2,  3,  3,  5,  5
    .db     6, 6, 7, 9, 11, 13, 15, 17, 19, 22, 25, 29, 32, 36, 40, 45

; YM_TABLE
#elif VOLUME_TABLE == 1
Volumes:    ; volume table for amplitude
    .db     0, 1, 1, 1, 2, 2, 3, 4, 5, 7, 10, 13, 18, 24, 34, 45
EVolumes:   ; volume table for envelopes
    .db     0, 0, 1, 1, 1,  1,  1,  1,  2,  2,  2,  2,  2,  3,  3,  4
    .db     4, 5, 6, 7, 8, 10, 11, 13, 15, 18, 21, 24, 29, 34, 40, 45

; ALT_TABLE
#elif VOLUME_TABLE == 2
Volumes:    ; volume table for amplitude
    .db     0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 13, 16, 22, 31, 42, 58
EVolumes:   ; volume table for envelopes
    .db     0,   1,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14
    .db     15, 16, 17, 18, 20, 22, 24, 26, 28, 30, 33, 36, 40, 45, 51, 58
#endif

; envelope codes:
;   bit0 - attack,
;   bit1 - invert on next cycle,
;   bit2 - stop generator on next cycle
Envelopes:
    .db     7, 7, 7, 7, 4, 4, 4, 4, 1, 7, 3, 5, 0, 6, 2, 4

; mask applied to registers values after receiving
RegsMask:
    .db     0xFF, 0x0F, 0xFF, 0x0F, 0xFF, 0x0F, 0x1F, 0xFF ; reg00 - reg07
    .db     0x1F, 0x1F, 0x1F, 0xFF, 0xFF, 0x0F, 0xFF, 0xFF ; reg08 - reg15

; ==============================================================================
; Parallel communication mode (BC1 on PD2/INT0, BDIR on PD3/INT1)
; ==============================================================================
_INT0_Handler:                      ; [4] enter interrupt
    sbic    PinD, b3                ; [2/1] check BDIR bit, skip next if clear
    rjmp    LATCH_REG_ADDR0         ; [0/2]

    ; [ READ MODE ] (BC1=1, BDIR=0)
    ; --------------------------------------------------------------------------
    ; 350ns max to set data bus, 8 cycles to set
    ; 8 * 37ns = 296ns for 27MHz O.K.
    ; 8 * 40ns = 320ns for 25MHz O.K.
    ; 8 * 42ns = 336ns for 24MHz O.K.
    ; 8 * 50ns = 400ns for 20MHz !!!!
    out     DDRD, BusOut2           ; [1] turn pins to output
    out     DDRC, BusOut1           ; [1]

LOOP_NOT_INACTIVE:                  ; loop while BC1=1
    ; 400ns max for release data bus, 9 cycles min
    ; 9 * 50 = 450ns for 20MHz !!!!
    ; 9 * 42 = 378ns for 24MHz O.K.
    ; 9 * 40 = 360ns for 25MHz O.K.
    ; 9 * 37 = 333ns for 27MHz O.K.
    sbic    PinD, b2                ; [2/1] check BC1 bit, skip next if clear
    rjmp    LOOP_NOT_INACTIVE       ; [0/2]
    out     DDRC, C00               ; [1] turn pins to input
    out     DDRD, C00               ; [1]
    reti                            ; [4] leave interrupt

LATCH_REG_ADDR0:                    ; TODO: use common latch reg mode code
    ; [ LATCH ADDRESS MODE ] (BC1=1, BDIR=1)
    ; --------------------------------------------------------------------------
    in      ADDR, PinC              ; [ ] receive register number
    ldd     BusOut1, Z+0x20         ; [ ] load value from SRAM
    ldd     BusOut2, Z+0x30         ; [ ] load value from SRAM
#if MCU_TYPE == 0
    out     GIFR, CC0               ; [ ] reset ext. interrupt flags
#else
    out     EIFR, YH                ; [ ] reset ext. interrupt flags
#endif
    reti                            ; [4] leave interrupt

_INT1_Handler:                      ; [4] enter interrupt
    in      BusData, PinC           ; [ ] TODO: move to write reg mode
    sbic    PinD, b2                ; [2/1] check BC1 bit, skip next if clear
    rjmp    LATCH_REG_ADDR1         ; [0/2]

    ; [ WRITE REGISTER MODE ] (BC1=0, BDIR=1)
    ; --------------------------------------------------------------------------
    ; 1950ns min, 33 cycles
    ; 33 * 50 = 1650ns for 20MHz O.K.
    ; 33 * 42 = 1386ns for 24MHz O.K.
    ; 33 * 40 = 1320ns for 25MHz O.K.
    ; 33 * 37 = 1221ns for 27MHz O.K.
    in      BusOut1, PinD           ; [1]
    in      SREGSave, SREG          ; [1] save SREG
    and     BusOut1, CC0            ; [1]
    or      BusData, BusOut1        ; [1] construct register value from 2 ports
    mov     BusOut1, BusData        ; [1]
    com     BusOut1                 ; [1] invert register value
    std     Z+0x20, BusOut1         ; [2] put inverted register value to SRAM for read mode

    ld      BusOut2, Z              ; [2] load register mask from SRAM
    and     BusData, BusOut2        ; [1] apply register mask

    mov     BusOut2, BusOut1        ; [1]
    and     BusOut2, CC0            ; [1]
    std     Z+0x30, BusOut2         ; [2] put inverted register value to SRAM for read mode (2 high bits)
    std     Z+0x10, BusData         ; [2] put register value to SRAM
    cpi     ADDR, 0x0D              ; [1] check for register 13
    brne    NO_ENVELOPE_CHANGED_P   ; [1]
    ori     TNLevel, 0x80           ; [1] set flag that register 13 changed

NO_ENVELOPE_CHANGED_P:
    out     SREG, SREGSave          ; [1]
    reti                            ; [4] leave interrupt

LATCH_REG_ADDR1:                    ; TODO: use common latch reg mode code
    ; [ LATCH ADDRESS MODE ] (BC1=1, BDIR=1)
    ; --------------------------------------------------------------------------
    ; 350ns min, 16 cycles
    ; 16 * 50 = 800ns for 20MHz mb O.K., but hz :)))
    ; 16 * 42 = 672ns for 24MHz mb O.K.
    ; 16 * 40 = 640ns for 25MHz mb O.K.
    ; 16 * 37 = 592ns for 27MHz mb O.K.
    mov     ADDR, BusData           ; [ ] receive register number
    ldd     BusOut1, Z+0x20         ; [2] load value from SRAM
    ldd     BusOut2, Z+0x30         ; [2] load value from SRAM
#if MCU_TYPE == 0
    out     GIFR, CC0               ; [ ] reset ext. interrupt flags
#else
    out     EIFR, ZH                ; [ ] reset ext. interrupt flags
#endif
    reti                            ; [4] leave interrupt

; ==============================================================================
; Serial communication mode: URXC Handler
; ==============================================================================
_USART_RX_COMPLETE:
#if MCU_TYPE == 0
    in      BusData, UDR            ; get byte from USART
#else
    lds     BusData, UDR0           ; get byte from USART
#endif
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
    in      SREGSave, SREG
    ld      BusOut1, Z              ; load register mask
    and     BusData, BusOut1        ; apply register mask
    std     Z+0x10, BusData         ; put register value to SRAM
    cpi     ADDR, 0x0D              ; check for envelope shape register
    brne    NO_ENVELOPE_CHANGED_S
    ori     TNLevel, 0x80           ; set envelope change flag (bit 7)

NO_ENVELOPE_CHANGED_S:
    ldi     ADDR, 0x10              ; set bit 4 to jump to receive register number on next byte received
    out     SREG, SREGSave
    reti

; ==============================================================================
; Entry point
; ==============================================================================
_RESET:
#if MCU_TYPE == 0
    in      r16, SFIOR              ; 1-> PUD for Atmega8
    sbr     r16, PUD
    out     SFIOR, r16
#else
    in      r16, MCUCR              ; 1-> PUD for Atmega48/88/168/328
    sbr     r16, PUD
    out     MCUCR, r16
#endif

    ; init stack pointer at end of RAM
    ldi     r16, low(RAMEND)
    out     SPL, r16
    ldi     r16, high(RAMEND)
    out     SPH, r16

    ; disable Analog Comparator
#if MCU_TYPE == 0
    sbi     ACSR, ACD               ; for atmega8
#else
    in      r16, ACSR               ; for ATMEGA48/88/168/328
    sbr     r16, ACD
    out     ACSR, r16
#endif

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

LOOP0:
    std     Z+0x20, CC0
    std     Z+0x10, r16
    st      Z+, C00
    dec     r18
    brne    LOOP0

    ; load envelope codes to SRAM 0x210, 16 bytes
    ldi     xh, 0x02
    ldi     xl, 0x10
    ldi     zl, low(2*Envelopes)
    ldi     zh, high(2*Envelopes)
    ldi     r18, 0x10
    rcall   _COPY

    ; load volume table for amplitude to SRAM 0x220, 16 bytes
    ldi     xl, 0x20
    ldi     zl, low(2*Volumes)
    ldi     zh, high(2*Volumes)
    ldi     r18, 0x10
    rcall   _COPY

    ; load volume table for envelopes to SRAM 0x230, 32 bytes
    ldi     xl, 0x30
    ldi     zl, low(2*EVolumes)
    ldi     zh, high(2*EVolumes)
    ldi     r18, 0x20
    rcall   _COPY

    ; load register masks to SRAM 0x100, 16 bytes
    clr     xl
    ldi     xh, 0x01
    ldi     zl, low(2*RegsMask)
    ldi     zh, high(2*RegsMask)
    ldi     r18, 0x10
    rcall   _COPY


    ldi     ZH, 0x01                ; set high byte of register Z for fast acces to register values
    ldi     YH, 0x02                ; set high byte of register Y for fast acces to volume table
    mov     NoiseAddon, ZH          ; load default value = 1 to high bit of noise generator

    ; get byte 0 from EEPROM, check value > 0 or skip USART initialization if value = 0
#if MCU_TYPE == 0 ||  MCU_TYPE > 1
    out     EEARH, C00              ; is absent in Atmega48
#endif
    out     EEARL, C00
    sbi     EECR, b0
    in      r16, EEDR
    cp      r16, C00
    breq    NO_USART

    ; --------------------------------------------------------------------------
    ; Init USART
    ; --------------------------------------------------------------------------
    clr     r16
#if MCU_TYPE == 0
    out     UBRRH, r16
    ldi     r16, 0x86
    out     UCSRC, r16
    ldi     r16, 0x02
    out     UCSRA, r16
    ldi     r16, 0x90
    out     UCSRB, r16
#else
    sts     UBRR0H, r16
    ldi     r16, 0x06
    sts     UCSR0C, r16
    ldi     r16, 0x02
    sts     UCSR0A, r16
    ldi     r16, 0x90
    sts     UCSR0B, r16
#endif
    ldi     r16, 0x03
    out     EEARL, r16
    sbi     EECR, b0
    in      r18, EEDR
#if MCU_TYPE == 0
    out     UBRRL, r18
#else
    sts     UBRR0L, r18
#endif
NO_USART:

    ; --------------------------------------------------------------------------
    ; Init Timer1
    ; --------------------------------------------------------------------------
#if MCU_TYPE == 0
    out     OCR1AH, C00             ; clear OCR values
    out     OCR1AL, C00
    out     OCR1BH, C00
    out     OCR1BL, C00
#else
    sts     OCR1AH, C00             ; clear OCR values
    sts     OCR1AL, C00
    sts     OCR1BH, C00
    sts     OCR1BL, C00
#endif
    sbi     DDRB, b1                ; set port B pin 1 to output for PWM (AY channel A)
    sbi     DDRB, b2                ; set port B pin 2 to output for PWM (AY channel C)

    ; Waveform generation mode: 14 (Fast PWM, TOP controlled by ICR1)
    ; Clear OC1A/OC1B on Compare Match, set OC1A/OC1B at BOTTOM (non-inverting mode)
    ; No prescaling
    ldi     r16, 0xA2               ; COM1A1+COM1B1+WGM11
#if MCU_TYPE == 0
    out     TCCR1A, r16
#else
    sts     TCCR1A, r16
    ldi     r16, 0x19               ; TODO: useless because of the same code further
    sts     TCCR1B, r16             ; TODO: useless because of the same code further
#endif
    ldi     r16, 0x19               ; WGM13+WGM12+CS10
#if MCU_TYPE == 0
    out     TCCR1B, r16
#else
    sts     TCCR1B, r16
#endif

    ; Defines the counter's TOP value
    ; ICR1H = 0
    ; ICR1L = config
    out     EEARL, YH               ; set EEPROM address 2
    sbi     EECR, b0
    in      r18, EEDR               ; load byte 2 from EEPROM to r18
#if MCU_TYPE == 0
    out     ICR1H, C00
    out     ICR1L, r18              ; set PWM speed from byte 2 of EEPROM (affect AY chip frequency)
#else
    sts     ICR1H, C00
    sts     ICR1L, r18              ; set PWM speed from byte 2 of EEPROM (affect AY chip frequency)
#endif
    ; ICR1L value formula (28000000/109375/2 - 1) where 28000000 = 28MHz - AVR oscillator frequency
    ; 109375 is for 1.75 MHz version, formula is (PSG frequency / 16) e.g. for 2MHz it is 2000000/16 = 125000

    ; --------------------------------------------------------------------------
    ; Init Timer2
    ; --------------------------------------------------------------------------
#if CHANNELS == 3
    sbi     DDRB, DDB3              ; set port B pin 3 to output for PWM (AY channel C)

    ; Waveform Generation Mode: 3 (Fast PWM, TOP = 0xFF)
    ; Clear OC2 on Compare Match, set OC2 at BOTTOM (non-inverting mode)
    ; No prescaling
#if MCU_TYPE == 0
    ldi     r16, 0x69               ; WGM20+COM21+WGM21+CS20
    out     TCCR2, r16
#else
    ldi     r16, 0x83               ; COM2A1+WGM21+WGM20
    sts     TCCR2A, r16
    ldi     r16, 0x01               ; CS20
    sts     TCCR2B, r16
#endif
#endif

    ; check for parallel interface enabled in byte 1 of EEPROM
    out     EEARL, ZH
    sbi     EECR, b0
    in      r16, EEDR
    cp      r16, C00
    breq    NO_EXT_INT

    ; --------------------------------------------------------------------------
    ; Init external interrupts INT0 and INT1
    ; --------------------------------------------------------------------------
#if MCU_TYPE == 0
    ldi     r16, 0x0F               ; fallen edge of INT0, INT1
    out     MCUCR, r16
    out     GIFR, CC0               ; clear interrupt flags
    out     GICR, CC0               ; enable interrupts
#else
    ldi     r16, 0x0F               ; fallen edge of INT0, INT1
    sts     EICRA, r16
    ldi     r16, 0x03
    out     EIFR, r16
    out     EIMSK, r16
#endif
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
_MAIN_LOOP:
#if MCU_TYPE == 0
	in		YL,TIFR			; check timer1 overflow flag TOV1
	sbrs	YL,TOV1
	rjmp	_MAIN_LOOP		; jump if not set
	out	TIFR,YL				; clear timer overflow flag
#else
	in		YL,TIFR1		; check timer1 overflow flag TOV1
	sbrs	YL,TOV1
	rjmp	_MAIN_LOOP		; jump if not set
	out		TIFR1,YL		; clear timer overflow flag
#endif

	// sound generation code start (using timer1 overflow flag)
	// MIN cycles: 69
	// MAX cycles: 110

	/////////////////////////////////////////////////////////////////////////////////////
	/// ENVELOPE GENERATOR
	/////////////////////////////////////////////////////////////////////////////////////
	sbrs	TNLevel,b7
	rjmp	NO_ENVELOPE_CHANGED

	// initialize envelope generator after change envelope shape register, only first 1/32 part of the first period!
	lds		YL,AY_REG13		; load envelope shape register value to TabE
	ldd		TabE,Y+0x10		; get envelope code from SRAM
	ldi		TabP,0x1F		; set counter for envelope period
	andi	TNLevel,0x7F	; clear envelope shape change flag
	rjmp	E_NEXT_STEP

NO_ENVELOPE_CHANGED:
	sbrc	TabE,b7			; alternate: cpi	TabE,0x80	; check if envelope generator is disabled
	rjmp	ENVELOPE_GENERATOR_END	; alternate: brcc	ENVELOPE_GENERATOR_END
	sbiw	CntEL,0x01
	brcs	E_NEXT_PERIOD	; jump to init next envelope value if counter overflow (if initial value was 0)
	brne	ENVELOPE_GENERATOR_END	; go to the next step if zero value is not reached
E_NEXT_PERIOD:
	dec		TabP
	brpl	E_NEXT_STEP		; jump to next step if envelope period >= 0
	;init new envelope period
	ldi		TabP,0x1F
	sbrc	TabE,b1
	eor		TabE,ZH			; invert envelope ATTACK bit
	sbrc	TabE,b2
	or		TabE,CC0		; disable envelope generator until new envelope shape register recived
E_NEXT_STEP:
	lds		CntEL,AY_REG11
	lds		CntEH,AY_REG12
	mov		YL,TabP
	sbrs	TabE,b0
	eor		YL,C1F			; invert envelope value if ATTACK bit is not set
	ldd		EVal,Y+0x30		; translate envelope value to volume, read volume value from SRAM 0x230+YL
ENVELOPE_GENERATOR_END:
	/////////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////////
	/// NOISE GENERATOR
	/////////////////////////////////////////////////////////////////////////////////////
	dec		CntN			; decrease noise period counter
	brpl	NOISE_GENERATOR_END ; skip if noise period is not finished (CntN>=0)
	//init new cycle
	lds		CntN,AY_REG06	; init noise period counter with value in AY register 6
	dec		CntN

	lsr		NoiseAddon
	mov		NoiseAddon,RNGL
	ror		RNGH
	ror		RNGL

	ori		TNLevel,0x38	; set noise bits
	sbrs	RNGL,b0
	andi	TNLevel,0xC7	; reset noise bits
	// make input bit
	lsl		NoiseAddon
	eor		NoiseAddon,RNGL
	lsr		NoiseAddon
NOISE_GENERATOR_END:
	/////////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////////
	/// TONE GENERATOR
	/////////////////////////////////////////////////////////////////////////////////////
	; all counters are Int16 values (signed)
	// Channel A -------------
	subi	CntAL,0x01		; CntA - 1
	sbci	CntAH,0x00
	brpl	CH_A_NO_CHANGE	; CntA >= 0
	lds		CntAL,AY_REG00	; update channel A tone period counter
	lds		CntAH,AY_REG01
	subi	CntAL,0x01		; CntA - 1
	sbci	CntAH,0x00
	eor		TNLevel,ZH		; TNLevel xor 1 (change logical level of channel A)
CH_A_NO_CHANGE:

	// Channel B -------------
	subi	CntBL,0x01		; CntB - 1
	sbci	CntBH,0x00
	brpl	CH_B_NO_CHANGE	; CntB >= 0
	lds		CntBL,AY_REG02	; update channel B tone period counter
	lds		CntBH,AY_REG03
	subi	CntBL,0x01		; CntB - 1
	sbci	CntBH,0x00
	eor		TNLevel,YH		; TNLevel xor 2 (change logical level of channel B)
CH_B_NO_CHANGE:

	// Channel C -------------
	sbiw	CntCL,0x01		; CntC - 1
	brpl	CH_C_NO_CHANGE	; CntC >= 0
	lds		CntCL,AY_REG04	; update channel C tone period counter
	lds		CntCH,AY_REG05
	sbiw	CntCL,0x01		; CntC - 1
	eor		TNLevel,C04		; TNLevel xor 4 (change logical level of channel C)
CH_C_NO_CHANGE:
	/////////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////////
	/// MIXER
	/////////////////////////////////////////////////////////////////////////////////////
	lds		TMP,AY_REG07	; Load Mixer AY Register from SRAM
	or		TMP,TNLevel		; Mixer formula = (Mixer Register Tone | TNLevel Tone) & (Mixer Register Noise | TNLevel Noise)
	mov		YL,TMP
	lsl		YL
	swap	YL
	and		TMP,YL
	/////////////////////////////////////////////////////////////////////////////////////


	/////////////////////////////////////////////////////////////////////////////////////
	/// AMPLITUDE CONTROL
	/////////////////////////////////////////////////////////////////////////////////////

	// Channel A
	lds		YL,AY_REG08		; Load Channel A Amplitude register
	mov		OutA,EVal		; set envelope volume as default value
	sbrs	YL,b4			; if bit 4 is not set in amplitude register then translate it to volume
	ldd		OutA,Y+0x20		; load volume value from SRAM 0x220 + YL
	sbrs	TMP,b0			; if channel is disabled in mixer - set volume to zero
	clr		OutA
	
	// Channel B
	lds		YL,AY_REG09		; Load Channel B Amplitude register
	mov		OutB,EVal		; set envelope volume as default value
	sbrs	YL,b4			; if bit 4 is not set in amplitude register then translate it to volume
	ldd		OutB,Y+0x20		; load volume value from SRAM 0x220 + YL
	sbrs	TMP,b1			; if channel is disabled in mixer - set volume to zero
	clr		OutB

	// Channel C
	lds		YL,AY_REG10		; Load Channel C Amplitude register
	mov		OutC,EVal		; set envelope volume as default value
	sbrs	YL,b4			; if bit 4 is not set in amplitude register then translate it to volume
	ldd		OutC,Y+0x20		; load volume value from SRAM 0x220 + YL
	sbrs	TMP,b2			; if channel is disabled in mixer - set volume to zero
	clr		OutC

	// Channel B
#if CHANNELS == 2
// two channel version ----------------------------------------
	mov		YL,OutB         ; channel B amplitude lowered to about 63%
	lsr		OutB			; TMP = TMP - (TMP/4 + TMP/8) eqivalent of
	lsr		OutB            ; TMP = 0.625 * TMP
	sub		YL,OutB
	lsr		OutB
	sub		YL,OutB
	add		OutA,YL			; add channel B volume to channels A and C
	add		OutC,YL
// --------------------------------------------------------------
#elif CHANNELS == 3
// three channel version ----------------------------------------
	#if MCU_TYPE == 0
		out	OCR2,OutB
	#else
		sts	OCR2A,OutB
	#endif
// --------------------------------------------------------------
#endif

// --------------------------------------------------------------
#if SPEAKER == 1
// speaker port enabled -----------------------------------------
    ; TODO: speaker amplitude is about 69% of channel amplitude,
    ; TODO: probably should be lowered to 63% or lower
	sbic	PinD,b1			; check PD1 (SPEAKER PORT INPUT) skip if bit is not set
	add		OutA,C1F		; add some volume to channel A
	sbic	PinD,b1			; check PD1 (SPEAKER PORT INPUT) skip if bit is not set
	add		OutC,C1F		; add some volume to channel A
// --------------------------------------------------------------
#endif


#if MCU_TYPE == 0
	out		OCR1AL,OutA		; update PWM counters
	out		OCR1BL,OutC
#else
	sts		OCR1AL,OutA		; update PWM counters
	sts		OCR1BL,OutC
#endif

	rjmp	_MAIN_LOOP
	// MAIN LOOP END ====================================================================

; ==============================================================================
; Subroutines
; ==============================================================================
_COPY:                      ; copy from flash to SRAM
    lpm     r16, Z+
    st      X+, r16
    dec     r18
    brne    _COPY
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
