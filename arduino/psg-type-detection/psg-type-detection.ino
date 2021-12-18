
#define NUM 16
#define PAT 0xFF

byte regsLow[NUM];
byte regsInst[NUM];

void print_hex(byte data)
{
    Serial.print(data > 0x0F ? "0x" : "0x0");
    Serial.print(data, HEX);
}

void setup()
{
    PSG_Init();
    Serial.begin(9600);

    for (byte reg = 0; reg < NUM; ++reg)
    {
        PSG_Send(reg, PAT);
    }

    for (byte reg = 0; reg < NUM; ++reg)
    {
        regsLow[reg] = PSG_Receive(reg);
    }

    for (byte reg = 0; reg < NUM; ++reg)
    {
        PSG_Address(reg);
        PSG_Write(PAT);
        PSG_Read(regsInst[reg]);
    }
    
    Serial.println("Test1");
    for (byte reg = 0; reg < NUM; ++reg)
    {
        Serial.print("R[");
        print_hex(reg);
        Serial.print("] = ");
        print_hex(regsLow[reg]);
        Serial.println();
    }

    Serial.println("Test2");
    for (byte reg = 0; reg < NUM; ++reg)
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
