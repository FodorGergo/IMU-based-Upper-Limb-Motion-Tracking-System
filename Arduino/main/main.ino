#include <Wire.h>
#include <SparkFun_BNO080_Arduino_Library.h>

BNO080 bno0;
BNO080 bno1;
BNO080 bno2;

void TCA9548A(uint8_t bus){
  Wire.beginTransmission(0x70);  // TCA9548A cím
  Wire.write(1 << bus);          // bit tologatás a busz kiválasztásához
  Wire.endTransmission();

}

void setup() {
  Serial.begin(115200);
  delay(50); //100

  //I2C kommunikáció megkezdése a Multiplexerrel
  Wire.begin();

  //BNO08x inicializálása a(z) (0) buszon
  TCA9548A(0); //I2C busz kiválasztása
  delay(50);
  if (!bno0.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (0) buszon.");
  }else{
  Serial.println("Találat! BNO08x szenzor a(z) (0) buszon");
  bno0.enableRotationVector(17); 
  }
 
  //BNO08x inicializálása a(z) (1) buszon
  TCA9548A(1); //I2C busz kiválasztása
  delay(50);
  if (!bno1.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (1) buszon.");
  }else{
    Serial.println("Találat! BNO08x szenzor a(z) (1) buszon");
    bno1.enableRotationVector(17); 
  }
  
  //BNO08x inicializálása a(z) (2) buszon
  TCA9548A(2); //I2C busz kiválasztása
  delay(50);
  if (!bno2.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (2) buszon.");
  }else{
    Serial.println("Találat! BNO08x szenzor a(z) (2) buszon");
    bno2.enableRotationVector(17); 
  }

}

void loop() {

  // 1. szenzor értékei
  TCA9548A(0);
  if (bno0.dataAvailable()) {

    float w0 = bno0.getQuatReal();
    float x0 = bno0.getQuatI();
    float y0 = bno0.getQuatJ();
    float z0 = bno0.getQuatK();

    Serial.print("0: ");
    Serial.print(w0,6); Serial.print(" ");
    Serial.print(x0,6); Serial.print(" ");
    Serial.print(y0,6); Serial.print(" ");
    Serial.println(z0,6);
  }
  // 2. szenzor értékei
  TCA9548A(1);
  if (bno1.dataAvailable()) {

    float w1 = bno1.getQuatReal();
    float x1 = bno1.getQuatI();
    float y1 = bno1.getQuatJ();
    float z1 = bno1.getQuatK();

    Serial.print("1: ");
    Serial.print(w1,6); Serial.print(" ");
    Serial.print(x1,6); Serial.print(" ");
    Serial.print(y1,6); Serial.print(" ");
    Serial.println(z1,6); ;
  }
  // 3. szenzor értékei
  TCA9548A(2);
  if (bno2.dataAvailable()) {

    float w2 = bno2.getQuatReal();
    float x2 = bno2.getQuatI();
    float y2 = bno2.getQuatJ();
    float z2 = bno2.getQuatK();

    Serial.print("2: ");
    Serial.print(w2,6); Serial.print(" ");
    Serial.print(x2,6); Serial.print(" ");
    Serial.print(y2,6); Serial.print(" ");
    Serial.println(z2,6);
  }
}
