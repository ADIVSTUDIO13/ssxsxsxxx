#!/bin/bash

# Script Monitoring CPU dan Internet Speed
# Author: System Monitor
# License: MIT
# Version: 2.0

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Konfigurasi
INTERVAL=2  # Interval update dalam detik
LOG_FILE="system_monitor.log"
COUNT=1
SPEEDTEST_CLI_INSTALLED=false
HAS_SPEEDTEST_CLI=false

# Fungsi untuk membersihkan layar
clear_screen() {
    printf "\033c"
}

# Fungsi untuk menampilkan header
show_header() {
    clear_screen
    echo -e "${PURPLE}=============================================${NC}"
    echo -e "${CYAN}     SISTEM MONITOR - CPU & INTERNET SPEED    ${NC}"
    echo -e "${CYAN}            (Speedtest CLI Version)            ${NC}"
    echo -e "${PURPLE}=============================================${NC}"
    echo -e "Tanggal: $(date)"
    echo -e "Hostname: $(hostname)"
    echo -e "IP Publik: $(curl -s https://ipinfo.io/ip 2>/dev/null || echo 'Tidak terdeteksi')"
    echo -e "${PURPLE}=============================================${NC}\n"
}

# Fungsi untuk cek dan install speedtest-cli
check_speedtest_cli() {
    echo -e "${YELLOW}Memeriksa speedtest-cli...${NC}"
    
    # Cek jika speedtest-cli sudah terinstall
    if command -v speedtest &> /dev/null; then
        echo -e "${GREEN}✓ speedtest-cli (Ookla) sudah terinstall${NC}"
        HAS_SPEEDTEST_CLI=true
        return 0
    fi
    
    # Cek versi python speedtest
    if command -v speedtest-cli &> /dev/null; then
        echo -e "${GREEN}✓ speedtest-cli (Python) sudah terinstall${NC}"
        HAS_SPEEDTEST_CLI=true
        return 0
    fi
    
    echo -e "${RED}✗ speedtest-cli tidak ditemukan${NC}"
    return 1
}

# Fungsi untuk install speedtest-cli
install_speedtest_cli() {
    echo -e "${YELLOW}Menginstall speedtest-cli...${NC}"
    
    # Pilihan metode install
    echo -e "${CYAN}Pilih metode install:${NC}"
    echo -e "  1. Ookla Speedtest (Official)"
    echo -e "  2. Python speedtest-cli"
    echo -e "  3. Batal"
    
    read -p "Pilihan (1-3): " install_choice
    
    case $install_choice in
        1)
            install_ookla_speedtest
            ;;
        2)
            install_python_speedtest
            ;;
        3)
            echo -e "${YELLOW}Installasi dibatalkan${NC}"
            return 1
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid${NC}"
            return 1
            ;;
    esac
    
    # Cek ulang setelah install
    if check_speedtest_cli; then
        SPEEDTEST_CLI_INSTALLED=true
        return 0
    else
        return 1
    fi
}

# Fungsi install Ookla Speedtest
install_ookla_speedtest() {
    echo -e "${YELLOW}Menginstall Ookla Speedtest...${NC}"
    
    # Deteksi arsitektur sistem
    ARCH=$(uname -m)
    OS=$(uname -s)
    
    if [ "$OS" = "Linux" ]; then
        if [ "$ARCH" = "x86_64" ]; then
            echo -e "${BLUE}Download untuk Linux x86_64...${NC}"
            wget -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
            tar -xzf speedtest.tgz
            sudo cp speedtest /usr/local/bin/
            rm speedtest.tgz
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            echo -e "${BLUE}Download untuk Linux ARM64...${NC}"
            wget -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz
            tar -xzf speedtest.tgz
            sudo cp speedtest /usr/local/bin/
            rm speedtest.tgz
        else
            echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
            return 1
        fi
    else
        echo -e "${RED}Sistem operasi tidak didukung: $OS${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Ookla Speedtest berhasil diinstall${NC}"
    return 0
}

