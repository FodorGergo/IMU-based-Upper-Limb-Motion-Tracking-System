#include <Wire.h>
#include <SparkFun_BNO080_Arduino_Library.h>

BNO080 bno0, bno1, bno2;

// FSM Állapotváltozó
int calibrationState = 0; 
bool stateInitialized = false; // Segédváltozó, hogy a kiíratások csak egyszer fussanak le

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

  Serial.println("==================================================");
  Serial.println(" SZEKVENCIÁLIS BNO08x KALIBRÁLÓ PROGRAM INDUL...  ");
  Serial.println("==================================================");

  // Szenzorok alapvető inicializálása (még nem kapcsoljuk be a kalibrációt!)
  TCA9548A(0); if(!bno0.begin(0x4B)) Serial.println("Hiba a 0. szenzornál!");
  TCA9548A(1); if(!bno1.begin(0x4B)) Serial.println("Hiba az 1. szenzornál!");
  TCA9548A(2); if(!bno2.begin(0x4B)) Serial.println("Hiba a 2. szenzornál!");
  
  Serial.println("\nInicializálás kész. Kezdődik a kalibráció...\n");
}

void loop() {
  // Bemenet olvasása a Serial Monitorról
  char cmd = ' ';
  if (Serial.available()) {
    cmd = Serial.read();
  }

  // --- VÉGES ÁLLAPOTGÉP (FSM) ---
  switch (calibrationState) {
    
    // -----------------------------------------------------------------
    case 0: // 0. SZENZOR (FELKAR) KALIBRÁLÁSA
      if (!stateInitialized) {
        TCA9548A(0);
        bno0.calibrateAll(); // Bekapcsoljuk a kalibrációt CSAK ezen a szenzoron
        Serial.println("\n>>> [1/3] 0. SZENZOR (FELKAR) KALIBRÁLÁSA AKTÍV <<<");
        Serial.println("1. Mozgasd nyolcas alakban a levegőben, majd forgasd meg minden tengelyen!");
        Serial.println("2. Tedd le az asztalra 3 másodpercre mozdulatlanul!");
        Serial.println("3. Ha kész, küldj egy 's' betűt a MENTÉSHEZ és a TOVÁBBLÉPÉSHEZ!");
        stateInitialized = true;
      }
      
      if (cmd == 's' || cmd == 'S') {
        TCA9548A(0);
        bno0.saveCalibration(); // Mentés az EEPROM-ba
        bno0.endCalibration();  // Kalibrációs mód kikapcsolása
        Serial.println("[MENTVE] 0. Szenzor kalibrációja sikeresen beégetve a Flash memóriába.");
        
        calibrationState = 1;     // Átlépés a következő állapotba
        stateInitialized = false; // Reset a következő állapothoz
      }
      break;

    // -----------------------------------------------------------------
    case 1: // 1. SZENZOR (ALKAR) KALIBRÁLÁSA
      if (!stateInitialized) {
        TCA9548A(1);
        bno1.calibrateAll();
        Serial.println("\n>>> [2/3] 1. SZENZOR (ALKAR) KALIBRÁLÁSA AKTÍV <<<");
        Serial.println("Végezd el ugyanazokat a mozdulatokat ezzel a szenzorral is!");
        Serial.println("Ha kész, küldj egy 's' betűt a MENTÉSHEZ és a TOVÁBBLÉPÉSHEZ!");
        stateInitialized = true;
      }
      
      if (cmd == 's' || cmd == 'S') {
        TCA9548A(1);
        bno1.saveCalibration();
        bno1.endCalibration();
        Serial.println("[MENTVE] 1. Szenzor kalibrációja sikeresen beégetve.");
        
        calibrationState = 2;
        stateInitialized = false;
      }
      break;

    // -----------------------------------------------------------------
    case 2: // 2. SZENZOR (KÉZFEJ) KALIBRÁLÁSA
      if (!stateInitialized) {
        TCA9548A(2);
        bno2.calibrateAll();
        Serial.println("\n>>> [3/3] 2. SZENZOR (KÉZFEJ) KALIBRÁLÁSA AKTÍV <<<");
        Serial.println("Végezd el a mozdulatokat az utolsó szenzorral is!");
        Serial.println("Ha kész, küldj egy 's' betűt a MENTÉSHEZ és a BEFEJEZÉSHEZ!");
        stateInitialized = true;
      }
      
      if (cmd == 's' || cmd == 'S') {
        TCA9548A(2);
        bno2.saveCalibration();
        bno2.endCalibration();
        Serial.println("[MENTVE] 2. Szenzor kalibrációja sikeresen beégetve.");
        
        calibrationState = 3;
        stateInitialized = false;
      }
      break;

    // -----------------------------------------------------------------
    case 3: // BEFEJEZÉS
      if (!stateInitialized) {
        Serial.println("\n==================================================");
        Serial.println(" MIND A 3 SZENZOR SIKERESEN BEKALIBRÁLVA ÉS MENTVE! ");
        Serial.println(" Töltheted fel a fő mérőprogramot az ESP32-re.");
        Serial.println("==================================================");
        stateInitialized = true;
      }
      // Itt a program "megpihen", nem csinál semmit.
      break;
  }

  // Egy minimális késleltetés a mikrokontroller stabilitása érdekében a ciklusban
  delay(10); 
}