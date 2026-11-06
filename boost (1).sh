#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  TOOL BOOST CLOUDPHONE - made by imnotminh
#  Chạy trong Termux, cần quyền root (su)
# ============================================================

# Cho phép chạy cả khi dùng: curl ... | bash
[ -t 0 ] || exec < /dev/tty

BACKUP="$HOME/.boost_orig"
SWAPFILE="/data/boost_swapfile"

G='\033[1;32m'; R='\033[1;31m'; Y='\033[1;33m'; C='\033[1;36m'; M='\033[1;35m'; N='\033[0m'

# ---------- kiểm tra root ----------
if ! command -v su >/dev/null 2>&1; then
  echo -e "${R}Không tìm thấy lệnh su. Máy chưa root hoặc chưa cấp quyền cho Termux.${N}"
  exit 1
fi
if ! su -c "id -u" </dev/null 2>/dev/null | grep -q '^0$'; then
  stty sane 2>/dev/null
  echo -e "${R}Không lấy được quyền root. Hãy cấp quyền root cho Termux rồi chạy lại.${N}"
  exit 1
fi
stty sane 2>/dev/null

# Chạy lệnh root; </dev/null để su không đụng vào terminal, stty sane để khôi phục
sudo_run() { su -c "$1" </dev/null; local rc=$?; stty sane 2>/dev/null; return $rc; }
pause() { echo; read -rp "Nhấn Enter để quay lại menu..." _; }

# ---------- BANNER ----------
banner() {
  stty sane 2>/dev/null
  clear
  echo -e "${C}"
  cat <<'EOF'
██████╗  ██████╗  ██████╗ ███████╗████████╗
██╔══██╗██╔═══██╗██╔═══██╗██╔════╝╚══██╔══╝
██████╔╝██║   ██║██║   ██║███████╗   ██║   
██╔══██╗██║   ██║██║   ██║╚════██║   ██║   
██████╔╝╚██████╔╝╚██████╔╝███████║   ██║   
╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   
EOF
  echo -e "${N}${Y}╔══════════════════════════════════════════╗"
  echo -e "║${G}        TOOL BOOST CLOUDPHONE             ${Y}║"
  echo -e "║${M}          made by imnotminh               ${Y}║"
  echo -e "╚══════════════════════════════════════════╝${N}"
  echo
}

# ---------- ĐỘ PHÂN GIẢI ----------
save_original_display() {
  if [ ! -f "$BACKUP" ]; then
    local size dens
    size=$(sudo_run "wm size" | grep -i "Physical size" | awk '{print $3}')
    dens=$(sudo_run "wm density" | grep -i "Physical density" | awk '{print $3}')
    [ -z "$size" ] && size=$(sudo_run "wm size" | awk '{print $NF}' | head -n1)
    [ -z "$dens" ] && dens=$(sudo_run "wm density" | awk '{print $NF}' | head -n1)
    echo "ORIG_SIZE=$size"    >  "$BACKUP"
    echo "ORIG_DENSITY=$dens" >> "$BACKUP"
    echo -e "${C}Đã lưu độ phân giải gốc: $size / $dens dpi${N}"
  fi
}

apply_res() {   # $1 = WxH, $2 = dpi
  save_original_display
  sudo_run "wm size $1"
  sudo_run "wm density $2"
  echo -e "${G}Đã áp dụng độ phân giải $1 / $2 dpi${N}"
}

reset_display() {
  sudo_run "wm size reset"
  sudo_run "wm density reset"
  echo -e "${G}Đã khôi phục độ phân giải gốc.${N}"
}

menu_resolution() {
  banner
  echo -e "${Y}=== CHỌN ĐỘ PHÂN GIẢI ===${N}"
  echo " 1) 240p  (240x426, 120dpi)  - nhẹ nhất  [khuyên dùng]"
  echo " 2) 360p  (360x640, 160dpi)"
  echo " 3) 480p  (480x854, 200dpi)"
  echo " 4) 720p  (720x1280, 320dpi)"
  echo " 5) Tuỳ chỉnh"
  echo " 6) Khôi phục độ phân giải gốc"
  echo " 0) Quay lại"
  echo
  read -rp "Chọn: " ch
  case "$ch" in
    1) apply_res 240x426 120; pause;;
    2) apply_res 360x640 160; pause;;
    3) apply_res 480x854 200; pause;;
    4) apply_res 720x1280 320; pause;;
    5) read -rp "Độ phân giải (vd 300x533): " r
       read -rp "DPI (vd 140): " d
       apply_res "$r" "$d"; pause;;
    6) reset_display; pause;;
    *) ;;
  esac
}

# ---------- RAM ẢO ----------
show_mem() {
  echo -e "${C}--- RAM / SWAP hiện tại ---${N}"
  sudo_run "grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree' /proc/meminfo"
  echo -e "${C}--- Bộ nhớ trống (/data) ---${N}"
  sudo_run "df -h /data | tail -n1"
}

remove_vram() {
  sudo_run "swapoff $SWAPFILE 2>/dev/null"
  sudo_run "swapoff /dev/block/zram0 2>/dev/null"
  sudo_run "for l in \$(losetup -a 2>/dev/null | grep boost_swapfile | cut -d: -f1); do swapoff \$l 2>/dev/null; losetup -d \$l 2>/dev/null; done"
  sudo_run "rm -f $SWAPFILE"
}

