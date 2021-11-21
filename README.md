# Introduction

**AY-3-8912 Emulator (AVR-AY)** is a replacement board for the famous AY-3-8910/AY-3-8912/YM2149F sound chip of the ZX-Spectrum 128 and others. Based on the schematic and firmware from [AVR-AY project](https://www.avray.ru), [discussion on ZX-PK.ru](https://zx-pk.ru/threads/10510-emulyator-ay-8910-na-atmega.html) and [Turbo Sound schematic](https://github.com/andykarpov/turbosound28p) resources.

![Photo](/hardware/AY-3-8912-Emulator-v1.1_Photo.jpg)

### Features:
- Complete sound chip emulation
- Parallel mode support (Read mode also supported)
- Serial mode support using `RX` pin at speed 57600
- Speaker input support using `SPK` pin

# Usage

### Serial communication mode

Baud Rate|Data Bits|Stop Bits|Parity
-|-|-|-
57600|8|1|NONE

Registers are sent as a pair of values: register number (0-13), then register value. To synchronize, just send `0xFF` at the start of sending.

This sound chip emulator can be used in conjunction with the [AVR-AY Player](https://www.avray.ru/avr-ay-player). You will need the most ordinary USB to serial TTL converter. Just connect +5V, GND and TX pins of the converter to VCC, GND and RX pins of this emulation device, choose COM port, `Open` it in the player and start playing music.

### Parallel communication mode

Following Arduino sketch is for parallel data streaming to a sound chip emulator. Data is received by the Arduino via the corresponding COM port and sent to the chip in parallel. For quick and easy testing, you can use the **AVR-AY Player** as described in the previous section. Just select the COM port of the Arduino board.

```c
#define LSB_PORT PORTB      // data bus bits D0-D1
#define LSB_DDR  DDRB
#define MSB_PORT PORTD      // data bus bits D2-D7
#define MSB_DDR  DDRD
#define BUS_PORT PORTB      // control bus BC1 and BDIR pins
#define BUS_DDR  DDRB

#define MSK_LSB  0b00000011 // data bus bits D0-D1
#define MSK_MSB  0b11111100 // data bus bits D2-D7
#define PIN_BC1  PB2        // control bus BC1 pin
#define PIN_BDIR PB3        // control bus BDIR pin

// writes to data bus
#define dbus_set(data) { LSB_PORT |=  ((data) & MSK_LSB); MSB_PORT |=  ((data) & MSK_MSB); }
#define dbus_clr(data) { LSB_PORT &= ~((data) & MSK_LSB); MSB_PORT &= ~((data) & MSK_MSB); }

// writes to control bus
#define cbus_set(pin)  { BUS_PORT |=  (1 << (pin)); }
#define cbus_clr(pin)  { BUS_PORT &= ~(1 << (pin)); }

byte serial_read()
{
    while (!Serial.available()) _delay_us(1);
    return Serial.read();
}

void send_to_psg(byte reg, byte data)
{
    // WRITE REGISTER NUMBER
    dbus_set(reg);      // write address to pins
    cbus_set(PIN_BDIR); // set BC1+BDIR pins, latch address mode
    cbus_set(PIN_BC1);
    _delay_us(0.500);   // set+hold address delay 500ns (400+100 min)
    cbus_clr(PIN_BDIR); // clear BC1+BDIR pins, inactive mode
    cbus_clr(PIN_BC1);
    dbus_clr(reg);      // reset pins to tristate mode

    // WRITE REGISTER DATA
    dbus_set(data);     // write data to pins
    cbus_set(PIN_BDIR); // set BDIR pin, write to reg mode
    _delay_us(0.250);   // 250ns delay (250min-500max)
    cbus_clr(PIN_BDIR); // clear BDIR pin, inactive mode
    dbus_clr(data);     // reset pins to tristate mode
}

void setup()
{
    // init pins for output
    LSB_DDR |= MSK_LSB;
    MSB_DDR |= MSK_MSB;
    BUS_DDR |= (1 << PIN_BDIR);
    BUS_DDR |= (1 << PIN_BC1);

    // inactive mode
    cbus_clr(PIN_BDIR);
    cbus_clr(PIN_BC1);

    // serial init
    Serial.begin(57600);
}

void loop()
{
    while (true)
    {
        // wait for register number
        byte reg = serial_read();
        if (reg > 13) continue;

        // read data and send everything to PSG
        byte data = serial_read();
        send_to_psg(reg, data);
    }
}
```

# Hardware

The [schematic](/hardware/AY-3-8912-Emulator-v1.1_Schematic.pdf) of the device is quite simple. The heart of the emulator is a 8-bit ATmega series microcontroller, which runs at an overclocked frequency and performs low-level simulation of the sound chip. The rest of the device is three low-pass filters with a cutoff frequency of about 20 kHz and three communication interfaces. An analog signals of three audio channels are generated at the output of the emulator.

### Serial interface

Pin|Name|Function
-|-|-
1|`GND`|Ground
2|`VCC`|Power Supply (+5V)
3|`SPK`|Speaker Input
4|`RX`| Serial Data Input

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
