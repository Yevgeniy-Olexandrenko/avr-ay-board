# AY-3-8912 Emulator

AY-3-8912 Emulator is a replacement board for AY-3-8910, AY-3-8912, and YM2149F sound chips, designed for the DIP-28 form factor.

![Photo](/hardware/v1.3/AY-3-8912-Emulator-v1.3_Photo_V2.jpg)

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
