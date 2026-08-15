#include <Arduino.h>
#include "Config.h"
#include "SensorManager.h"
#include "NetworkManager.h"

bool isWifiMode = false;
QueueHandle_t sensorQueue = NULL;

void taskSensorRead(void *pvParameters) {
  TickType_t lastWakeTime = xTaskGetTickCount();
  const TickType_t samplingPeriod = pdMS_TO_TICKS(10); // 100 Hz mintavételezés

  for (;;) {
    unsigned long currentTime = millis();

    // Szenzorok olvasása és Queue-ba küldése
    for (int i = 0; i < NUM_SENSORS; i++) {
      float w, x, y, z, ax, ay, az, gx, gy, gz;
      if (readSensorData(i, w, x, y, z, ax, ay, az, gx, gy, gz)) {
        SensorPacket packet = createSensorPacket(i, w, x, y, z, ax, ay, az, gx, gy, gz);
        xQueueSend(sensorQueue, &packet, 0);
      }
    }

    // Watchdog ellenőrzés
    if (isWatchdogTriggered(currentTime)) {
      Serial.println("ESP32 Újraindítása...\n");
      vTaskDelay(pdMS_TO_TICKS(200));
      ESP.restart();
    }

    vTaskDelayUntil(&lastWakeTime, samplingPeriod);
  }
}

void taskNetworkSend(void *pvParameters) {
  SensorPacket packet;

  for (;;) {
    // Várakozás Queue elemekre
    if (xQueueReceive(sensorQueue, &packet, portMAX_DELAY) == pdTRUE) {
      sendSensorPacket(packet, isWifiMode);
    }
  }
}

void setup() {
  Serial.begin(921600);
  delay(100);

  // Kapcsolat kiválasztása
  pinMode(SWITCH_PIN, INPUT_PULLUP);
  delay(50);
  isWifiMode = (digitalRead(SWITCH_PIN) == LOW);

  // Inicializálások
  initNetwork(isWifiMode);
  initSensors();

  // Queue létrehozása (max 20 elem)
  sensorQueue = xQueueCreate(20, sizeof(SensorPacket));

  // FreeRTOS Taskok indítása (Core 1: Szenzor olvasás, Core 0: Hálózati küldés)
  xTaskCreatePinnedToCore(
    taskSensorRead,
    "taskSensorRead",
    4096,
    NULL,
    2,
    NULL,
    1
  );

  xTaskCreatePinnedToCore(
    taskNetworkSend,
    "taskNetworkSend",
    4096,
    NULL,
    1,
    NULL,
    0
  );
}

void loop() {
  vTaskDelete(NULL);
}