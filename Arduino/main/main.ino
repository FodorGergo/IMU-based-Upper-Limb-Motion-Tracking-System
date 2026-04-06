#include <Wire.h>
#include <SparkFun_BNO080_Arduino_Library.h>

BNO080 bno0;
BNO080 bno1;
BNO080 bno2;
BNO080 bno4;

// --- ÚJ: Watchdog (Időtúllépés) Változók ---
unsigned long utolsoAdat0 = 0;
unsigned long utolsoAdat1 = 0;
unsigned long utolsoAdat2 = 0;
unsigned long utolsoAdat4 = 0;
const unsigned long TIMEOUT_MS = 2000; // 2 másodperc (Ha 2 mp-ig nincs adat, reset)

void TCA9548A(uint8_t bus){
  Wire.beginTransmission(0x70);  // TCA9548A cím
  Wire.write(1 << bus);          // bit tologatás a busz kiválasztásához
  Wire.endTransmission();
}

void setup() {
  Serial.begin(115200);
  delay(50); //100

  // I2C kommunikáció megkezdése a Multiplexerrel
  Wire.begin();

  // BNO08x inicializálása a(z) (0) buszon
  TCA9548A(0); 
  delay(50);
  if (!bno0.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (0) buszon.");
  } else {
    Serial.println("Találat! BNO08x szenzor a(z) (0) buszon");
    bno0.enableRotationVector(33); 
  }
 
  // BNO08x inicializálása a(z) (1) buszon
  TCA9548A(1); 
  delay(50);
  if (!bno1.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (1) buszon.");
  } else {
    Serial.println("Találat! BNO08x szenzor a(z) (1) buszon");
    bno1.enableRotationVector(33); 
  }
  
  // BNO08x inicializálása a(z) (2) buszon
  TCA9548A(2); 
  delay(50);
  if (!bno2.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (2) buszon.");
  } else {
    Serial.println("Találat! BNO08x szenzor a(z) (2) buszon");
    bno2.enableRotationVector(33); 
  }

  TCA9548A(4); 
  delay(50);
  if (!bno4.begin(0x4B)) {
    Serial.println("Nem található BNO08x szenzor a(z) (4) buszon.");
  } else {
    Serial.println("Találat! BNO08x szenzor a(z) (4) buszon");
    bno4.enableRotationVector(33); 
  }

  // --- ÚJ: Időbélyegek indítása a setup végén ---
  // Hogy ne induljon újra rögtön a legelső loop ciklusban
  unsigned long startIdo = millis();
  utolsoAdat0 = startIdo;
  utolsoAdat1 = startIdo;
  utolsoAdat2 = startIdo;
  utolsoAdat4 = startIdo;
}

void loop() {
  unsigned long jelenlegiIdo = millis(); // Lekérdezzük, mennyi az idő most

  // 1. szenzor értékei
  TCA9548A(0);
  if (bno0.dataAvailable()) {
    utolsoAdat0 = jelenlegiIdo; // Frissítjük a 0. szenzor életjelét

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
    utolsoAdat1 = jelenlegiIdo; // Frissítjük az 1. szenzor életjelét

    float w1 = bno1.getQuatReal();
    float x1 = bno1.getQuatI();
    float y1 = bno1.getQuatJ();
    float z1 = bno1.getQuatK();

    Serial.print("1: ");
    Serial.print(w1,6); Serial.print(" ");
    Serial.print(x1,6); Serial.print(" ");
    Serial.print(y1,6); Serial.print(" ");
    Serial.println(z1,6);
  }

  // 3. szenzor értékei
  TCA9548A(2);
  if (bno2.dataAvailable()) {
    utolsoAdat2 = jelenlegiIdo; // Frissítjük a 2. szenzor életjelét

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

  // 3. szenzor értékei
  TCA9548A(4);
  if (bno4.dataAvailable()) {
    utolsoAdat4 = jelenlegiIdo; // Frissítjük a 2. szenzor életjelét

    float w4 = bno4.getQuatReal();
    float x4 = bno4.getQuatI();
    float y4 = bno4.getQuatJ();
    float z4 = bno4.getQuatK();

    Serial.print("4: ");
    Serial.print(w4,6); Serial.print(" ");
    Serial.print(x4,6); Serial.print(" ");
    Serial.print(y4,6); Serial.print(" ");
    Serial.println(z4,6);
  }

  // WATCHDOG
  // Melyik szenzornál eltelt-e több mint 2 másodperc a legutóbbi adat óta
  if ((jelenlegiIdo - utolsoAdat0 > TIMEOUT_MS) || 
      (jelenlegiIdo - utolsoAdat1 > TIMEOUT_MS) || 
      (jelenlegiIdo - utolsoAdat2 > TIMEOUT_MS) ||
      (jelenlegiIdo - utolsoAdat4 > TIMEOUT_MS)){
      
      Serial.println("\n Kapcsolat megszakadt az egyik szenzornal!");
      Serial.println("ESP32 ujrainditasa\n");
      
      delay(500); 
      ESP.restart(); 
  }
}