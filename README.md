# Wearable-IMU-based-Upper-Limb-Motion-Tracking-System
=======
Egyetemi projekt 

Hordható, IMU (Inertial Measurement Unit) szenzorokon alapuló felsővégtagi 3D mozgáskövető és rehabilitációs rendszer. A rendszer egy ESP32 mikrokontrollerből, TCA9548A I2C multiplexerből, 7 db BNO08x IMU szenzorból, valamint egy valós idejű MATLAB 3D grafikus megjelenítő és elemző szoftverből áll.

---

### Modulok és Struktúra:
- **`Config.h`**: Rendszerszintű konstansok definíciója (szenzorok száma, kapcsoló PIN, PC IP cím, UDP port, watchdog időkorlát).
- **`SensorManager` (`SensorManager.h`, `SensorManager.cpp`)**:
  - TCA9548A I2C multiplexer kezelése.
  - BNO08x szenzorok inicializálása.
  - Kvaterniók (`w, x, y, z`) beolvasása az IMU szenzorokról.
  - Watchdog időzítő a kapcsolat megszakadásának érzékelésére.
- **`NetworkManager` (`NetworkManager.h`, `NetworkManager.cpp`)**:
  - Wi-Fi kapcsolat automatikus konfigurációja `WiFiManager` segítségével.
  - A szenzoradatok becsomagolása egy 20 bájtos `SensorPacket` struktúrába és elküldése nyers bájtfolyamként (`udp.write()` vagy `Serial.write()`).
- **`main.cpp`**:
  - Hardveres kapcsoló (`SWITCH_PIN`) állása alapján kijelöli az üzemmódot: Soros port (USB) vagy Wi-Fi (UDP).
  - Folyamatos szenzorolvasás és adatküldés.

---

## Bináris Kommunikációs Protokoll (SensorPacket)

A sávszélesség-takarékosság, a magasabb frekvencia és a gyors MATLAB oldali feldolgozás érdekében a rendszer 20 bájtos nyers bináris csomagokat használ:

| Mező | Típus | Méret | Leírás |
| :--- | :--- | :--- | :--- |
| **header1** | `uint8_t` | 1 bájt | Fix azonosító (`0xAA` / `170`) |
| **header2** | `uint8_t` | 1 bájt | Fix azonosító (`0xBB` / `187`) |
| **id** | `uint8_t` | 1 bájt | Szenzor azonosítója (0 – 6) |
| **w, x, y, z** | `float` | 16 bájt | 4 db IEEE 754 float32 kvaternió érték |
| **checksum** | `uint8_t` | 1 bájt | XOR ellenőrző összeg (az ID és float bájtok alapján) |

---

## MATLAB

A MATLAB fogadja a bináris adatokat, elvégzi az anatómiai és kinematikai számításokat, valamint 3D-ben megjeleníti a felsővégtag mozgását.

### `Main_GUI` (`main.m`):
Fő GUI alkalmazás hibrid működési móddal (Szabad edzés mód és Irányított gyakorló mód), kalibrációs funkcióval (T-póz offset), valós idejű Euler-szög visszajelzéssel és adatrögzítéssel.

### Adatfogadó Osztályok:

- **`dataReceiver`**: Absztrakt osztály
  - `open(obj, params)` - Adatkapcsolat felépítése.
  - `dataMatrix = readData(obj)` - A bejövő puffer olvasása. Kimenet: `[N x 5]` mátrix (`[SzenzorID, qW, qX, qY, qZ]`).
  - `close(obj)` - A hardveres kapcsolat biztonságos lezárása.

- **`udpReceiver`**: Leszármazott osztály (Wi-Fi UDP kapcsolat)
  - Beérkező bináris UDP adatcsomagok olvasása az `udpport` objektumon keresztül.
  - Csomagkeresés a `0xAA 0xBB` szinkronfejléc alapján, XOR checksum ellenőrzés.
  - Közvetlen lebegőpontos konverzió `typecast(..., 'single')` segítségével.

- **`serialReceiver`**: Leszármazott osztály (Soros portú kapcsolat)
  - Kábeles USB kommunikáció kezelése a `serialport` objektumon keresztül.
  - Dinamikus bináris pufferelés (`buffer uint8`), automata visszaszinkronizálás fejléc vagy checksum hiba esetén.

### 3D Anatómiai Modell:

- **`armModel`**: Osztály a jobb és bal kar 3D megjelenítéséhez és kinematikájához
  - Beérkező nyers kvaterniók forgatómátrixokká alakítása.
  - Kalibráció (T-póz referenciapozíció rögzítése).
  - **Hierarchikus Forward Kinematics**: A mozgás láncolatként adódik át (Váll $\rightarrow$ Könyök $\rightarrow$ Csukló).
  - Anatómiai szögkorlátozások (`clampJoint`).
  - Euler-szögek kiszámítása (Csavarás, Emelés, Forgatás) és a 3D dobozmodell (patch objektumok) elforgatása a térben.
>>>>>>> Stashed changes
