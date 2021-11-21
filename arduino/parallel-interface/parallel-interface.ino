#include <util/delay.h>

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
