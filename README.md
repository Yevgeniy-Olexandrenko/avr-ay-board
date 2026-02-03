# AY-3-8912 Emulator

AY-3-8912 Emulator is a replacement board for AY-3-8910, AY-3-8912, and YM2149F sound chips, designed for the DIP-28 form factor.

![Photo](/hardware/v1.3/AY-3-8912-Emulator-v1.3_Photo_V2.jpg)

# Programmable Sound Generator

AY-3-8910 is a programmable sound generator (PSG) developed by General Instrument in the late 1970s. It became one of the most widely used sound chips of the 8-bit era, appearing in many home computers and arcade systems. The chip provides three independent tone channels with programmable frequency and amplitude, as well as a noise generator that can be mixed into each channel. Sound generation is controlled through internal registers, making the AY-3-8910 easy to interface with microprocessors of its time. Its distinctive sound strongly influenced the chiptune audio style of early computer and video game systems.

YM2149F is a fully compatible version of the AY-3-8910 manufactured by Yamaha. It follows the same internal architecture and programming model but features improved electrical characteristics and slightly different analog output behavior, especially at lower volume levels. Due to its stability and cleaner output, the YM2149F was widely used in European computer systems. From a software perspective, both chips are interchangeable and can be driven using identical register-level code.

AY-3-8912 is a more compact and now relatively rare variant of the AY-3-8910. It preserves the full sound generation capabilities of the original chip but offers a reduced number of general-purpose I/O lines, targeting systems that did not require additional parallel ports. While less common, it remains fully compatible in terms of audio functionality. Together, these chips represent an important milestone in the development of digital sound hardware and remain relevant in retro computing and emulation projects.

Internally, the AY-3-8910 and YM2149F use a register-based design with 16 programmable registers accessed over an 8-bit data bus. Sound generation is based on three independent square-wave tone generators with programmable frequency dividers and a shared pseudo-random noise generator with an adjustable period. A mixer register controls the contribution of tone and noise sources for each channel, while per-channel amplitude control allows either fixed volume levels or envelope-driven modulation.

The envelope generator provides hardware-controlled amplitude changes using a programmable period and a set of predefined envelope shapes, reducing the need for continuous CPU updates. Output levels are produced by internal resistor-ladder DACs, which are inherently nonlinear; together with the analog output stages, this contributes to the characteristic sound of these chips. Although the YM2149F remains software-compatible with the AY-3-8910, minor hardware differences such as an optional internal clock divider and slightly different amplitude resolution can result in subtle but audible variations in sound.

# Hardware

TODO

- DIP-28 form factor, pin-compatible with AY/YM family
- MCU-based PSG emulation implemented in firmware
- PWM-based audio outputs with analog low-pass filtering
- External EEPROM for configuration storage
- ICSP interface for firmware flashing and debugging

# Firmware

The emulator aims to reproduce original AY/YM behavior at the register and audio level.
Due to architectural differences between the MCU-based implementation and original chips,
some timing and analog characteristics may differ.

Feature|FW 1.0|Comment
-|:-:|-
AY-3-8910/AY-3-8912 specific behavior|⚠️|Partially implemented in AY FW build
YM2149F specific behavior|⚠️|Partially implemented in YM FW build
Data/Address Bits 7-0 (DA7-DA0, pins 28-21)|✅|
Bus Control 1 (BC1, pin 20)|✅|Handled via HW interrupt (INT0)
Bus Control 2 (BC2, pin 19)|❗|Will not be implemented (not required)
Bus direction (BDIR, pin 18)|✅|Handled via HW interrupt (INT1)
Address 8 (A8, pin 17)|❌|Planned for implementation
Reset input (#RESET, pin 16)|✅|
Clock input (CLOCK, pin 15)|⚠️|Clock is defined in EEPROM configuration file
I/O Port Bits 7-0 (IOA7-IOA0, pins 7-14)|❗|Will not be implemented (HW limitation)
Analog Channel A,B,C (pins 5,4,1)|✅|Three PWMs with low-pass filters
Parallel I/O: Write data to register|✅|
Parallel I/O: Read data from register|✅|
Serial I/O: Write data to register|✅|UART, 57600 baud (see protocol)
Serial I/O: Read data from register|❌|Planned for implementation
Firmware configuration via J1,J2|❌|Planned for implementation
In-Circuit Serial Programming (ICSP)|✅|Via ICSP pins (or via PIO pins since HW 1.5)

### Known Limitations

- IOA port (pins 7–14) is not supported due to HW limitations.
- External CLOCK input is not used; clock frequency is configured via EEPROM.
- BC2 signal is not implemented, as it is not required for target systems.

### Planned Features

- A8 address line support
- Serial read access
- Firmware configuration via jumpers (J1/J2)

# Communication

### Parallel I/O Interface

The parallel interface follows the original AY-3-8910 / AY-3-8912 datasheet behavior.
It supports register addressing and data read/write operations using BC1 and BDIR control signals.

Detailed description:
- See `docs/parallel_io.md`

### Serial Interface (UART)

An alternative serial interface is provided for register access and debugging purposes.

- UART, 57600 baud
- 8 data bits, no parity, 1 stop bit (8N1)
- Write access to PSG registers is supported
- Read access is planned

Protocol description:
- See `docs/serial_protocol.md`
