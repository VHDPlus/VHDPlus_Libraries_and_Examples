
#include <Arduino.h>

#include "alt_types.h"
#include "altera_avalon_i2c.h"
#include "TSL25403.h"
#include <system.h>

// I2C address
#define TSL25403_I2C_ADDRESS  0x39
// command adress
#define ENABLE 0x80
#define ALS_INTEGRATION_TIME 0x81
#define WAIT_TIME 0x83
#define ALS_INT_LOW_LOW 0x84
#define ALS_INT_LOW_HIGH 0x85
#define ALS_INT_HIGH_LOW 0x86
#define ALS_INT_HIGH_HIGH 0x87
#define ALS_INT_PERSISTANCE 0x8C
#define CFG0 0x8D
#define CFG1 0x90
#define CFG2 0x9F
#define CFG3 0xAB
#define AZ_CONFIG 0xD6
#define INT_ENABLE 0xDD
#define ID 0x92
#define STATUS 0x93
#define VISIBLE_DATA_LOW 0x94
#define VISIBLE_DATA_HIGH 0x95
#define IR_DATA_LOW 0x96
#define IR_DATA_HIGH 0x97

alt_u8 TSL25403::gencrc8(alt_u8 *data) {
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

void TSL25403::i2c_init(void) {
    ALT_AVALON_I2C_MASTER_CONFIG_t cfg;
    i2c_dev = alt_avalon_i2c_open(I2C_0_NAME);
    alt_avalon_i2c_init(i2c_dev);
    if(i2c_dev) alt_avalon_i2c_master_config_speed_set(i2c_dev, &cfg, 100000);
}

alt_8 TSL25403::i2c_write(alt_u8 target_addr, alt_u8 command, const alt_u8* argument, alt_u8 argument_word_size) {
    alt_u8 i,j=0,buffer[32];

    buffer[j++] = command;

    for (i=0; i < argument_word_size; i++) {
        buffer[j++] = argument[i];
    }
    alt_avalon_i2c_master_target_set(i2c_dev, target_addr);
    alt_8 status = alt_avalon_i2c_master_tx(i2c_dev, buffer, j, ALT_AVALON_I2C_NO_INTERRUPTS);

    return status;
}

alt_8 TSL25403::i2c_read(alt_u8 target_addr, alt_u8 command, alt_u8* data, alt_u8 data_word_size) {
    alt_u8 i,j=0,buffer[32],size = data_word_size;

    i2c_write(target_addr, command, NULL, 0);
    delayMicroseconds(5000);

    alt_u8 status = alt_avalon_i2c_master_rx(i2c_dev, buffer, size, ALT_AVALON_I2C_NO_INTERRUPTS);
    if (status != 0) return status;

    for (i=0; i < size; i ++) {
        data[j++] = buffer[i];
    }

    return status;
}

alt_8 TSL25403::busy()
{
    alt_8 r = i2c_read(TSL25403_I2C_ADDRESS, STATUS, &status, 1);
    return r;
}

void TSL25403::begin()
{
    i2c_init();
    
    while (busy() != 0) {
        #ifdef DEBUG
        printf("TSL25403 sensor probing failed\n\r");
        #endif
        delayMicroseconds(1000000);
    }
    //Start
    i2c_write(TSL25403_I2C_ADDRESS, ENABLE, &enable, 1);
    
    //Gain
    cfg = (0x06 & gain)>>1;
    i2c_write(TSL25403_I2C_ADDRESS, CFG1, &cfg, 1);
    cfg = ((0x01 & gain)<<1) | ((0x08 & gain)<<1);
    i2c_write(TSL25403_I2C_ADDRESS, CFG2, &cfg, 1);
}

void TSL25403::end()
{
    cfg = 0x00;
    // stop periodic measurement
    i2c_write(TSL25403_I2C_ADDRESS, ENABLE, &cfg, 1);
}

float TSL25403::read_lux()
{
    i2c_read(TSL25403_I2C_ADDRESS, VISIBLE_DATA_LOW, &rx_reg, 1);
    lux = rx_reg;
    i2c_read(TSL25403_I2C_ADDRESS, VISIBLE_DATA_HIGH, &rx_reg, 1);
    lux += 256*rx_reg;
    lux /= divider;
    return lux;
}

float TSL25403::read_ir_lux()
{
    i2c_read(TSL25403_I2C_ADDRESS, IR_DATA_LOW, &rx_reg, 1);
    ir_lux = rx_reg;
    i2c_read(TSL25403_I2C_ADDRESS, IR_DATA_HIGH, &rx_reg, 1);
    ir_lux += 256*rx_reg;
    ir_lux /= divider;
    return ir_lux;
}


