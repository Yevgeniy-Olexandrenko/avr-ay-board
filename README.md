# AY-3-8912 Emulator (AVR-AY)

The replacement board for the famous AY-3-8910/AY-3-8912/YM2149F sound chip of the ZX-Spectrum 128 and others. Based on the schematic and firmware from https://www.avray.ru, https://zx-pk.ru/threads/10510-emulyator-ay-8910-na-atmega.html and https://github.com/andykarpov/turbosound28p resources.

![Photo](/hardware/AY-3-8912-Emulator-v1.1_Photo.jpg)

### Features:
- Complete chip emulation
- Parallel mode support (Read mode also supported)
- Serial mode support using `RX` pin at speed 57600
- Speaker input support using `SPK` pin

### Serial protocol communication:
Baud Rate|Data Bits|Stop Bits|Parity
-|-|-|-
57600|8|1|NONE

Registers sent as a pair of values:
- Register number `0-13`
- Register value

To synchronize, just send `0xFF` at start of sending.

# Firmware

TODO

**EasyEDA** project **[HERE](https://easyeda.com/yevgeniy.olexandrenko/avr-ay)**.
