
#include <Arduino.h>

#include "alt_types.h"
#include "altera_avalon_i2c.h"
#include "scd30.h"
#include <system.h>

// I2C address
#define SCD30_I2C_ADDRESS  0x61
// command adress
#define START_PERIODIC_MEASUREMENT 0x0010
#define STOP_PERIODIC_MEASUREMENT 0x0104
#define READ_MEASUREMENT 0x0300
#define SET_MEASUREMENT_INTERVAL 0x4600
#define GET_DATA_READY 0x0202
#define AUTO_SELF_CALIBRATION 0x5306

#define FLOAT_TO_INT(x) ((x)>=0?(int)((x)+0.5)::(int)((x)-0.5))

ALT_AVALON_I2C_DEV_t *i2c_dev = NULL;

alt_u8 SCD30::gencrc8(alt_u8 *data) {
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

void SCD30::i2c_init(void) {
    ALT_AVALON_I2C_MASTER_CONFIG_t cfg;
    i2c_dev = alt_avalon_i2c_open(I2C_0_NAME);
    alt_avalon_i2c_init(i2c_dev);
    if(i2c_dev) alt_avalon_i2c_master_config_speed_set(i2c_dev, &cfg, 100000);
}

alt_8 SCD30::i2c_write(alt_u8 target_addr, alt_u16 command, const alt_u16* argument, alt_u8 argument_word_size) {
    alt_u8 i,j=0,buffer[32];

    buffer[j++] = (command & 0xFF00) >> 8;
    buffer[j++] = (command & 0x00FF) >> 0;

    for (i=0; i < argument_word_size; i++) {
        buffer[j++] = (argument[i] & 0xFF00) >> 8;
        buffer[j++] = (argument[i] & 0x00FF) >> 0;
        buffer[j++] = gencrc8(&buffer[i+2]);
    }
    alt_avalon_i2c_master_target_set(i2c_dev, target_addr);
    alt_8 status = alt_avalon_i2c_master_tx(i2c_dev, buffer, j, ALT_AVALON_I2C_NO_INTERRUPTS);

    return status;
}

alt_8 SCD30::i2c_read(alt_u8 target_addr, alt_u16 command, alt_u16* data, alt_u8 data_word_size) {
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

alt_8 SCD30::busy()
{
    alt_8 r = i2c_read(SCD30_I2C_ADDRESS, GET_DATA_READY, &data_ready, sizeof(data_ready)/2);
    return r;
}

void SCD30::begin()
{
    i2c_init();
    
    while (busy() != 0) {
        #ifdef DEBUG
        printf("SCD30 sensor probing failed\n\r");
        #endif
        delayMicroseconds(1000000);
    }
    // activate Automatic Self-Calibration
    i2c_read(SCD30_I2C_ADDRESS, AUTO_SELF_CALIBRATION, &asc_state, sizeof(asc_state)/2);
    if (asc_state == 0) i2c_write(SCD30_I2C_ADDRESS, AUTO_SELF_CALIBRATION, &activate, sizeof(activate)/2);

    // set measurement interval
    i2c_write(SCD30_I2C_ADDRESS, SET_MEASUREMENT_INTERVAL, &measurement_interval,(sizeof(measurement_interval))/2);
    delayMicroseconds(20000);

    // start periodic measurement
    i2c_write(SCD30_I2C_ADDRESS, START_PERIODIC_MEASUREMENT, &ambient_pressure_mbar,(sizeof(ambient_pressure_mbar))/2);
}

void SCD30::end()
{
    // stop periodic measurement
    i2c_write(SCD30_I2C_ADDRESS, STOP_PERIODIC_MEASUREMENT, NULL, 0);
}

void SCD30::read()
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
        delayMicroseconds(100000);
    }
    if (!data_ready) {
        #ifdef DEBUG
        printf("Timeout waiting for data_ready flag\n");
        #endif
    }
    else
    {
        // Measure co2, temperature and humidity
        alt_u16 data[3][2];
        status = i2c_read(SCD30_I2C_ADDRESS, READ_MEASUREMENT, &data[0][0], sizeof(data)/2);
        co2.u32  = (((alt_u32)data[0][0]) << 16) | (alt_u32)data[0][1]; // co2
        // The measured temperature and humidity are influenced by the waste heat of the FPGA.
        temp.u32 = (((alt_u32)data[1][0]) << 16) | (alt_u32)data[1][1]; // temperature
        hum.u32  = (((alt_u32)data[2][0]) << 16) | (alt_u32)data[2][1]; // humidity
    }
}

float SCD30::co2_value()
{
    return co2.f;
}

float SCD30::temp_value()
{
    return temp.f;
}

float SCD30::hum_value()
{
    return hum.f;
}


