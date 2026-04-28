#include <WiFi.h>
#include <WiFiUdp.h>
#include <math.h>

// =====================================================
// KONFIGURASI WIFI DAN UDP
// =====================================================
const char* ssid = "KOS BU SIHA 4G";
const char* password = "kosbusiha4g";

// Ganti dengan IP Raspberry Pi / VM kamu
const char* targetIP = "192.168.100.196";
const int targetPort = 1234;

WiFiUDP udp;

// =====================================================
// PILIH SKENARIO
// A = Cloud / Server-Side Filtering
//     ESP32 kirim raw data, Raspberry Pi melakukan filter
//
// B = Edge / Client-Side Filtering
//     ESP32 melakukan filter, lalu kirim filtered data
// =====================================================
#define MODE_SCENARIO 'B'

// =====================================================
// KONFIGURASI EKSPERIMEN
// =====================================================
const int SAMPLE_RATE_HZ = 20;
const int SAMPLE_INTERVAL_MS = 1000 / SAMPLE_RATE_HZ;

// Durasi eksperimen per skenario
const int EXPERIMENT_DURATION_SEC = 30;
const int TOTAL_SAMPLES = SAMPLE_RATE_HZ * EXPERIMENT_DURATION_SEC;

// =====================================================
// KONFIGURASI PARTICLE FILTER
// =====================================================
const int N_PARTICLES = 1000;

float particles[N_PARTICLES];
float weights[N_PARTICLES];
float newParticles[N_PARTICLES];

const float PROCESS_NOISE_STD = 0.15;
const float MEASUREMENT_NOISE_STD = 0.80;

// =====================================================
// VARIABEL GLOBAL
// =====================================================
unsigned long lastSampleTime = 0;
unsigned long experimentStartMs = 0;
int seq = 0;
bool experimentDone = false;

// =====================================================
// RANDOM HELPER
// =====================================================
float randomUniform() {
  return (float) random(1, 1000000) / 1000000.0;
}

float randomGaussian(float mean, float stddev) {
  float u1 = randomUniform();
  float u2 = randomUniform();

  float z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2);
  return mean + z0 * stddev;
}

// =====================================================
// FAKE IMU GENERATOR
// Simulasi akselerasi sumbu X.
// Dibuat seperti sinyal gerakan + noise.
// =====================================================
float generateFakeIMU(int sampleIndex) {
  float t = sampleIndex / (float) SAMPLE_RATE_HZ;

  // Sinyal utama seperti gerakan periodik
  float movement = 2.0 * sin(2.0 * PI * 0.5 * t);

  // Gangguan kecil lain
  float drift = 0.3 * sin(2.0 * PI * 0.08 * t);

  // Noise sensor fiksi
  float noise = randomGaussian(0.0, 0.8);

  return movement + drift + noise;
}

// =====================================================
// INISIALISASI PARTICLE FILTER
// =====================================================
void initParticleFilter() {
  for (int i = 0; i < N_PARTICLES; i++) {
    particles[i] = randomGaussian(0.0, 1.0);
    weights[i] = 1.0 / N_PARTICLES;
  }
}

// =====================================================
// SYSTEMATIC RESAMPLING
// =====================================================
void systematicResampling() {
  float step = 1.0 / N_PARTICLES;
  float u = randomUniform() * step;
  float cumsum = weights[0];
  int i = 0;

  for (int j = 0; j < N_PARTICLES; j++) {
    float threshold = u + j * step;

    while (threshold > cumsum && i < N_PARTICLES - 1) {
      i++;
      cumsum += weights[i];
    }

    newParticles[j] = particles[i];
  }

  for (int j = 0; j < N_PARTICLES; j++) {
    particles[j] = newParticles[j];
    weights[j] = 1.0 / N_PARTICLES;
  }
}

