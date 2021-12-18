volatile byte buffer[256];
volatile byte wr_ptr = 0;
volatile byte rd_ptr = 0;
volatile byte reg = 0xFF;

ISR(USART_RX_vect)
{
    byte data = UDR0;
    if (bit_is_clear(UCSR0A, FE0))
    {
        if (reg <= 15)
        {
            buffer[wr_ptr++] = reg;
            buffer[wr_ptr++] = data;
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
    while(true)
    {
        while(rd_ptr != wr_ptr)
        {
            byte reg  = buffer[rd_ptr++];
            byte data = buffer[rd_ptr++];
            PSG_Send(reg, data);
        }
    }
}
