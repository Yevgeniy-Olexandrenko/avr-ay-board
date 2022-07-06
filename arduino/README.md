## PSG to Arduino connection ##

AY-3-8910|AY-3-8912|PSG Signal|Arduino|ATMega328|Description
-|-|-|-|-|-
40|3|Vcc (+5V)|+5V|VCC|Power supply +5V
1|6|Vss (GND)|GND|GND|Ground reference
37|28|DA0|A0|PC0|Data/Address Bit 0
36|27|DA1|A1|PC1|Data/Address Bit 1
35|26|DA2|A2|PC2|Data/Address Bit 2
34|25|DA3|A3|PC3|Data/Address Bit 3
33|24|DA4|D4|PD4|Data/Address Bit 4
32|23|DA5|D5|PD5|Data/Address Bit 5
31|22|DA6|D6|PD6|Data/Address Bit 6
30|21|DA7|D7|PD7|Data/Address Bit 7
29|20|BC1|D8|PB0|Bus Control 1
28|-|BC2|+5V|VCC|Bus Control 2
27|18|BDIR|D9|PB1|Bus Direction
25|17|A8|+5V|VCC|Address Bit 8
24|-|#A9|GND|GND|Address Bit 9 (Low active)
23|16|#RESET|D2|PD2|Reset (Low active)
22|15|CLOCK|D3|PD3|Master clock (1-2 MHz)
4|5|ANALOG A|-|-|Analog output channel A
3|4|ANALOG B|-|-|Analog output channel B
38|1|ANALOG C|-|-|Analog output channel C