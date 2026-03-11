#include <Wire.h>
#include <SparkFun_BNO080_Arduino_Library.h>

BNO080 bno0, bno1, bno2;

// I2C Multiplexer vezérlés
void TCA9548A(uint8_t bus){
  Wire.beginTransmission(0x70); 
  Wire.write(1 << bus);
  Wire.endTransmission();
}

void setup() {
  Serial.begin(115200);
  Wire.begin();
  delay(100);

  Serial.println("===============================================");
  Serial.println("   BNO08x DIAGNOSZTIKA ÉS STÁTUSZ ELLENŐRZŐ    ");
  Serial.println("===============================================");
  Serial.println("Skála: 0 (Rossz) -> 3 (Kiváló)");

  // Szenzorok inicializálása
  TCA9548A(0); if(bno0.begin(0x4B)) bno0.enableRotationVector(50);
  TCA9548A(1); if(bno1.begin(0x4B)) bno1.enableRotationVector(50);
  TCA9548A(2); if(bno2.begin(0x4B)) bno2.enableRotationVector(50);
}

void loop() {
  // Változók a státuszok tárolására
  int stat0 = -1, stat1 = -1, stat2 = -1;

  // 0. Szenzor (Felkar) olvasása
  TCA9548A(0);
  if (bno0.dataAvailable()) {
    stat0 = bno0.getQuatAccuracy();
  }

  // 1. Szenzor (Alkar) olvasása
  TCA9548A(1);
  if (bno1.dataAvailable()) {
    stat1 = bno1.getQuatAccuracy();
  }

  // 2. Szenzor (Kézfej) olvasása
  TCA9548A(2);
  if (bno2.dataAvailable()) {
    stat2 = bno2.getQuatAccuracy();
  }

  // Csak akkor írjuk ki az adatokat, ha mindhárom szenzortól kaptunk friss infót
  if (stat0 != -1 && stat1 != -1 && stat2 != -1) {
    Serial.print("Megbízhatóság -> ");
    Serial.print("Felkar (0): "); Serial.print(stat0); Serial.print("/3 | ");
    Serial.print("Alkar (1): ");  Serial.print(stat1); Serial.print("/3 | ");
    Serial.print("Kézfej (2): "); Serial.print(stat2); Serial.println("/3");
    
    // Fél másodperc szünet, hogy olvasható maradjon a terminál (diagnosztikánál a delay megengedett)
    delay(500); 
  }
}

