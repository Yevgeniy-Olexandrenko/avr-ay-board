# AY-3-8912 Emulator (AVR-AY)

The replacement board for the famous AY-3-8910/AY-3-8912/YM2149F sound chip of the ZX-Spectrum 128 and others. Based on the schematic and firmware from https://www.avray.ru, https://zx-pk.ru/threads/10510-emulyator-ay-8910-na-atmega.html and https://github.com/andykarpov/turbosound28p resources.

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

TODO

### Parallel communication mode

The following sketch is for parallel data streaming to AY-3-8910 / AY-3-8912 / YM2149F or to an emulator. Data is received by the Arduino via the corresponding COM port and sent to the chip in parallel.

```c
 // connect to D0,1,...,7
const int ad[8] = { 8, 9, 2, 3, 4, 5, 6, 7 };

const int pinBC1  = 10;
const int pinBDIR = 11;

// fast pin switching macros
#define CLR(x,y) (x&=(~(1<<y)))
#define SET(x,y) (x|=(1<<y))
#define __BCPORT__ PORTB
#define __BC1__    2
#define __BDIR__   3

void send_data(byte address, byte data) {
  // write address to pins
  PORTB |= address & 0x03;
  PORTD |= address & 0xFC;
  
  // validate addess
  __BCPORT__ |= (1 << __BDIR__) + (1 << __BC1__);
  delayMicroseconds(1);
  __BCPORT__ &= ~((1 << __BDIR__) + (1 << __BC1__));
  PORTB &= ~(address & 0x03);
  PORTD &= ~(address & 0xFC);

  // write data to pins
  PORTB |= data & 0x03;
  PORTD |= data & 0xFC;
  
  // validate data
  SET(__BCPORT__,__BDIR__);
  delayMicroseconds(1);
  CLR(__BCPORT__,__BDIR__);
  PORTB &= ~(data & 0x03);
  PORTD &= ~(data & 0xFC);
}

void setup() {
  // init pins
  for (int i=0; i < 8; i++) {
    pinMode(ad[i], OUTPUT);
  }
  pinMode(pinBC1, OUTPUT);
  pinMode(pinBDIR, OUTPUT);

  // inactive mode
  digitalWrite(pinBC1, LOW);
  digitalWrite(pinBDIR, LOW);

  // serial init
  Serial.begin(57600);
}

void loop() {
  byte reg;
  while (true) {
    do {
      while (Serial.available() < 1) delayMicroseconds(1);
      reg = Serial.read();
    } while (reg > 15);

    while (Serial.available() < 1) delayMicroseconds(1);
    send_data(reg, Serial.read());
  }
}
```

# Hardware

The **[schematic](/hardware/AY-3-8912-Emulator-v1.1_Schematic.pdf)** of the device is quite simple. The heart of the emulator is an 8-bit ATmega series microcontroller, which runs at an overclocked frequency and performs low-level simulation of the sound chip. The rest of the device is three low-pass filters with a cutoff frequency of about 20 kHz and three communication interfaces. An analog signals of three audio channels are generated at the output of the emulator.

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

### Serial interface

Pin|Name|Function
-|-|-
1|`GND`|Ground
2|`VCC`|Power Supply (+5V)
3|`SPK`|Speaker Input
4|`RX`| Serial Data Input

### In-Circuit Serial Programming interface

Pin|Name|Function|Pin|Name|Function
-|-|-|-|-|-
1|`MISO`|Master In/Slave Out|2|`VCC`|Power Supply
3|`SCK`|Clock|4|`MOSI`|Master Out/Slave In
5|`RES`|Reset|6|`GND`|Ground


# Firmware

TODO

# References, Links and Notes

TODO

**EasyEDA** project **[HERE](https://easyeda.com/yevgeniy.olexandrenko/avr-ay)**.
