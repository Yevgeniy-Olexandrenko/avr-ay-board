#include <util/delay.h>

// -----------------------------------------------------------------------------

// data bus bits D0-D3 (Arduino pins A0-A3)
#define LSB_DDR  DDRC
#define LSB_PORT PORTC
#define LSB_PIN  PINC
#define LSB_MASK 0b00001111

// data bus bits D4-D7 (Arduino pins D4-D7)
#define MSB_DDR  DDRD
#define MSB_PORT PORTD
#define MSB_PIN  PIND
#define MSB_MASK 0b11110000

// control bus BC1 and BDIR signals
#define BUS_PORT PORTB
#define BUS_DDR  DDRB
#define PIN_BC1  PB0   // Arduino pin D8
#define PIN_BDIR PB1   // Arduino pin D9

// -----------------------------------------------------------------------------

void psg_data_set(byte data)
{
    // set ports to output
    LSB_DDR  |= LSB_MASK;
    MSB_DDR  |= MSB_MASK;

    // set data bits to output ports
    LSB_PORT = (LSB_PORT & ~LSB_MASK) | (data & LSB_MASK);
    MSB_PORT = (MSB_PORT & ~MSB_MASK) | (data & MSB_MASK);
}

void psg_data_get(byte& data)
{
    // get bata bits from input ports
    data = (LSB_PIN & LSB_MASK) | (MSB_PIN & MSB_MASK);
}

void psg_inactive()
{
    BUS_PORT &= ~(1 << PIN_BDIR | 1 << PIN_BC1);

    // set ports to input
    LSB_DDR  &= ~LSB_MASK;
    MSB_DDR  &= ~MSB_MASK;

    // enable pull-up resistors
    LSB_PORT = (LSB_PORT & ~LSB_MASK) | (0xFF & LSB_MASK);
    MSB_PORT = (MSB_PORT & ~MSB_MASK) | (0xFF & MSB_MASK);
}

void psg_address(byte reg)
{
    psg_data_set(reg);
    BUS_PORT |= (1 << PIN_BDIR | 1 << PIN_BC1);
    _delay_us(0.300);
    psg_inactive();
    _delay_us(0.100);
}

void psg_write(byte data)
{
    psg_data_set(data);
    BUS_PORT |= (1 << PIN_BDIR);
    _delay_us(0.500);
    psg_inactive();
}

void psg_read(byte& data)
{
    BUS_PORT |= (1 << PIN_BC1);
    _delay_us(0.200);
    psg_data_get(data);
    psg_inactive();
}

// -----------------------------------------------------------------------------

void psg_init()
{
    // 1.77 MHz on pin D3 (PD3)
    DDRD  |= (1 << PD3);
    TCCR2A = (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
    TCCR2B = (1 << WGM22) | (1 << CS20);
    OCR2A  = 8;
    OCR2B  = 3; 

    // init pins for output
    BUS_DDR |= (1 << PIN_BDIR);
    BUS_DDR |= (1 << PIN_BC1);

    // inactive mode
    psg_inactive();
}

void psg_send(byte reg, byte data)
{
    psg_address(reg);
    psg_write(data);
}

byte psg_receive(byte reg)
{
    byte data;
    psg_address(reg);
    psg_read(data);
    return data;
}
