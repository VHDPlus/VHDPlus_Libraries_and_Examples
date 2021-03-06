#include "alt_types.h"
#include <unistd.h>

class SCD30
{
private:
    union u32tof {
        alt_u32 u32;
        float f;
    };
    
    alt_u16 data_ready=0;
    alt_u16 asc_state=2;
    alt_u16 activate=1;
    alt_u16 measurement_interval = 2; //allowed range: 2s - 1800s
    alt_u16 ambient_pressure_mbar = 0; // allowed range: 0 & 700mbar - 1400mbar
    union u32tof co2, temp, hum;
    alt_16 status;
    
public:
    void i2c_init(void);

    alt_u8 gencrc8(alt_u8 *data);

    alt_8 i2c_write(alt_u8 target_addr, alt_u16 command, const alt_u16* argument, alt_u8 argument_word_size);

    alt_8 i2c_read(alt_u8 target_addr, alt_u16 command, alt_u16* data, alt_u8 data_word_size);

    alt_8 busy();
    
    void begin();
    
    void end();
    
    void read();
    
    float co2_value();
    
    float temp_value();
    
    float hum_value();

};