# Fungsi install Python speedtest-cli
install_python_speedtest() {
    echo -e "${YELLOW}Menginstall Python speedtest-cli...${NC}"
    
    # Cek jika python3 tersedia
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python3 tidak ditemukan${NC}"
        return 1
    fi
    
    # Install menggunakan pip
    if command -v pip3 &> /dev/null; then
        pip3 install speedtest-cli
    elif command -v pip &> /dev/null; then
        pip install speedtest-cli
    else
        echo -e "${RED}Pip tidak ditemukan${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Python speedtest-cli berhasil diinstall${NC}"
    return 0
}

# Fungsi untuk mendapatkan informasi CPU
get_cpu_info() {
    echo -e "${BLUE}=== INFORMASI CPU ===${NC}"
    
    # Nama CPU
    if command -v lscpu &> /dev/null; then
        echo -e "${YELLOW}Model CPU:${NC} $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
        
        # Jumlah core
        CORES=$(nproc)
        echo -e "${YELLOW}Jumlah Core:${NC} $CORES"
        
        # Frekuensi CPU
        CPU_FREQ=$(lscpu | grep "MHz" | head -1 | awk '{print $3}')
        echo -e "${YELLOW}Frekuensi CPU:${NC} $CPU_FREQ MHz"
    else
        echo -e "${YELLOW}Informasi CPU:${NC} $(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)"
        CORES=$(grep -c ^processor /proc/cpuinfo)
        echo -e "${YELLOW}Jumlah Core:${NC} $CORES"
    fi
    
    # Load average
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    echo -e "${YELLOW}Load Average (1,5,15m):${NC} $LOAD_AVG"
    
    # CPU Usage
    if command -v mpstat &> /dev/null; then
        CPU_USAGE=$(mpstat 1 1 | awk '/Average:/ {printf "%.1f", 100 - $12}')
        echo -e "${YELLOW}CPU Usage:${NC} ${GREEN}${CPU_USAGE}%${NC}"
    fi
    
    echo ""
}

# Fungsi untuk mengukur kecepatan CPU (benchmark kecil)
test_cpu_speed() {
    echo -e "${BLUE}=== TEST KECEPATAN CPU ===${NC}"
    
    # Test 1: Perhitungan integer
    echo -e "${YELLOW}1. Speed Test Integer:${NC}"
    START_TIME=$(date +%s%N)
    for i in {1..1000000}; do
        result=$((i * i))
    done
    END_TIME=$(date +%s%N)
    INT_TIME=$((($END_TIME - $START_TIME)/1000000))
    echo -e "   Waktu: ${GREEN}${INT_TIME} ms${NC}"
    
    # Test 2: Perhitungan floating point
    echo -e "${YELLOW}2. Speed Test Floating Point:${NC}"
    START_TIME=$(date +%s%N)
    for i in {1..50000}; do
        result=$(echo "$i * 3.14159" | bc -l 2>/dev/null || echo "0")
    done
    END_TIME=$(date +%s%N)
    FLOAT_TIME=$((($END_TIME - $START_TIME)/1000000))
    echo -e "   Waktu: ${GREEN}${FLOAT_TIME} ms${NC}"
    
    # Test 3: MD5 Hash computation
    echo -e "${YELLOW}3. Hash Computation Test:${NC}"
    START_TIME=$(date +%s%N)
    for i in {1..10000}; do
        echo "test$i" | md5sum &> /dev/null
    done
    END_TIME=$(date +%s%N)
    HASH_TIME=$((($END_TIME - $START_TIME)/1000000))
    echo -e "   Waktu: ${GREEN}${HASH_TIME} ms${NC}"
    
    # Skor relatif
    CPU_SCORE=$((1000000/(INT_TIME + FLOAT_TIME + HASH_TIME + 1)))
    echo -e "${YELLOW}4. CPU Score:${NC} ${GREEN}${CPU_SCORE} points${NC}"
    
    echo ""
}

