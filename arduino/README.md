## PSG to Arduino connection ##

AY-3-8910|AY-3-8912|PSG Signal|Arduino|Description
-|-|-|-|-
40|3|Vcc (+5V)|+5V|Power supply
1|6|Vss (GND)|GND|Ground reference
37|28|DA0|A0|Data/Address Bit 0
36|27|DA1|A1|Data/Address Bit 1
35|26|DA2|A2|Data/Address Bit 2
34|25|DA3|A3|Data/Address Bit 3
33|24|DA4|D4|Data/Address Bit 4
32|23|DA5|D5|Data/Address Bit 5
31|22|DA6|D6|Data/Address Bit 6
30|21|DA7|D7|Data/Address Bit 7
29|20|BC1|D8|Bus Control 1
28|-|BC2|+5V|Bus Control 2
27|18|BDIR|D9|Bus Direction
25|17|A8|+5V|Address 8
24|-|#A9|GND|Address 9 (Low active)
23|16|#RESET|D2|Reset (Low active)
22|15|CLOCK|D3|Clock
4|5|ANALOG A|`Audio A`|Analog output
3|4|ANALOG B|`Audio B`|Analog output
38|1|ANALOG C|`Audio C`|Analog output