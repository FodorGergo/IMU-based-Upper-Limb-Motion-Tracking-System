#include "NetworkManager.h"
#include "Config.h"
#include <WiFi.h>
#include <WiFiUdp.h>
#include <WiFiManager.h>

WiFiUDP udp;

void initNetwork(bool useWifi) {
  if (useWifi) {
    Serial.println("\n[Wi-Fi kiválasztva]");
    WiFiManager wifiManager;
    
    if (!wifiManager.startConfigPortal("MotionCapture")) {
      Serial.println("Hiba: Nem sikerült csatlakozni a Wi-Fi-re.");
      delay(1000);
      ESP.restart(); 
    }
    
    Serial.println("Wi-Fi Csatlakoztatva!");
    Serial.print("ESP32 IP címe: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[Soros Port kiválasztva]");
  }
}

static uint8_t calculateChecksum(const SensorPacket& pkt) {
    const uint8_t* ptr = (const uint8_t*)&pkt;
    uint8_t checksum = 0;
    for (size_t i = 2; i < sizeof(SensorPacket) - 1; i++) {
        checksum ^= ptr[i];
    }
    return checksum;
}

void sendSensorPacket(const SensorPacket& packet, bool useWifi) {
    if (useWifi) {
        udp.beginPacket(PC_IP, UDP_PORT);
        udp.write((const uint8_t*)&packet, sizeof(SensorPacket));
        udp.endPacket();
    } else {
        Serial.write((const uint8_t*)&packet, sizeof(SensorPacket));
    }
}

SensorPacket createSensorPacket(uint8_t id, float w, float x, float y, float z, float ax, float ay, float az, float gx, float gy, float gz) {
    SensorPacket packet;
    packet.header1 = 0xAA;
    packet.header2 = 0xBB;
    packet.id = id;
    packet.w = w;
    packet.x = x;
    packet.y = y;
    packet.z = z;
    packet.ax = ax;
    packet.ay = ay;
    packet.az = az;
    packet.gx = gx;
    packet.gy = gy;
    packet.gz = gz;
    packet.checksum = calculateChecksum(packet);
    return packet;
}

void sendSensorData(uint8_t id, float w, float x, float y, float z, float ax, float ay, float az, float gx, float gy, float gz, bool useWifi) {
    SensorPacket packet = createSensorPacket(id, w, x, y, z, ax, ay, az, gx, gy, gz);
    sendSensorPacket(packet, useWifi);
}