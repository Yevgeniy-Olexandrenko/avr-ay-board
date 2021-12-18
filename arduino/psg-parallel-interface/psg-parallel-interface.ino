
volatile byte reg = 0xFF;

ISR(USART_RX_vect)
{
    byte data = UDR0;
    if (bit_is_clear(UCSR0A, FE0))
    {
        if (reg <= 15)
        {
            PSG_Send(reg, data);
            reg = 0xFF;
        }
        else if (data <= 15)
        {
            reg = data;
        }
    }
}

void setup()
{
    cli();

    PSG_Init();

    // serial init at 57600
    UBRR0H = 0;
    UBRR0L = 0x10;
    UCSR0C = 0x06;
    UCSR0A = 0;
    UCSR0B = 0x90;
    pinMode(0, INPUT);

    sei();
}

void loop()
{
}
