#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# switch_profile.sh — Переключение профилей сканирования
#
# Использование:
#   ./scripts/switch_profile.sh close    — Ближнее (0.3–15 м, помещение)
#   ./scripts/switch_profile.sh medium  — Среднее (1–40 м, комнаты)
#   ./scripts/switch_profile.sh far     — Дальнее (2–150 м, открытое)
#   ./scripts/switch_profile.sh list    — Список профилей
#   ./scripts/switch_profile.sh current — Текущие параметры
#   ./scripts/switch_profile.sh auto    — Автоперезапуск SLAM
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[PROFILE]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

show_profiles() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Профили сканирования SLAM                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN} close${NC}    — Ближнее    | 0.3–15 м   | Помещения, коридоры, мелкие детали"
    echo -e "${GREEN} medium${NC}   — Среднее    | 1–40 м     | Комнаты, этажи, здания"
    echo -e "${GREEN} far${NC}      — Дальнее    | 2–150 м    | Открытые пространства, улицы"
    echo ""
    echo -e "${BLUE}Использование:${NC}"
    echo "  ./scripts/switch_profile.sh <профиль>"
    echo "  ./scripts/switch_profile.sh <профиль> --restart  (с перезапуском SLAM)"
    echo ""
}

show_current() {
    CFG_CANDIDATES=(
        "$SCRIPTS_DIR/../config/horizon.yaml"
        "/home/pi5/ros1_horizon/ws/catkin_ws/src/fast_lio/config/horizon.yaml"
    )

    CFG=""
    for candidate in "${CFG_CANDIDATES[@]}"; do
        if [[ -f "$candidate" ]]; then
            CFG="$candidate"
            break
        fi
    done

    if [[ -z "$CFG" ]]; then
        log_error "horizon.yaml не найден"
        exit 1
    fi

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           Текущие параметры SLAM                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    python3 - << PYTHON
import yaml
from pathlib import Path

cfg = Path("$CFG")
data = yaml.safe_load(cfg.read_text())

blind = data['preprocess']['blind']
filter_num = data['preprocess']['point_filter_num']
filter_map = data['mapping']['filter_size_map']
det_range = data['mapping']['det_range']
fov = data['mapping']['fov_degree']
dense = data['publish']['dense_publish_en']
pcd_int = data['pcd_save']['interval']

# Определяем профиль
if blind <= 0.5 and det_range <= 20:
    profile = "CLOSE (ближнее)"
elif blind >= 1.5 and det_range >= 100:
    profile = "FAR (дальнее)"
else:
    profile = "MEDIUM (среднее)"

print(f"  Профиль:         {profile}")
print(f"  Мёртвая зона:    {blind} м")
print(f"  Прореживание:    {filter_num}")
print(f"  Воксель карты:   {filter_map} м")
print(f"  Дальность:       {det_range} м")
print(f"  FOV:             {fov}°")
print(f"  Плотная публ.:   {dense}")
print(f"  Интервал PCD:    {pcd_int}")
PYTHON

    echo ""
}

apply_profile() {
    local profile="$1"
    local do_restart="${2:-false}"

    case "$profile" in
        close|medium|far)
            local script="$SCRIPTS_DIR/profile_${profile}.sh"
            if [[ ! -f "$script" ]]; then
                log_error "Скрипт профиля не найден: $script"
                exit 1
            fi
            bash "$script"
            ;;
        *)
            log_error "Неизвестный профиль: $profile"
            echo "Доступные: close, medium, far"
            exit 1
            ;;
    esac

    if [[ "$do_restart" == "true" ]] || [[ "$do_restart" == "--restart" ]]; then
        echo ""
        log_info "Перезапуск SLAM..."
        if command -v slam.sh &>/dev/null; then
            slam.sh restart
        elif [[ -f "$SCRIPTS_DIR/../slam.sh" ]]; then
            bash "$SCRIPTS_DIR/../slam.sh" restart
        elif [[ -f "/home/pi5/slam.sh" ]]; then
            /home/pi5/slam.sh restart
        else
            log_warn "slam.sh не найден, перезапустите вручную"
        fi
    fi
}

###############################################################################
# MAIN
###############################################################################

case "${1:-}" in
    close)
        apply_profile "close" "${2:-}"
        ;;
    medium)
        apply_profile "medium" "${2:-}"
        ;;
    far)
        apply_profile "far" "${2:-}"
        ;;
    list|ls|--list|-l)
        show_profiles
        ;;
    current|show|--current|-c)
        show_current
        ;;
    auto)
        log_info "Автопереключение по расстоянию..."
        echo "  В разработке — определение оптимального профиля по данным лидара"
        ;;
    --help|-h|help)
        show_profiles
        ;;
    *)
        log_error "Укажите профиль: close, medium, far"
        echo ""
        show_profiles
        exit 1
        ;;
esac
