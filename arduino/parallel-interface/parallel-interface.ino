#include <util/delay.h>

// data bus bits D0-D3 (Arduino pins A0-A3)
#define LSB_PORT PORTC
#define LSB_DDR  DDRC
#define LSB_MASK 0b00001111

// data bus bits D4-D7 (Arduino pins D4-D7)
#define MSB_PORT PORTD
#define MSB_DDR  DDRD
#define MSB_MASK 0b11110000

// control bus BC1 and BDIR signals
#define BUS_PORT PORTB
#define BUS_DDR  DDRB
#define PIN_BC1  PB0   // Arduino pin D8
#define PIN_BDIR PB1   // Arduino pin D9

byte serial_read()
{
    while (!Serial.available()) _delay_us(1);
    return Serial.read();
}

void psg_data(byte data)
{
    LSB_PORT = (LSB_PORT & ~LSB_MASK) | (data & LSB_MASK);
    MSB_PORT = (MSB_PORT & ~MSB_MASK) | (data & MSB_MASK);
}

void psg_inactive()
{
    BUS_PORT &= ~(1 << PIN_BDIR | 1 << PIN_BC1);
}

void psg_address()
{
    BUS_PORT |= (1 << PIN_BDIR | 1 << PIN_BC1);
    _delay_us(0.300);
    psg_inactive();
}

void psg_write()
{
    BUS_PORT |= (1 << PIN_BDIR);
    _delay_us(0.300);
    psg_inactive();
}

void psg_send(byte reg, byte data)
{
    psg_data(reg);
    psg_address();
    psg_data(data);
    psg_write();
}

void setup()
{
    // 1.77 MHz on pin D3 (PD3)
    DDRD  |= (1 << PD3);
    TCCR2A = (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
    TCCR2B = (1 << WGM22) | (1 << CS20);
    OCR2A  = 8;
    OCR2B  = 3; 

    // init pins for output
    LSB_DDR |= LSB_MASK;
    MSB_DDR |= MSB_MASK;
    BUS_DDR |= (1 << PIN_BDIR);
    BUS_DDR |= (1 << PIN_BC1);

    // inactive mode
    psg_inactive();

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
        psg_send(reg, data);
    }
}
