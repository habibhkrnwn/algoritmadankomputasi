import socket
import time
import os
import glob
from datetime import datetime

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


# =====================================================
# KONFIGURASI UDP
# =====================================================
UDP_IP = "0.0.0.0"
UDP_PORT = 1234


# =====================================================
# KONFIGURASI PARTICLE FILTER CLOUD
# =====================================================
N_PARTICLES = 1000
PROCESS_NOISE_STD = 0.15
MEASUREMENT_NOISE_STD = 0.80

particles_cloud = np.random.normal(0, 1, N_PARTICLES)
weights_cloud = np.ones(N_PARTICLES) / N_PARTICLES


# =====================================================
# FOLDER OUTPUT
# =====================================================
OUTPUT_DIR = "hasil_eksperimen"
os.makedirs(OUTPUT_DIR, exist_ok=True)


# =====================================================
# PARTICLE FILTER CLOUD / RASPBERRY PI
# =====================================================
def systematic_resampling(particles, weights):
    n = len(particles)
    positions = (np.random.random() + np.arange(n)) / n

    indexes = np.zeros(n, dtype=np.int32)

    cumulative_sum = np.cumsum(weights)
    i, j = 0, 0

    while i < n:
        if positions[i] < cumulative_sum[j]:
            indexes[i] = j
            i += 1
        else:
            j += 1

    return particles[indexes]


def particle_filter_cloud(measurement):
    global particles_cloud, weights_cloud

    # 1. Prediction
    particles_cloud = particles_cloud + np.random.normal(
        0,
        PROCESS_NOISE_STD,
        N_PARTICLES
    )

    # 2. Weighting
    diff = measurement - particles_cloud
    weights_cloud = np.exp(
        -0.5 * (diff ** 2) / (MEASUREMENT_NOISE_STD ** 2)
    ) + 1e-300

    # 3. Normalize
    weights_cloud = weights_cloud / np.sum(weights_cloud)

    # 4. Estimate
    estimate = np.sum(particles_cloud * weights_cloud)

    # 5. Resampling
    particles_cloud = systematic_resampling(particles_cloud, weights_cloud)
    weights_cloud = np.ones(N_PARTICLES) / N_PARTICLES

    return estimate


# =====================================================
# SIMPAN CSV PER SKENARIO
# =====================================================
def save_session_csv(rows, mode):
    if not rows:
        return None

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"scenario_{mode}_{timestamp}.csv"
    filepath = os.path.join(OUTPUT_DIR, filename)

    df = pd.DataFrame(rows)
    df.to_csv(filepath, index=False)

    print()
    print(f"CSV saved: {filepath}")

    return filepath


# =====================================================
# CARI FILE TERBARU PER MODE
# =====================================================
def get_latest_file(mode):
    pattern = os.path.join(OUTPUT_DIR, f"scenario_{mode}_*.csv")
    files = glob.glob(pattern)

    if not files:
        return None

    return max(files, key=os.path.getmtime)


# =====================================================
# BUAT PLOT RAW VS FILTERED CLOUD VS FILTERED EDGE
# =====================================================
def create_comparison_plot():
    file_a = get_latest_file("A")
    file_b = get_latest_file("B")

    if file_a is None or file_b is None:
        print()
        print("Plot belum dibuat karena file skenario A dan B belum lengkap.")
        print("Jalankan eksperimen mode A dan mode B terlebih dahulu.")
        return

    df_a = pd.read_csv(file_a)
    df_b = pd.read_csv(file_b)

    min_len = min(len(df_a), len(df_b))

    df_a = df_a.iloc[:min_len].copy()
    df_b = df_b.iloc[:min_len].copy()

    x = np.arange(min_len)

    plt.figure(figsize=(14, 7))

    plt.plot(
        x,
        df_a["raw_value"],
        label="Raw Data"
    )

    plt.plot(
        x,
        df_a["filtered_cloud"],
        label="Filtered Cloud / Server-Side"
    )

    plt.plot(
        x,
        df_b["filtered_edge"],
        label="Filtered Edge / Client-Side"
    )

    plt.title("Perbandingan Raw Data vs Filtered Edge vs Filtered Cloud")
    plt.xlabel("Sample")
    plt.ylabel("Simulated IMU Acceleration X")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()

    plot_path = os.path.join(OUTPUT_DIR, "plot_raw_vs_edge_vs_cloud.png")
    plt.savefig(plot_path, dpi=300)
    plt.close()

    print(f"Plot saved: {plot_path}")

    create_summary(df_a, df_b)


# =====================================================
# BUAT SUMMARY PROCESSING TIME DAN ANALISIS DASAR
# =====================================================
def create_summary(df_a, df_b):
    summary = []

    # Skenario A
    summary.append({
        "scenario": "A - Cloud / Server-Side Filtering",
        "total_packets": len(df_a),
        "mean_processing_ms": df_a["cloud_processing_ms"].mean(),
        "median_processing_ms": df_a["cloud_processing_ms"].median(),
        "max_processing_ms": df_a["cloud_processing_ms"].max(),
        "min_processing_ms": df_a["cloud_processing_ms"].min(),
        "total_processing_ms": df_a["cloud_processing_ms"].sum(),
        "mean_packet_interval_ms": df_a["arrival_interval_ms"].mean(),
        "packet_loss_estimation": int(df_a["seq"].max() + 1 - len(df_a))
    })

    # Skenario B
    summary.append({
        "scenario": "B - Edge / Client-Side Filtering",
        "total_packets": len(df_b),
        "mean_processing_ms": df_b["edge_processing_ms"].mean(),
        "median_processing_ms": df_b["edge_processing_ms"].median(),
        "max_processing_ms": df_b["edge_processing_ms"].max(),
        "min_processing_ms": df_b["edge_processing_ms"].min(),
        "total_processing_ms": df_b["edge_processing_ms"].sum(),
        "mean_packet_interval_ms": df_b["arrival_interval_ms"].mean(),
        "packet_loss_estimation": int(df_b["seq"].max() + 1 - len(df_b))
    })

    df_summary = pd.DataFrame(summary)

    summary_path = os.path.join(OUTPUT_DIR, "summary_processing_time.csv")
    df_summary.to_csv(summary_path, index=False)

    print(f"Summary saved: {summary_path}")
    print()
    print("========== SUMMARY PROCESSING TIME ==========")
    print(df_summary.to_string(index=False))
    print("=============================================")


