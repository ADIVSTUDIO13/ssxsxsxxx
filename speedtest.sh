#!/bin/bash

# Script Monitoring CPU dan Internet Speed
# Author: System Monitor
# License: MIT
# Version: 2.1 (No Auto-Refresh)

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Konfigurasi
LOG_FILE="system_monitor.log"
COUNT=1
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
    echo -e "${CYAN}         (Tanpa Auto-Refresh Version)         ${NC}"
    echo -e "${PURPLE}=============================================${NC}"
    echo -e "Tanggal: $(date)"
    echo -e "Hostname: $(hostname)"
    echo -e "IP Publik: $(curl -s https://ipinfo.io/ip 2>/dev/null || echo 'Tidak terdeteksi')"
    echo -e "${PURPLE}=============================================${NC}\n"
}

# Fungsi untuk cek speedtest-cli
check_speedtest_cli() {
    # Cek jika speedtest-cli sudah terinstall
    if command -v speedtest &> /dev/null; then
        HAS_SPEEDTEST_CLI=true
        return 0
    fi
    
    # Cek versi python speedtest
    if command -v speedtest-cli &> /dev/null; then
        HAS_SPEEDTEST_CLI=true
        return 0
    fi
    
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
    check_speedtest_cli
    return $?
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
            wget -q -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
            tar -xzf speedtest.tgz
            sudo mv speedtest /usr/local/bin/ 2>/dev/null || cp speedtest /usr/local/bin/
            rm -f speedtest.tgz
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            echo -e "${BLUE}Download untuk Linux ARM64...${NC}"
            wget -q -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz
            tar -xzf speedtest.tgz
            sudo mv speedtest /usr/local/bin/ 2>/dev/null || cp speedtest /usr/local/bin/
            rm -f speedtest.tgz
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
        pip3 install speedtest-cli -q
    elif command -v pip &> /dev/null; then
        pip install speedtest-cli -q
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
        CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
        echo -e "${YELLOW}Model CPU:${NC} $CPU_MODEL"
        
        # Jumlah core
        CORES=$(nproc)
        echo -e "${YELLOW}Jumlah Core:${NC} $CORES"
        
        # Frekuensi CPU
        CPU_FREQ=$(lscpu | grep "MHz" | head -1 | awk '{print $3}')
        echo -e "${YELLOW}Frekuensi CPU:${NC} $CPU_FREQ MHz"
    else
        CPU_MODEL=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d':' -f2 | xargs)
        echo -e "${YELLOW}Model CPU:${NC} $CPU_MODEL"
        CORES=$(grep -c ^processor /proc/cpuinfo)
        echo -e "${YELLOW}Jumlah Core:${NC} $CORES"
    fi
    
    # Architecture
    echo -e "${YELLOW}Architecture:${NC} $(uname -m)"
    
    # Load average
    LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    echo -e "${YELLOW}Load Average (1,5,15m):${NC} $LOAD_AVG"
    
    # Uptime
    echo -e "${YELLOW}Uptime:${NC} $(uptime -p | sed 's/up //')"
    
    echo ""
}

