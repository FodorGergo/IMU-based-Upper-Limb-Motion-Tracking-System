#include "SensorManager.h"
#include "Config.h"
#include <Wire.h>
#include <SparkFun_BNO080_Arduino_Library.h>

BNO080 bno[NUM_SENSORS];
bool sensorActive[NUM_SENSORS] = {false};
unsigned long lastData[NUM_SENSORS] = {0};

void TCA9548A(uint8_t bus) {
  Wire.beginTransmission(0x70); 
  Wire.write(1 << bus);         
  Wire.endTransmission();
}

static bool checkI2CAddress(uint8_t addr) {
  Wire.beginTransmission(addr);
  return (Wire.endTransmission() == 0);
}

void initSensors() {
  Wire.begin();
  Wire.setClock(400000); // 400 kHz Fast-Mode I2C busz a 7 szenzorhoz
  Wire.setTimeOut(50);
  delay(50);

  Serial.println("\n--- BNO08x szenzorok inicializálása ---");
  for (int i = 0; i < NUM_SENSORS; i++) {
    TCA9548A(i);
    delay(10);

    bool detected = false;
    uint8_t foundAddr = 0;

    if (checkI2CAddress(0x4A)) {
      foundAddr = 0x4A;
    } else if (checkI2CAddress(0x4B)) {
      foundAddr = 0x4B;
    }

    if (foundAddr != 0) {
      if (bno[i].begin(foundAddr)) {
        Serial.printf("Találat! BNO08x szenzor a(z) %d. csatornán (Cím: 0x%02X)\n", i, foundAddr);
        bno[i].enableRotationVector(33);
        bno[i].enableLinearAccelerometer(33);
        bno[i].enableGyro(33);
        detected = true;
      } else {
        Serial.printf("Hiba: I2C eszköz található a 0x%02X címen, de az inicializálás meghiúsult a(z) %d. csatornán.\n", foundAddr, i);
      }
    }

    sensorActive[i] = detected;

    if (!detected && foundAddr == 0) {
      Serial.printf("Nem található BNO08x szenzor a(z) %d. csatornán.\n", i);
    }
  }
  Serial.println("------------------------------------------------\n");

  unsigned long startTime = millis();
  for (int i = 0; i < NUM_SENSORS; i++) {
    lastData[i] = startTime;
  }
}

uint8_t retryCount[NUM_SENSORS] = {0};

// Az értékeket referencia szerint (&) adja vissza a főprogramnak
bool readSensorData(uint8_t id, float &w, float &x, float &y, float &z, float &ax, float &ay, float &az, float &gx, float &gy, float &gz) {
  if (!sensorActive[id]) return false;
  TCA9548A(id);

  if (bno[id].hasReset()) {
    bno[id].enableRotationVector(33);
    bno[id].enableLinearAccelerometer(33);
    bno[id].enableGyro(33);
    lastData[id] = millis();
  }

  if (bno[id].dataAvailable()) {
    lastData[id] = millis();
    retryCount[id] = 0;
    w = bno[id].getQuatReal();
    x = bno[id].getQuatI();
    y = bno[id].getQuatJ();
    z = bno[id].getQuatK();
    ax = bno[id].getLinAccelX();
    ay = bno[id].getLinAccelY();
    az = bno[id].getLinAccelZ();
    gx = bno[id].getGyroX();
    gy = bno[id].getGyroY();
    gz = bno[id].getGyroZ();
    return true;
  }
  return false;
}

bool isWatchdogTriggered(unsigned long currentTime) {
  for (int i = 0; i < NUM_SENSORS; i++) {
    if (sensorActive[i] && (currentTime - lastData[i] > TIMEOUT_MS)) {
      if (retryCount[i] < 3) {
        retryCount[i]++;
        TCA9548A(i);
        bno[i].enableRotationVector(33);
        bno[i].enableLinearAccelerometer(33);
        bno[i].enableGyro(33);
        lastData[i] = currentTime;
      } else {
        Serial.printf("Kapcsolat megszakadt a(z) %d. szenzornál!\n", i);
        return true;
      }
    }
  }
  return false;
}