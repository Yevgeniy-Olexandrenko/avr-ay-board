
byte regsLow[32];
byte regsInst[32];

void print_hex(byte data)
{
    Serial.print(data > 0x0F ? "0x" : "0x0");
    Serial.print(data, HEX);
}

void setup()
{
    psg_init();
    Serial.begin(9600);

    for (byte reg = 0; reg < 32; ++reg)
    {
        psg_send(reg, 0xFF);
    }

    for (byte reg = 0; reg < 32; ++reg)
    {
        regsLow[reg] = psg_receive(reg);
    }

    for (byte reg = 0; reg < 32; ++reg)
    {
        psg_address(reg);
        psg_write(0xFF);
        psg_read(regsInst[reg]);
    }
    
    Serial.println("Test1");
    for (byte reg = 0; reg < 32; ++reg)
    {
        Serial.print("R[");
        print_hex(reg);
        Serial.print("] = ");
        print_hex(regsLow[reg]);
        Serial.println();
    }

    Serial.println("Test2");
    for (byte reg = 0; reg < 32; ++reg)
    {
        Serial.print("R[");
        print_hex(reg);
        Serial.print("] = ");
        print_hex(regsInst[reg]);
        Serial.println();
    }
}

void loop()
{
}