# =====================================================
# UDP RECEIVER
# =====================================================
def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((UDP_IP, UDP_PORT))

    print("======================================")
    print("Raspberry Pi UDP Receiver + Plotter")
    print(f"Listening on {UDP_IP}:{UDP_PORT}")
    print("Particle Filter Cloud: 1000 particles")
    print("======================================")
    print()
    print("Langkah penggunaan:")
    print("1. Jalankan script ini.")
    print("2. Upload ESP32 mode A, tunggu selesai.")
    print("3. Upload ESP32 mode B, tunggu selesai.")
    print("4. Plot dan summary akan dibuat otomatis setelah data A dan B tersedia.")
    print()

    current_rows = []
    current_mode = None
    last_arrival_time = None

    try:
        while True:
            data, addr = sock.recvfrom(2048)
            arrival_time = time.time()
            message = data.decode(errors="ignore").strip()
            parts = message.split(",")

            if len(parts) < 2:
                continue

            packet_type = parts[0]

            # =====================================================
            # PAKET DATA
            # Format:
            # DATA,mode,seq,esp_time_ms,raw,filtered_edge,edge_processing_ms
            # =====================================================
            if packet_type == "DATA":
                if len(parts) != 7:
                    print(f"Invalid DATA packet: {message}")
                    continue

                mode = parts[1]
                seq = int(parts[2])
                esp_time_ms = float(parts[3])
                raw_value = float(parts[4])
                filtered_edge = float(parts[5])
                edge_processing_ms = float(parts[6])

                if current_mode is None:
                    current_mode = mode
                    current_rows = []
                    last_arrival_time = None

                    print()
                    print(f"--- New session detected: Scenario {current_mode} ---")

                if current_mode != mode:
                    print()
                    print("Mode changed before END packet. Saving previous session...")
                    save_session_csv(current_rows, current_mode)

                    current_mode = mode
                    current_rows = []
                    last_arrival_time = None

                # Hitung interval antar paket
                if last_arrival_time is None:
                    arrival_interval_ms = 0.0
                else:
                    arrival_interval_ms = (arrival_time - last_arrival_time) * 1000.0

                last_arrival_time = arrival_time

                # Cloud filtering hanya dilakukan pada skenario A
                if mode == "A":
                    start_process = time.perf_counter()
                    filtered_cloud = particle_filter_cloud(raw_value)
                    end_process = time.perf_counter()

                    cloud_processing_ms = (end_process - start_process) * 1000.0

                else:
                    filtered_cloud = np.nan
                    cloud_processing_ms = 0.0

                row = {
                    "mode": mode,
                    "seq": seq,
                    "arrival_timestamp": arrival_time,
                    "esp_time_ms": esp_time_ms,
                    "raw_value": raw_value,
                    "filtered_cloud": filtered_cloud,
                    "filtered_edge": filtered_edge,
                    "cloud_processing_ms": cloud_processing_ms,
                    "edge_processing_ms": edge_processing_ms,
                    "arrival_interval_ms": arrival_interval_ms,
                    "sender_ip": addr[0],
                    "sender_port": addr[1]
                }

                current_rows.append(row)

                print(
                    f"Mode {mode} | "
                    f"Seq {seq} | "
                    f"Raw {raw_value:.4f} | "
                    f"Cloud {filtered_cloud if not np.isnan(filtered_cloud) else 0:.4f} | "
                    f"Edge {filtered_edge:.4f} | "
                    f"Rows {len(current_rows)}",
                    end="\r"
                )

            # =====================================================
            # PAKET END
            # Format:
            # END,mode,total_seq,esp_time_ms
            # =====================================================
            elif packet_type == "END":
                if len(parts) != 4:
                    print(f"Invalid END packet: {message}")
                    continue

                mode = parts[1]
                total_seq = int(parts[2])
                esp_time_ms = float(parts[3])

                print()
                print()
                print(f"END packet received from Scenario {mode}")
                print(f"ESP total samples: {total_seq}")
                print(f"ESP elapsed time ms: {esp_time_ms}")

                if current_rows:
                    save_session_csv(current_rows, mode)

                current_rows = []
                current_mode = None
                last_arrival_time = None

                create_comparison_plot()

            else:
                print(f"Unknown packet: {message}")

    except KeyboardInterrupt:
        print()
        print("Program stopped by user.")

        if current_rows and current_mode is not None:
            print("Saving unfinished session...")
            save_session_csv(current_rows, current_mode)
            create_comparison_plot()

    finally:
        sock.close()


if __name__ == "__main__":
    main()