# Fungsi untuk mengukur kecepatan CPU
test_cpu_speed() {
    echo -e "${BLUE}=== TEST KECEPATAN CPU ===${NC}"
    echo -e "${YELLOW}Menjalankan benchmark CPU...${NC}"
    
    # Test 1: Perhitungan integer
    echo -e "\n${YELLOW}1. Integer Calculation Test:${NC}"
    START_TIME=$(date +%s%N)
    for i in {1..1000000}; do
        result=$((i * i))
    done
    END_TIME=$(date +%s%N)
    INT_TIME=$((($END_TIME - $START_TIME)/1000000))
    echo -e "   Waktu eksekusi: ${GREEN}${INT_TIME} ms${NC}"
    
    # Test 2: Perhitungan floating point
    echo -e "\n${YELLOW}2. Floating Point Calculation Test:${NC}"
    START_TIME=$(date +%s%N)
    for i in {1..50000}; do
        result=$(echo "$i * 3.14159" | bc -l 2>/dev/null || echo "0")
    done
    END_TIME=$(date +%s%N)
    FLOAT_TIME=$((($END_TIME - $START_TIME)/1000000))
    echo -e "   Waktu eksekusi: ${GREEN}${FLOAT_TIME} ms${NC}"
    
    # Test 3: MD5 Hash computation
    echo -e "\n${YELLOW}3. Hash Computation Test:${NC}"
    if command -v md5sum &> /dev/null; then
        START_TIME=$(date +%s%N)
        for i in {1..10000}; do
            echo "test$i" | md5sum &> /dev/null
        done
        END_TIME=$(date +%s%N)
        HASH_TIME=$((($END_TIME - $START_TIME)/1000000))
        echo -e "   Waktu eksekusi: ${GREEN}${HASH_TIME} ms${NC}"
    else
        echo -e "   ${YELLOW}md5sum tidak tersedia, test dilewati${NC}"
        HASH_TIME=0
    fi
    
    # Skor CPU
    TOTAL_TIME=$((INT_TIME + FLOAT_TIME + HASH_TIME))
    if [ $TOTAL_TIME -gt 0 ]; then
        CPU_SCORE=$((1000000 / TOTAL_TIME))
    else
        CPU_SCORE=0
    fi
    
    echo -e "\n${YELLOW}4. Hasil CPU Benchmark:${NC}"
    echo -e "   Total waktu: ${CYAN}${TOTAL_TIME} ms${NC}"
    echo -e "   CPU Score: ${GREEN}${CPU_SCORE} points${NC}"
    
    # Rating berdasarkan skor
    if [ $CPU_SCORE -gt 500 ]; then
        RATING="Sangat Cepat"
    elif [ $CPU_SCORE -gt 200 ]; then
        RATING="Cepat"
    elif [ $CPU_SCORE -gt 100 ]; then
        RATING="Sedang"
    else
        RATING="Lambat"
    fi
    echo -e "   Rating: ${BLUE}${RATING}${NC}"
    
    echo ""
}

# Fungsi untuk test internet menggunakan speedtest-cli
test_internet_speed_cli() {
    echo -e "${BLUE}=== TEST KECEPATAN INTERNET (SPEEDTEST-CLI) ===${NC}"
    
    # Cek koneksi internet
    echo -ne "${YELLOW}Memeriksa koneksi internet...${NC}"
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN} TERHUBUNG${NC}"
    else
        echo -e "${RED} TIDAK TERHUBUNG${NC}"
        echo -e "${RED}Tidak dapat melakukan speedtest${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Menjalankan speedtest...${NC}"
    echo -e "${CYAN}Harap tunggu, proses mungkin memerlukan waktu 15-30 detik...${NC}"
    echo ""
    
    # Cek versi speedtest yang tersedia
    if command -v speedtest &> /dev/null && [[ $(speedtest --version 2>&1) =~ "Ookla" ]]; then
        # Gunakan Ookla speedtest (official)
        echo -e "${PURPLE}Menggunakan Ookla Speedtest (Official)${NC}\n"
        
        # Eksekusi speedtest dan capture output
        SPEEDTEST_OUTPUT=$(speedtest --progress=no --format=json 2>/dev/null)
        
        if [ $? -eq 0 ] && [ ! -z "$SPEEDTEST_OUTPUT" ]; then
            # Parse JSON output
            echo "$SPEEDTEST_OUTPUT" | python3 -c "
import json, sys

try:
    data = json.load(sys.stdin)
    
    # Download speed (convert bytes/sec to Mbps)
    download_bps = data['download']['bandwidth'] * 8
    download_mbps = download_bps / 1000000
    
    # Upload speed
    upload_bps = data['upload']['bandwidth'] * 8
    upload_mbps = upload_bps / 1000000
    
    # Ping/latency
    ping_ms = data['ping']['latency']
    
    # Server info
    server_name = data['server']['name']
    server_location = data['server']['location']
    server_country = data['server']['country']
    
    # ISP info
    isp_name = data['isp']
    
    # Result URL
    result_url = data['result']['url']
    
    print(f'${GREEN}✓ Download Speed:${NC} {download_mbps:.2f} Mbps')
    print(f'${GREEN}✓ Upload Speed:${NC} {upload_mbps:.2f} Mbps')
    print(f'${GREEN}✓ Ping/Latency:${NC} {ping_ms:.1f} ms')
    print(f'${GREEN}✓ Jitter:${NC} {data[\"ping\"][\"jitter\"]:.1f} ms')
    print(f'${GREEN}✓ Server:${NC} {server_name}')
    print(f'${GREEN}✓ Lokasi:${NC} {server_location}, {server_country}')
    print(f'${GREEN}✓ ISP:${NC} {isp_name}')
    print(f'${GREEN}✓ Result URL:${NC} {result_url}')
    
