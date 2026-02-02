# Introduction

AY-3-8912 Emulator is a replacement board for AY-3-8910, AY-3-8912, and YM2149F sound chips, designed for the DIP-28 form factor.

![Photo](/hardware/v1.3/AY-3-8912-Emulator-v1.3_Photo.jpg)

# Features

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

---

## Hardware Overview

- DIP-28 form factor, pin-compatible with AY/YM family
- MCU-based PSG emulation implemented in firmware
- PWM-based audio outputs with analog low-pass filtering
- External EEPROM for configuration storage
- ICSP interface for firmware flashing and debugging

---

## Communication Interfaces

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

---

## Firmware

The firmware implements PSG emulation logic and hardware signal handling.

- Developed using **Microchip Studio**
- Separate firmware builds for AY-3-8910/AY-3-8912 and YM2149F behavior
- MCU handles parallel bus interrupts, audio generation, and configuration logic

---

### Build and Flash

Firmware build and flashing process:

- Build environment: Microchip Studio
- Flashing tool: `avrdude`
- EEPROM configuration file is required
- MCU fuse settings must match the selected clock configuration

Detailed instructions:
- See `docs/build_and_flash.md`

---

## Configuration

The emulator uses EEPROM-stored parameters to configure runtime behavior, including:

- Internal clock frequency
- Audio output parameters
- Interface-related options

Configuration format and examples:
- See `docs/eeprom_config.md`

---

## Emulation Notes

The emulator aims to reproduce original AY/YM behavior at the register and audio level.
Due to architectural differences between the MCU-based implementation and original chips,
some timing and analog characteristics may differ.

Known behavior details and quirks:
- See `docs/emulation_notes.md`

---

## Repository Structure

- `firmware/` — MCU firmware source code
- `hardware/` — schematics, PCB layouts, board revisions, photos
- `docs/` — protocols, build instructions, configuration and emulation notes

---

## Project Status

Active development.
