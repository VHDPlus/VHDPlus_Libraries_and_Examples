#include "alt_types.h"
#include "altera_avalon_i2c.h"
#include <unistd.h>

class TSL25403
{
private:
    alt_u8 cfg;
    alt_u8 rx_reg;
    alt_u8 enable = 0x0B;
    alt_u8 gain = 0x05; //Gain: 0x00 = *1/2, 0x01 = *1, 3 = *4, 5 = *16, 7 = *64, F = *128
    alt_u8 status;
    float divider    = 1.0; //Divider -> could convert to lux
    float divider_ir = 1.0; //Divider -> could convert to lux
    float lux, ir_lux;
    ALT_AVALON_I2C_DEV_t *i2c_dev = NULL;
    
public:
    void i2c_init(void);

    alt_u8 gencrc8(alt_u8 *data);

    alt_8 i2c_write(alt_u8 target_addr, alt_u8 command, const alt_u8* argument, alt_u8 argument_word_size);

    alt_8 i2c_read(alt_u8 target_addr, alt_u8 command, alt_u8* data, alt_u8 data_word_size);

    alt_8 busy();
    
    void begin();
    
    void end();
    
    void calibrate(float lux);
    
    void calibrate_ir(float lux);
    
    float read_lux();
    
    float read_ir_lux();

};