except Exception as e:
    print(f'${RED}Error parsing JSON output:${NC}', str(e))
    print('${YELLOW}Menggunakan output sederhana...${NC}')
" 2>/dev/null || echo -e "${RED}Gagal parse output${NC}"
        
        else
            # Fallback ke simple output
            echo -e "${YELLOW}Menggunakan output sederhana...${NC}\n"
            speedtest --simple
        fi
        
    elif command -v speedtest-cli &> /dev/null; then
        # Gunakan python speedtest-cli
        echo -e "${PURPLE}Menggunakan Python speedtest-cli${NC}\n"
        speedtest-cli --simple
        
    else
        echo -e "${RED}Speedtest-cli tidak ditemukan${NC}"
        echo -e "${YELLOW}Silakan install speedtest-cli terlebih dahulu (Pilih menu 6)${NC}"
        return 1
    fi
    
    echo ""
}

# Fungsi untuk test internet cepat
quick_internet_test() {
    echo -e "${BLUE}=== QUICK INTERNET TEST ===${NC}"
    
    # Ping test ke beberapa server
    echo -e "${YELLOW}1. Ping Test:${NC}"
    
    SERVERS=("8.8.8.8" "1.1.1.1" "google.com" "cloudflare.com")
    
    for server in "${SERVERS[@]}"; do
        echo -ne "   ${server}: "
        if ping -c 2 -W 1 "$server" &> /dev/null; then
            ping_result=$(ping -c 2 -W 1 "$server" | tail -1 | awk -F '/' '{print $5}')
            if [ ! -z "$ping_result" ]; then
                echo -e "${GREEN}${ping_result} ms${NC}"
            else
                echo -e "${GREEN}OK${NC}"
            fi
        else
            echo -e "${RED}TIMEOUT${NC}"
        fi
    done
    
    # Download test kecil
    echo -e "\n${YELLOW}2. Quick Download Test:${NC}"
    
    TEST_URLS=(
        "http://ipv4.download.thinkbroadband.com/1MB.zip"
        "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
    )
    
    for url in "${TEST_URLS[@]}"; do
        echo -ne "   Testing $url... "
        START_TIME=$(date +%s)
        
        if wget -O /dev/null --timeout=5 --tries=1 "$url" 2>&1 | grep -q "saved"; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            
            if [ $DURATION -gt 0 ]; then
                # 1MB = 8 megabits, calculate Mbps
                SPEED=$((8 / DURATION))
                echo -e "${GREEN}${SPEED} Mbps${NC}"
                break
            else
                echo -e "${YELLOW}Terlalu cepat untuk diukur${NC}"
            fi
        else
            echo -e "${RED}Gagal${NC}"
        fi
    done
    
    echo ""
}

# Fungsi untuk menampilkan status sistem saat ini
show_system_status() {
    echo -e "${BLUE}=== STATUS SISTEM SAAT INI ===${NC}"
    
    # CPU Usage
    if command -v mpstat &> /dev/null; then
        CPU_USAGE=$(mpstat 1 1 | awk '/Average:/ {printf "%.1f", 100 - $12}')
    else
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    fi
    
    # Memory usage
    MEM_INFO=$(free -m | grep Mem)
    MEM_TOTAL=$(echo $MEM_INFO | awk '{print $2}')
    MEM_USED=$(echo $MEM_INFO | awk '{print $3}')
    MEM_FREE=$(echo $MEM_INFO | awk '{print $4}')
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    
    # Disk usage
    DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}')
    
    # Temperature jika ada
    TEMP_C="N/A"
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
        TEMP_C=$((TEMP/1000))
    fi
    
    # Uptime
    UPTIME=$(uptime -p)
    
    # Display
    echo -e "${YELLOW}CPU Usage:${NC} $CPU_USAGE%"
    echo -e "${YELLOW}Memory:${NC} ${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PERCENT}%)"
    echo -e "${YELLOW}Disk Usage (/):${NC} $DISK_USAGE"
    echo -e "${YELLOW}CPU Temperature:${NC} $TEMP_C°C"
    echo -e "${YELLOW}Uptime:${NC} $UPTIME"
    echo -e "${YELLOW}Load Average:${NC} $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
    
    echo ""
}

# Fungsi untuk log hasil
log_results() {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] Test ke-$COUNT" >> "$LOG_FILE"
    COUNT=$((COUNT+1))
}

