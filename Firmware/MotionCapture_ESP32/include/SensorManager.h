#pragma once
#include <Arduino.h>

void initSensors();
bool readSensorData(uint8_t id, float &w, float &x, float &y, float &z, float &ax, float &ay, float &az, float &gx, float &gy, float &gz);
bool isWatchdogTriggered(unsigned long currentTime);