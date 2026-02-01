## AVR-PSG firmware differences from AVR-AY: ##

- Removed support for ATmega8A
- Use T0 as internal clock source instead of T1
- Now A & C have same amplitude as B (T1 PWM works in simple 8-bit mode)
- Increased the maximum amplitude of all channels by 5 times
- Removed support for 2ch version
- Replaced volume tables, now AY's envelope period has 16 steps
- Improved registers reading
