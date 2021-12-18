#include <util/delay.h>

// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------

// data bus bits D0-D3 (Arduino pins A0-A3)
#define LSB_DDR  DDRC
#define LSB_PORT PORTC
#define LSB_PIN  PINC
#define LSB_MASK 0x0F

// data bus bits D4-D7 (Arduino pins D4-D7)
#define MSB_DDR  DDRD
#define MSB_PORT PORTD
#define MSB_PIN  PIND
#define MSB_MASK 0xF0

// control bus BC1 and BDIR signals
#define BUS_PORT PORTB
#define BUS_DDR  DDRB
#define PIN_BC1  PB0   // Arduino pin D8
#define PIN_BDIR PB1   // Arduino pin D9

// timing delays (nano seconds)
#define PSG_Delay(ns) _delay_us(0.001f * (ns))
#define tAS 800 // min 400 ns by datasheet
#define tAH 100 // min 100 ns by datasheet
#define tDW 500 // min 500 ns by datasheet
#define tDH 100 // min 100 ns by datasheet
#define tDA 500 // max 500 ns by datasheet
#define tTS 100 // max 200 ns by datasheet

// MCU clock to PSG clock deviders
#define CLK_177_MHz 9
#define CLK_200_MHz 8

// -----------------------------------------------------------------------------
// Low Level Access
// -----------------------------------------------------------------------------

void PSG_GetDataBus(byte& data)
{
    // get bata bits from input ports
    data = (LSB_PIN & LSB_MASK) | (MSB_PIN & MSB_MASK);
}

void PSG_SetDataBus(byte data)
{
    // set ports to output
    LSB_DDR |= LSB_MASK;
    MSB_DDR |= MSB_MASK;

    // set data bits to output ports
    LSB_PORT = (LSB_PORT & ~LSB_MASK) | (data & LSB_MASK);
    MSB_PORT = (MSB_PORT & ~MSB_MASK) | (data & MSB_MASK);
}

void PSG_ReleaseDataBus()
{
    // setup ports to input
    LSB_DDR &= ~LSB_MASK;
    MSB_DDR &= ~MSB_MASK;

    // enable pull-up resistors
    LSB_PORT |= LSB_MASK;
    MSB_PORT |= MSB_MASK;
}

void PSG_Inactive()
{
    BUS_PORT &= ~(1 << PIN_BDIR | 1 << PIN_BC1);
}

void PSG_Address(byte reg)
{
    PSG_SetDataBus(reg);
    BUS_PORT |= (1 << PIN_BDIR | 1 << PIN_BC1);
    PSG_Delay(tAS);
    PSG_Inactive();
    PSG_Delay(tAH);
    PSG_ReleaseDataBus();
}

void PSG_Write(byte data)
{
    PSG_SetDataBus(data);
    BUS_PORT |= (1 << PIN_BDIR);
    PSG_Delay(tDW);
    PSG_Inactive();
    PSG_Delay(tDH);
    PSG_ReleaseDataBus();
}

void PSG_Read(byte& data)
{
    BUS_PORT |= (1 << PIN_BC1);
    PSG_Delay(tDA);
    PSG_GetDataBus(data);
    PSG_Inactive();
    PSG_Delay(tTS);
}

// -----------------------------------------------------------------------------
// High Level Access
// -----------------------------------------------------------------------------

void PSG_Init()
{
    // 1.77 MHz on pin D3 (PD3)
    DDRD  |= (1 << PD3);
    TCCR2A = (1 << COM2B1) | (1 << WGM21) | (1 << WGM20);
    TCCR2B = (1 << WGM22) | (1 << CS20);
    OCR2A  = (CLK_177_MHz - 1);
    OCR2B  = (CLK_177_MHz / 2); 

    // setup control and data bus
    BUS_DDR |= (1 << PIN_BDIR);
    BUS_DDR |= (1 << PIN_BC1);
    PSG_Inactive();
    PSG_ReleaseDataBus();
}

void PSG_Send(byte reg, byte data)
{
    PSG_Address(reg);
    PSG_Write(data);
}

byte PSG_Receive(byte reg)
{
    byte data;
    PSG_Address(reg);
    PSG_Read(data);
    return data;
}
