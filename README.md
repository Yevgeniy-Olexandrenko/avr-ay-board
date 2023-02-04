# Introduction

**AY-3-8912 Emulator (AVR-AY)** is a replacement board for the famous AY-3-8910/AY-3-8912/YM2149F sound chip of the ZX-Spectrum 128 and others. Based on the schematic and firmware from [AVR-AY project](https://www.avray.ru), [discussion on ZX-PK.ru](https://zx-pk.ru/threads/10510-emulyator-ay-8910-na-atmega.html) and [Turbo Sound schematic](https://github.com/andykarpov/turbosound28p) resources.

![Photo](/hardware/photo.jpg)

### Features:
- Complete chip emulation (sound generation only)
- Parallel mode write/read operations support
- Serial mode write operations support

# Usage

### Serial communication mode

Baud Rate|Data Bits|Stop Bits|Parity
-|-|-|-
57600|8|1|NONE

Registers are sent as a pair of values: register number (0-13), then register value. To synchronize, just send `0xFF` at the start of sending.

This sound chip emulator can be used in conjunction with the [AVR-AY Player](https://www.avray.ru/avr-ay-player) or [PSG Tools](https://github.com/Yevgeniy-Olexandrenko/psg-tools). You will need the most ordinary USB to serial TTL converter. Just connect `+5V`, `GND` and `TX` pins of the converter to `VCC`, `GND` and `RX` pins of this emulation device, open corrsponding `COM` port in the player/tool and start playing music.

### Parallel communication mode

...

# Hardware

The '[schematic](/hardware/v1.3/AY-3-8912-Emulator-v1.3_Schematic.pdf)' of the device is quite simple. The heart of the emulator is a 8-bit ATmega series microcontroller, which runs at an overclocked frequency and performs low-level simulation of the sound chip. The rest of the device is three low-pass filters with a cutoff frequency of about 20 kHz, three communication interfaces and three output audio channels with analog signal waveform.

### Serial interface

Pin|Name|Function
-|-|-
1|`GND`|Ground reference
2|`VCC`|Power Supply (+5V)
3|`TX`|Serial dada output (Speaker Input for AVR-AY)
4|`RX`|Serial Data Input

### Parallel interface

Pin|Name|Function|Pin|Name|Function
-|-|-|-|-|-
1|`C`|Analog Channel C|28|`D0`|Data/Address 0
2|`NC`|*no connect*|27|`D1`|Data/Address 1
3|`VCC`|Power Supply (+5V)|26|`D2`|Data/Address 2
4|`B`|Analog Channel B|25|`D3`|Data/Address 3
5|`A`|Analog Channel A|24|`D4`|Data/Address 4
6|`GND`|Ground|23|`D5`|Data/Address 5
7|`NC`|*no connect*|22|`D6`|Data/Address 6
8|`NC`|*no connect*|21|`D7`|Data/Address 7
9|`NC`|*no connect*|20|`BC1`|Bus Control 1
10|`NC`|*no connect*|19|`NC`|*no connect*
11|`NC`|*no connect*|18|`BDIR`|Bus Direction
12|`NC`|*no connect*|17|`NC`|*no connect*
13|`NC`|*no connect*|16|`RES`|Reset (Low active)
14|`NC`|*no connect*|15|`NC`|*no connect*

### In-Circuit Serial Programming interface

Pin|Name|Function|Pin|Name|Function
-|-|-|-|-|-
1|`MISO`|Master In/Slave Out|2|`VCC`|Power Supply
3|`SCK`|Clock|4|`MOSI`|Master Out/Slave In
5|`RES`|Reset|6|`GND`|Ground

### Hardware configuration

The default hardware configuration of the device assumes the use of an ATmega88PA microcontroller with a 27 MHz crystal resonator. According to reviews, it should work reliably. But you are free to use another microcontroller (ATmega8, ATmega48, ATmega168 and ATmega328) and a quartz resonator with another frequency (20 MHz, 24 MHz, 25 MHz, 28.332 MHz, 28 MHz, 30 MHz, 32 MHz and 40 MHz). It should be clear that firmware with full functionality (standard) may be unstable at a lower operation frequency. In this case, you need to use the firmware configuration for the specific communication interface.

# Firmware

TODO

# References, Links and Notes

1. [Project on EasyEDA](https://easyeda.com/yevgeniy.olexandrenko/avr-ay)
2. [AVR-AY Home Page](https://www.avray.ru)
3. [Discussion on ZX-PK.ru](https://zx-pk.ru/threads/10510-emulyator-ay-8910-na-atmega.html)
4. [AY-3-8910/12 Datasheet](/datasheet/AY-3-8910-microchip.pdf)
5. [YM2149 Datasheet](/datasheet/ym2149-yamaha.pdf)
6. [ATmega88 Datasheet](/datasheet/ATmega88.pdf)
