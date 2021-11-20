#include <util/delay.h>

#define LSB_DDR  DDRB
#define MSB_DDR  DDRD
#define BUS_DDR  DDRB

#define LSB_PORT PORTB
#define MSB_PORT PORTD
#define BUS_PORT PORTB

#define PIN_BC1  PB2
#define PIN_BDIR PB3

#define SET_DATA(data) { LSB_PORT |=  ((data) & 0b00000011); MSB_PORT |=  ((data) & 0b11111100); }
#define CLR_DATA(data) { LSB_PORT &= ~((data) & 0b00000011); MSB_PORT &= ~((data) & 0b11111100); }

void send_to_psg(byte address, byte data)
{
    // WRITE REGISTER NUMBER
    SET_DATA(address);            // write address to pins
    bitSet(BUS_PORT, PIN_BDIR);   // set BC1+BDIR pins, latch address mode
    bitSet(BUS_PORT, PIN_BC1);
    _delay_us(0.500);             // set+hold address delay 500ns (400+100 min)
    bitClear(BUS_PORT, PIN_BDIR); // clear BC1+BDIR pins, inactive mode
    bitClear(BUS_PORT, PIN_BC1);
    CLR_DATA(address);            // reset pins to tristate mode

    // WRITE REGISTER DATA
    SET_DATA(data);               // write data to pins
    bitSet(BUS_PORT, PIN_BDIR);   // set BDIR pin, write to reg mode
    _delay_us(0.250);             // 250ns delay (250min-500max)
    bitClear(BUS_PORT, PIN_BDIR); // clear BDIR pin, inactive mode
    CLR_DATA(data);               // reset pins to tristate mode
}

void setup()
{
    // init pins
    LSB_DDR |= 0b00000011;
    MSB_DDR |= 0b11111100;
    bitSet(BUS_DDR, PIN_BDIR);
    bitSet(BUS_DDR, PIN_BC1);

    // inactive mode
    bitClear(BUS_PORT, PIN_BDIR);
    bitClear(BUS_PORT, PIN_BC1);

    // serial init
    Serial.begin(57600);
}

void loop()
{
    while (true)
    {
        // wait for register number
        while (!Serial.available()) delayMicroseconds(1);
        byte reg = Serial.read();
        if (reg > 15) continue;

        // read data and send everything to PSG
        while (!Serial.available()) delayMicroseconds(1);
        byte data = Serial.read();
        send_to_psg(reg, data);
    }
}
