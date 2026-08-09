#pragma once
#include <Arduino.h>

#pragma pack(push, 1)
struct SensorPacket {
    uint8_t header1 = 0xAA;
    uint8_t header2 = 0xBB;
    uint8_t id;
    float w;
    float x;
    float y;
    float z;
    float ax;
    float ay;
    float az;
    float gx;
    float gy;
    float gz;
    uint8_t checksum;
};
#pragma pack(pop)

void initNetwork(bool useWifi);
SensorPacket createSensorPacket(uint8_t id, float w, float x, float y, float z, float ax, float ay, float az, float gx, float gy, float gz);
void sendSensorData(uint8_t id, float w, float x, float y, float z, float ax, float ay, float az, float gx, float gy, float gz, bool useWifi);
void sendSensorPacket(const SensorPacket& packet, bool useWifi);