# Fungsi untuk test internet menggunakan speedtest-cli
test_internet_speed_cli() {
    echo -e "${BLUE}=== TEST KECEPATAN INTERNET (SPEEDTEST-CLI) ===${NC}"
    
    # Cek koneksi internet
    echo -ne "${YELLOW}Checking internet connection...${NC}"
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN} OK${NC}"
    else
        echo -e "${RED} FAILED${NC}"
        echo -e "${RED}Tidak dapat terhubung ke internet${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Menjalankan speedtest...${NC}"
    echo -e "${CYAN}Ini mungkin memerlukan waktu beberapa detik...${NC}"
    echo ""
    
    # Cek versi speedtest yang tersedia
    if command -v speedtest &> /dev/null && [[ $(speedtest --version 2>&1) =~ "Ookla" ]]; then
        # Gunakan Ookla speedtest (official)
        echo -e "${PURPLE}Menggunakan Ookla Speedtest (Official)${NC}"
        speedtest --progress=no --format=json | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print('${GREEN}✓ Download:${NC}', f\"{data['download']['bandwidth'] * 8 / 1000000:.2f} Mbps\")
    print('${GREEN}✓ Upload:${NC}', f\"{data['upload']['bandwidth'] * 8 / 1000000:.2f} Mbps\")
    print('${GREEN}✓ Ping:${NC}', f\"{data['ping']['latency']:.1f} ms\")
    print('${GREEN}✓ Server:${NC}', data['server']['name'])
    print('${GREEN}✓ ISP:${NC}', data['isp'])
except:
    # Fallback ke text output
    print('${YELLOW}Menggunakan output text...${NC}')
" 2>/dev/null || speedtest --simple
        
    elif command -v speedtest-cli &> /dev/null; then
        # Gunakan python speedtest-cli
        echo -e "${PURPLE}Menggunakan Python speedtest-cli${NC}"
        speedtest-cli --simple
        
    else
        echo -e "${RED}Speedtest-cli tidak ditemukan${NC}"
        echo -e "${YELLOW}Silakan install speedtest-cli terlebih dahulu${NC}"
        return 1
    fi
    
    echo ""
}

# Fungsi untuk test internet cepat (tanpa speedtest-cli)
quick_internet_test() {
    echo -e "${BLUE}=== QUICK INTERNET TEST ===${NC}"
    
    # Ping test
    echo -e "${YELLOW}1. Ping Test:${NC}"
    echo -e "   Google DNS (8.8.8.8):"
    ping -c 3 8.8.8.8 | tail -2 | head -1
    
    # Download test kecil
    echo -e "${YELLOW}2. Quick Download Test:${NC}"
    START_TIME=$(date +%s)
    SIZE=1000000  # 1MB test
    if wget -O /dev/null --timeout=10 --tries=1 http://ipv4.download.thinkbroadband.com/1MB.zip 2>&1 | grep -o '[0-9.]\+ [KM]B/s'; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        if [ $DURATION -gt 0 ]; then
            SPEED=$((8 / DURATION))  # Approx Mbps
            echo -e "   Perkiraan kecepatan: ${GREEN}${SPEED} Mbps${NC}"
        fi
    else
        echo -e "   ${RED}Failed${NC}"
    fi
    
    echo ""
}

# Fungsi untuk monitoring real-time CPU usage
monitor_cpu_real_time() {
    echo -e "${BLUE}=== MONITORING REAL-TIME CPU (${INTERVAL}s interval) ===${NC}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk kembali ke menu utama${NC}"
    echo ""
    
    trap 'echo -e "\n${YELLOW}Menghentikan monitoring...${NC}"; sleep 1; return' SIGINT
    
    while true; do
        # Get CPU usage
        if command -v mpstat &> /dev/null; then
            CPU_USAGE=$(mpstat 1 1 | awk '/Average:/ {printf "%.1f", 100 - $12}')
        else
            CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        fi
        
        # Get memory usage
        MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
        MEM_USED=$(free -m | grep Mem | awk '{print $3}')
        MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
        
        # Get temperature jika ada sensor
        TEMP_C="N/A"
        if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
            TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
            TEMP_C=$((TEMP/1000))
        elif command -v sensors &> /dev/null; then
            TEMP_C=$(sensors | grep "Core" | head -1 | awk '{print $3}' | tr -d '+°C')
        fi
        
        # Get network interface stats
        if [ -f /sys/class/net/eth0/statistics/rx_bytes ] && [ -f /sys/class/net/eth0/statistics/tx_bytes ]; then
            RX_BYTES=$(cat /sys/class/net/eth0/statistics/rx_bytes)
            TX_BYTES=$(cat /sys/class/net/eth0/statistics/tx_bytes)
        elif [ -f /sys/class/net/wlan0/statistics/rx_bytes ] && [ -f /sys/class/net/wlan0/statistics/tx_bytes ]; then
            RX_BYTES=$(cat /sys/class/net/wlan0/statistics/rx_bytes)
            TX_BYTES=$(cat /sys/class/net/wlan0/statistics/tx_bytes)
        else
            RX_BYTES=0
            TX_BYTES=0
        fi
        
        clear_screen
        show_header
        
        # Display real-time data
        echo -e "${BLUE}=== REAL-TIME MONITORING ===${NC}"
        echo ""
        
        # CPU Bar
        echo -e "${YELLOW}CPU Usage:${NC}"
        draw_bar $CPU_USAGE
        
        # Memory Bar
        echo -e "${YELLOW}Memory Usage:${NC} ${MEM_USED}MB / ${MEM_TOTAL}MB"
        draw_bar $MEM_PERCENT
        
        # Stats
        echo -e "${YELLOW}CPU Temperature:${NC} ${GREEN}${TEMP_C}°C${NC}"
        echo -e "${YELLOW}Uptime:${NC} $(uptime -p | cut -d' ' -f2-)"
        echo -e "${YELLOW}Network RX/TX:${NC} $(bytes_to_human $RX_BYTES) / $(bytes_to_human $TX_BYTES)"
        echo -e "${YELLOW}Load Average:${NC} $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
        
        echo ""
        echo -e "${CYAN}Refresh dalam ${INTERVAL} detik...${NC}"
        echo -e "${YELLOW}Tekan Ctrl+C untuk berhenti${NC}"
        
        sleep $INTERVAL
    done
}

# Fungsi untuk menggambar progress bar
draw_bar() {
    local percent=$1
    local width=50
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    # Warna berdasarkan persentase
    if [ $percent -lt 50 ]; then
        COLOR=$GREEN
    elif [ $percent -lt 80 ]; then
        COLOR=$YELLOW
    else
        COLOR=$RED
    fi
    
    printf "["
    printf "${COLOR}"
    for ((i=0; i<filled; i++)); do printf "█"; done
    printf "${NC}"
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "] ${COLOR}%3.1f%%${NC}\n" "$percent"
}

# Fungsi konversi bytes ke human readable
bytes_to_human() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

# Fungsi untuk log hasil
log_results() {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] Iteration $COUNT" >> "$LOG_FILE"
    COUNT=$((COUNT+1))
}

# Fungsi untuk install dependencies
install_dependencies() {
    echo -e "${YELLOW}Menginstall dependencies yang diperlukan...${NC}"
    
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y bc wget curl python3 python3-pip sysstat lm-sensors
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        sudo yum install -y bc wget curl python3 python3-pip sysstat lm_sensors
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y bc wget curl python3 python3-pip sysstat lm_sensors
    elif command -v pacman &> /dev/null; then
        # Arch
        sudo pacman -S --noconfirm bc wget curl python3 python-pip sysstat lm_sensors
    else
        echo -e "${RED}Tidak dapat menentukan package manager${NC}"
    fi
    
    echo -e "${GREEN}Installasi dependencies selesai!${NC}"
    sleep 2
}

# Fungsi untuk menu utama
show_menu() {
    while true; do
        clear_screen
        show_header
        
        # Status speedtest-cli
        if $HAS_SPEEDTEST_CLI; then
            echo -e "${GREEN}✓ speedtest-cli: Tersedia${NC}"
        else
            echo -e "${RED}✗ speedtest-cli: Tidak tersedia${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}PILIHAN MENU:${NC}"
        echo -e "  ${GREEN}1.${NC} Informasi CPU"
        echo -e "  ${GREEN}2.${NC} Test Kecepatan CPU"
        echo -e "  ${GREEN}3.${NC} Test Kecepatan Internet (Speedtest CLI)"
        echo -e "  ${GREEN}4.${NC} Quick Internet Test"
        echo -e "  ${GREEN}5.${NC} Monitoring Real-time CPU"
        echo -e "  ${GREEN}6.${NC} Install Speedtest CLI"
        echo -e "  ${GREEN}7.${NC} Install Dependencies Lainnya"
        echo -e "  ${GREEN}8.${NC} Jalankan Semua Test"
        echo -e "  ${GREEN}9.${NC} Lihat Log"
        echo -e "  ${GREEN}0.${NC} Keluar"
        echo ""
        
        read -p "Pilih opsi (0-9): " choice
        
        case $choice in
            1)
                clear_screen
                show_header
                get_cpu_info
                read -p "Tekan Enter untuk kembali..."
                ;;
            2)
                clear_screen
                show_header
                test_cpu_speed
                log_results
                read -p "Tekan Enter untuk kembali..."
                ;;
            3)
                clear_screen
                show_header
                if $HAS_SPEEDTEST_CLI; then
                    test_internet_speed_cli
                else
                    echo -e "${RED}Speedtest CLI tidak terinstall!${NC}"
                    echo -e "${YELLOW}Pilih opsi 6 untuk install speedtest CLI${NC}"
                fi
                read -p "Tekan Enter untuk kembali..."
                ;;
            4)
                clear_screen
                show_header
                quick_internet_test
                read -p "Tekan Enter untuk kembali..."
                ;;
            5)
                monitor_cpu_real_time
                ;;
            6)
                clear_screen
                show_header
                install_speedtest_cli
                check_speedtest_cli
                read -p "Tekan Enter untuk kembali..."
                ;;
            7)
                clear_screen
                show_header
                install_dependencies
                read -p "Tekan Enter untuk kembali..."
                ;;
            8)
                clear_screen
                show_header
                get_cpu_info
                test_cpu_speed
                if $HAS_SPEEDTEST_CLI; then
                    test_internet_speed_cli
                else
                    quick_internet_test
                fi
                log_results
                read -p "Tekan Enter untuk kembali..."
                ;;
            9)
                clear_screen
                show_header
                echo -e "${BLUE}=== LOG FILE ===${NC}"
                if [ -f "$LOG_FILE" ]; then
                    cat "$LOG_FILE"
                else
                    echo "Log file tidak ditemukan."
                fi
                echo ""
                read -p "Tekan Enter untuk kembali..."
                ;;
            0)
                echo -e "${GREEN}Keluar dari program. Terima kasih!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main execution
main() {
    # Cek jika script dijalankan sebagai root
    if [ "$EUID" -eq 0 ]; then 
        echo -e "${YELLOW}Warning: Script berjalan sebagai root${NC}"
        sleep 1
    fi
    
    # Cek dependencies dasar
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    # Cek speedtest-cli
    check_speedtest_cli
    
    # Cek dependencies lain
    for cmd in bc wget curl; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}$cmd tidak ditemukan${NC}"
        fi
    done
    
    sleep 2
    
    # Tampilkan menu
    show_menu
}

# Jalankan main function
main