try_swapfile() {
  sudo_run "rm -f $SWAPFILE; (fallocate -l ${1}M $SWAPFILE 2>/dev/null || dd if=/dev/zero of=$SWAPFILE bs=1M count=$1 2>/dev/null) && chmod 600 $SWAPFILE && mkswap $SWAPFILE >/dev/null 2>&1 && swapon $SWAPFILE 2>/dev/null"
}

try_loop() {
  sudo_run "[ -f $SWAPFILE ]" || return 1
  local lo
  lo=$(sudo_run "losetup -f 2>/dev/null")
  [ -n "$lo" ] || return 1
  sudo_run "losetup $lo $SWAPFILE && mkswap $lo >/dev/null 2>&1 && swapon $lo 2>/dev/null"
}

try_zram() {
  sudo_run "[ -e /sys/block/zram0 ] || (modprobe zram 2>/dev/null; [ -e /sys/block/zram0 ])" || return 1
  sudo_run "swapoff /dev/block/zram0 2>/dev/null; echo 1 > /sys/block/zram0/reset 2>/dev/null; echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null; echo ${1}M > /sys/block/zram0/disksize && mkswap /dev/block/zram0 >/dev/null 2>&1 && swapon -p 100 /dev/block/zram0 2>/dev/null"
}

enable_vram() {   # $1 = MB
  local mb=$1 free_mb
  case "$mb" in ''|*[!0-9]*) echo -e "${R}Giá trị không hợp lệ.${N}"; return;; esac

  free_mb=$(sudo_run "df -m /data | tail -n1" | awk '{print $4}')
  if [ -n "$free_mb" ] && [ "$mb" -ge "$free_mb" ]; then
    echo -e "${R}Bộ nhớ trống ($free_mb MB) không đủ cho $mb MB.${N}"
    return
  fi

  remove_vram
  echo -e "${Y}Đang tạo RAM ảo ${mb}MB, vui lòng đợi (có thể mất vài phút)...${N}"

  local method=""
  if try_swapfile "$mb"; then method="swap file (dùng bộ nhớ ROM)"
  elif try_loop; then method="swap qua loop device (dùng bộ nhớ ROM)"
  elif try_zram "$mb"; then method="zram (nén RAM, không dùng ROM)"
  fi

  if [ -z "$method" ]; then
    sudo_run "rm -f $SWAPFILE"
    echo -e "${R}Thất bại: kernel của máy ảo không hỗ trợ swap/zram.${N}"
    return
  fi

  sudo_run "echo 100 > /proc/sys/vm/swappiness 2>/dev/null"
  sudo_run "echo 50 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null"
  echo -e "${G}Đã bật RAM ảo ${mb}MB bằng: $method${N}"
  show_mem
}

menu_vram() {
  banner
  echo -e "${Y}=== CHỌN MỨC RAM ẢO ===${N}"
  echo " 1) Nhẹ        1 GB"
  echo " 2) Vừa        2 GB  [khuyên dùng]"
  echo " 3) Mạnh       3 GB"
  echo " 4) Cực mạnh   4 GB"
  echo " 5) Tuỳ chỉnh (MB)"
  echo " 6) Tắt / xoá RAM ảo"
  echo " 0) Quay lại"
  echo
  read -rp "Chọn: " ch
  case "$ch" in
    1) enable_vram 1024; pause;;
    2) enable_vram 2048; pause;;
    3) enable_vram 3072; pause;;
    4) enable_vram 4096; pause;;
    5) read -rp "Nhập số MB: " mb; enable_vram "$mb"; pause;;
    6) remove_vram; echo -e "${G}Đã tắt và xoá RAM ảo.${N}"; pause;;
    *) ;;
  esac
}

# ---------- DỌN RAM / ANIMATION ----------
clean_ram() {
  sudo_run "sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null"
  sudo_run "am kill-all 2>/dev/null"
  echo -e "${G}Đã dọn cache và tắt các app nền.${N}"
  sudo_run "grep MemAvailable /proc/meminfo"
}

anim_off() {
  sudo_run "settings put global window_animation_scale 0"
  sudo_run "settings put global transition_animation_scale 0"
  sudo_run "settings put global animator_duration_scale 0"
  echo -e "${G}Đã tắt animation hệ thống.${N}"
}

anim_on() {
  sudo_run "settings put global window_animation_scale 1"
  sudo_run "settings put global transition_animation_scale 1"
  sudo_run "settings put global animator_duration_scale 1"
}

restore_all() {
  reset_display
  remove_vram
  anim_on
  echo -e "${G}Đã khôi phục toàn bộ về mặc định.${N}"
}

# ---------- MENU CHÍNH ----------
while true; do
  banner
  echo -e " ${G}[1]${N} Select độ phân giải"
  echo -e " ${G}[2]${N} Select mức RAM ảo"
  echo -e " ${G}[3]${N} Dọn RAM + tắt animation"
  echo -e " ${G}[4]${N} Xem RAM / bộ nhớ"
  echo -e " ${G}[5]${N} Khôi phục tất cả"
  echo -e " ${G}[0]${N} Thoát"
  echo
  read -rp "Chọn: " ch
  case "$ch" in
    1) menu_resolution;;
    2) menu_vram;;
    3) clean_ram; anim_off; pause;;
    4) show_mem; pause;;
    5) restore_all; pause;;
    0) echo -e "${M}Tạm biệt! - imnotminh${N}"; exit 0;;
    *) echo "Lựa chọn không hợp lệ"; sleep 1;;
  esac
done