// =====================================================
// PARTICLE FILTER 1000 PARTIKEL
// =====================================================
float runParticleFilter(float measurement) {
  float weightSum = 0.0;
  float estimate = 0.0;

  // 1. Prediction + Weighting
  for (int i = 0; i < N_PARTICLES; i++) {
    particles[i] += randomGaussian(0.0, PROCESS_NOISE_STD);

    float diff = measurement - particles[i];
    float exponent = -0.5 * (diff * diff) / (MEASUREMENT_NOISE_STD * MEASUREMENT_NOISE_STD);

    weights[i] = exp(exponent) + 1e-12;
    weightSum += weights[i];
  }

  // 2. Normalize weights
  if (weightSum <= 0.0) {
    for (int i = 0; i < N_PARTICLES; i++) {
      weights[i] = 1.0 / N_PARTICLES;
    }
  } else {
    for (int i = 0; i < N_PARTICLES; i++) {
      weights[i] /= weightSum;
    }
  }

  // 3. Estimate
  for (int i = 0; i < N_PARTICLES; i++) {
    estimate += particles[i] * weights[i];
  }

  // 4. Resampling
  systematicResampling();

  return estimate;
}

// =====================================================
// KIRIM PAKET UDP
// Format:
// DATA,mode,seq,esp_time_ms,raw,filtered_edge,edge_processing_ms
// =====================================================
void sendDataPacket(
  char mode,
  int seq,
  unsigned long espTimeMs,
  float rawValue,
  float filteredEdge,
  float edgeProcessingMs
) {
  udp.beginPacket(targetIP, targetPort);

  udp.printf(
    "DATA,%c,%d,%lu,%.6f,%.6f,%.6f",
    mode,
    seq,
    espTimeMs,
    rawValue,
    filteredEdge,
    edgeProcessingMs
  );

  udp.endPacket();
}

// =====================================================
// KIRIM END PACKET
// =====================================================
void sendEndPacket() {
  udp.beginPacket(targetIP, targetPort);
  udp.printf("END,%c,%d,%lu", MODE_SCENARIO, seq, millis());
  udp.endPacket();
}

// =====================================================
// SETUP
// =====================================================
void setup() {
  Serial.begin(115200);
  delay(1000);

  randomSeed(analogRead(0));

  Serial.println();
  Serial.println("======================================");
  Serial.println("ESP32 Fake IMU UDP Sender");
  Serial.print("Mode Skenario: ");
  Serial.println(MODE_SCENARIO);
  Serial.println("Particle Filter: 1000 particles");
  Serial.println("======================================");

  WiFi.begin(ssid, password);

  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi connected.");
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  udp.begin(1235);

  initParticleFilter();

  experimentStartMs = millis();
  lastSampleTime = millis();

  Serial.println("Experiment started...");
}

// =====================================================
// LOOP
// =====================================================
void loop() {
  if (experimentDone) {
    delay(1000);
    return;
  }

  unsigned long now = millis();

  if (now - lastSampleTime >= SAMPLE_INTERVAL_MS) {
    lastSampleTime = now;

    if (seq >= TOTAL_SAMPLES) {
      sendEndPacket();

      Serial.println();
      Serial.println("Experiment finished.");
      Serial.print("Total samples sent: ");
      Serial.println(seq);

      experimentDone = true;
      return;
    }

    float rawValue = generateFakeIMU(seq);

    float filteredEdge = 0.0;
    float edgeProcessingMs = 0.0;

    if (MODE_SCENARIO == 'B') {
      unsigned long startMicros = micros();
      filteredEdge = runParticleFilter(rawValue);
      unsigned long endMicros = micros();

      edgeProcessingMs = (endMicros - startMicros) / 1000.0;
    }

    // Pada skenario A:
    // filteredEdge = 0
    // edgeProcessingMs = 0
    //
    // Pada skenario B:
    // filteredEdge berisi hasil PF ESP32
    // edgeProcessingMs berisi waktu proses PF ESP32
    sendDataPacket(
      MODE_SCENARIO,
      seq,
      now - experimentStartMs,
      rawValue,
      filteredEdge,
      edgeProcessingMs
    );

    Serial.print("Sent seq: ");
    Serial.print(seq);
    Serial.print(" | raw: ");
    Serial.print(rawValue, 4);

    if (MODE_SCENARIO == 'B') {
      Serial.print(" | edge filtered: ");
      Serial.print(filteredEdge, 4);
      Serial.print(" | edge ms: ");
      Serial.print(edgeProcessingMs, 4);
    }

    Serial.println();

    seq++;
  }
}