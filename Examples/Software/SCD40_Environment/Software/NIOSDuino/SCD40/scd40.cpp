
#include <Arduino.h>

#include "alt_types.h"
#include "altera_avalon_i2c.h"
#include "scd40.h"
#include <system.h>

// I2C address
#define SCD40_I2C_ADDRESS  0x62
// command adress
#define REINIT 0x3646
#define START_PERIODIC_MEASUREMENT 0x21b1
#define STOP_PERIODIC_MEASUREMENT 0x3f86
#define READ_MEASUREMENT 0xec05
#define SET_MEASUREMENT_INTERVAL 0x4600
#define GET_DATA_READY 0xe4b8
#define AUTO_SELF_CALIBRATION_SET 0x2416
#define AUTO_SELF_CALIBRATION_GET 0x2313

ALT_AVALON_I2C_DEV_t *i2c_dev = NULL;

alt_u8 SCD40::gencrc8(alt_u8 *data) {
    alt_u8 crc = 0xff;
    alt_8 i, j;
    for (i = 0; i < 2; i++) {
        crc ^= data[i];
        for (j = 0; j < 8; j++) {
            if ((crc & 0x80) != 0) crc = (alt_u8)((crc << 1) ^ 0x31);
            else crc <<= 1;
        }
    }
    return crc;
}

void SCD40::i2c_init(void) {
    ALT_AVALON_I2C_MASTER_CONFIG_t cfg;
    i2c_dev = alt_avalon_i2c_open(I2C_0_NAME);
    alt_avalon_i2c_init(i2c_dev);
    if(i2c_dev) alt_avalon_i2c_master_config_speed_set(i2c_dev, &cfg, 100000);
}

alt_8 SCD40::i2c_write(alt_u8 target_addr, alt_u16 command, const alt_u16* argument, alt_u8 argument_word_size) {
    alt_u8 i,j=0,buffer[32];

    buffer[j++] = (command & 0xFF00) >> 8;
    buffer[j++] = (command & 0x00FF) >> 0;

    for (i=0; i < argument_word_size; i++) {
        buffer[j++] = (argument[i] & 0xFF00) >> 8;
        buffer[j++] = (argument[i] & 0x00FF) >> 0;
        buffer[j++] = gencrc8(&buffer[i+2]);
    }
    for (i=0; i < j; i++)
    {
        printf("%02X", buffer[i]);
    }
    printf("%02X", gencrc8(&buffer[2]));
    printf("\n");
    alt_avalon_i2c_master_target_set(i2c_dev, target_addr);
    alt_8 status = alt_avalon_i2c_master_tx(i2c_dev, buffer, j, ALT_AVALON_I2C_NO_INTERRUPTS);

    return status;
}

alt_8 SCD40::i2c_read(alt_u8 target_addr, alt_u16 command, alt_u16* data, alt_u8 data_word_size) {
    alt_u8 i,j=0,buffer[32],size = data_word_size * 3;

    i2c_write(target_addr, command, NULL, 0);
    delayMicroseconds(5000);

    alt_u8 status = alt_avalon_i2c_master_rx(i2c_dev, buffer, size, ALT_AVALON_I2C_NO_INTERRUPTS);
    if (status != 0) return status;

    for (i=0; i < size; i += 3) {
        if (gencrc8(&buffer[i]) != buffer[i+2]) return -8;
        data[j++] = (alt_u16)buffer[i]<<8 | (alt_u16)buffer[i+1];
    }

    return status;
}

alt_8 SCD40::busy()
{
    alt_8 r = i2c_read(SCD40_I2C_ADDRESS, GET_DATA_READY, &data_ready, sizeof(data_ready)/2);
    data_ready = data_ready & 0x7FF;
    return r;
}

void SCD40::begin()
{
    i2c_init();
    
    while (busy() != 0) {
        #ifdef DEBUG
        printf("SCD40 sensor probing failed\n\r");
        #endif
        delayMicroseconds(1000000);
    }
    //Stop Measurement
    //i2c_write(SCD40_I2C_ADDRESS, STOP_PERIODIC_MEASUREMENT, NULL, 0);
    
    //Reinit
    i2c_write(SCD40_I2C_ADDRESS, REINIT, NULL, 0);
    
    // start periodic measurement
    i2c_write(SCD40_I2C_ADDRESS, START_PERIODIC_MEASUREMENT, NULL, 0);
}

void SCD40::end()
{
    // stop periodic measurement
    i2c_write(SCD40_I2C_ADDRESS, STOP_PERIODIC_MEASUREMENT, NULL, 0);
}

void SCD40::read()
{
    alt_u16 timeout = 0;

    // Poll data_ready flag
    data_ready = 0;
    for (timeout = 0; (100000 * timeout) < (measurement_interval * 1200000); ++timeout) {
        status = busy();
        if (status != 0) {
            #ifdef DEBUG
            printf("Error reading data_ready flag: %i\n\r", status);
            #endif
        }
        if (data_ready) break;
        delay(100);
    }
    if (!data_ready) {
        #ifdef DEBUG
        printf("Timeout waiting for data_ready flag\n");
        #endif
    }
    else
    {
        // Measure co2, temperature and humidity
        alt_u16 data[3];
        status = i2c_read(SCD40_I2C_ADDRESS, READ_MEASUREMENT, &data[0], sizeof(data)/2);
        printf("Data: ");
        for (int i=0; i < 3; i ++) {
            printf("%d, ",data[i]);
        }
        printf("\n");

        co2  = (float)data[0]; // co2
        // The measured temperature and humidity are influenced by the waste heat of the FPGA.
        temp = -45. + 175*(float)data[1]/65536.; // temperature
        hum  = 100.*(float)data[2]/65536.; // humidity
    }
}

float SCD40::co2_value()
{
    return co2;
}

float SCD40::temp_value()
{
    return temp;
}

float SCD40::hum_value()
{
    return hum;
}