# Fungsi untuk install dependencies
install_dependencies() {
    echo -e "${YELLOW}Menginstall dependencies yang diperlukan...${NC}"
    
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y bc wget curl python3 python3-pip sysstat lm-sensors
        echo -e "${GREEN}✓ Dependencies berhasil diinstall${NC}"
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS
        sudo yum install -y bc wget curl python3 python3-pip sysstat lm_sensors
        echo -e "${GREEN}✓ Dependencies berhasil diinstall${NC}"
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf install -y bc wget curl python3 python3-pip sysstat lm_sensors
        echo -e "${GREEN}✓ Dependencies berhasil diinstall${NC}"
    elif command -v pacman &> /dev/null; then
        # Arch
        sudo pacman -S --noconfirm bc wget curl python3 python-pip sysstat lm_sensors
        echo -e "${GREEN}✓ Dependencies berhasil diinstall${NC}"
    else
        echo -e "${YELLOW}Tidak dapat menentukan package manager${NC}"
        echo -e "${YELLOW}Silakan install manual: bc, wget, curl, python3${NC}"
    fi
    
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
        
        show_system_status
        
        echo -e "${CYAN}PILIHAN MENU:${NC}"
        echo -e "  ${GREEN}1.${NC} Informasi CPU Detail"
        echo -e "  ${GREEN}2.${NC} Test Kecepatan CPU (Benchmark)"
        echo -e "  ${GREEN}3.${NC} Test Kecepatan Internet (Speedtest CLI)"
        echo -e "  ${GREEN}4.${NC} Quick Internet Test"
        echo -e "  ${GREEN}5.${NC} Status Sistem Saat Ini"
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
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            2)
                clear_screen
                show_header
                test_cpu_speed
                log_results
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
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
                log_results
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            4)
                clear_screen
                show_header
                quick_internet_test
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            5)
                clear_screen
                show_header
                show_system_status
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            6)
                clear_screen
                show_header
                install_speedtest_cli
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            7)
                clear_screen
                show_header
                install_dependencies
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            8)
                clear_screen
                show_header
                echo -e "${BLUE}=== MENJALANKAN SEMUA TEST ===${NC}\n"
                
                echo -e "${YELLOW}[1/3] Mengambil informasi CPU...${NC}"
                get_cpu_info
                
                echo -e "${YELLOW}[2/3] Menjalankan CPU benchmark...${NC}"
                test_cpu_speed
                
                echo -e "${YELLOW}[3/3] Menjalankan internet speed test...${NC}"
                if $HAS_SPEEDTEST_CLI; then
                    test_internet_speed_cli
                else
                    quick_internet_test
                fi
                
                log_results
                echo -e "${GREEN}✓ Semua test selesai!${NC}"
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            9)
                clear_screen
                show_header
                echo -e "${BLUE}=== LOG FILE ===${NC}"
                echo -e "File: $LOG_FILE"
                echo -e "================================\n"
                if [ -f "$LOG_FILE" ]; then
                    if [ -s "$LOG_FILE" ]; then
                        cat "$LOG_FILE"
                    else
                        echo "Log file kosong."
                    fi
                else
                    echo "Log file tidak ditemukan."
                fi
                echo -e "\n================================\n"
                echo -e "${YELLOW}Tekan Enter untuk kembali ke menu...${NC}"
                read
                ;;
            0)
                echo -e "\n${GREEN}Keluar dari program. Terima kasih!${NC}"
                echo -e "${BLUE}File log tersimpan di: $LOG_FILE${NC}"
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
        echo -e "${YELLOW}Info: Script berjalan sebagai root${NC}"
        sleep 1
    fi
    
    # Cek dependencies dasar
    echo -e "${YELLOW}Memeriksa dependencies...${NC}"
    
    # Cek speedtest-cli
    check_speedtest_cli
    
    # Cek dependencies lain
    MISSING_DEPS=()
    for cmd in bc wget curl; do
        if ! command -v $cmd &> /dev/null; then
            MISSING_DEPS+=("$cmd")
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Dependencies berikut tidak ditemukan:${NC}"
        for dep in "${MISSING_DEPS[@]}"; do
            echo -e "  ${RED}✗${NC} $dep"
        done
        echo -e "${YELLOW}Anda bisa install melalui menu 7${NC}"
        sleep 2
    else
        echo -e "${GREEN}✓ Semua dependencies tersedia${NC}"
        sleep 1
    fi
    
    # Tampilkan menu
    show_menu
}

# Jalankan main function
main