#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# profile_far.sh — Профиль: ДАЛЬНЕЕ сканирование (открытые пространства)
#
# Диапазон: 2 — 150 м (максимум Livox Horizon)
# Точность: снижена (дальние точки шумнее)
# Производительность: экономная (меньше точек)
#
# Использование:
#   chmod +x scripts/profile_far.sh
#   ./scripts/profile_far.sh
#   # затем перезапустить SLAM: ./slam.sh restart
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[PROFILE]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Пути к конфигам
CFG_CANDIDATES=(
    "$(cd "$(dirname "$0")/.." && pwd)/config/horizon.yaml"
    "/home/pi5/ros1_horizon/ws/catkin_ws/src/fast_lio/config/horizon.yaml"
)

find_config() {
    for candidate in "${CFG_CANDIDATES[@]}"; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done
    log_error "horizon.yaml не найден"
    exit 1
}

CFG=$(find_config)

# Резервная копия
cp "$CFG" "${CFG}.bak"
log_info "Резервная копия: ${CFG}.bak"

# Применяем параметры дальнего сканирования
python3 - << 'PYTHON'
import yaml
from pathlib import Path

cfg = Path("'''$CFG'''")
data = yaml.safe_load(cfg.read_text())

# ─────────────────────────────────────────────────────
# FAR RANGE — открытые пространства, улицы, поля
# ─────────────────────────────────────────────────────

# Мёртвая зона — больше, игнорируем ближайший шум
data['preprocess']['blind'] = 2.0

# Прореживание — выше, меньше точек для нагрузки
data['preprocess']['point_filter_num'] = 4

# Воксель карты — крупный, общая картина
data['mapping']['filter_size_map'] = 0.5

# Дальность обнаружения — максимум
data['mapping']['det_range'] = 150

# Поле зрения — уже, фокус вдаль
data['mapping']['fov_degree'] = 50

# Плотная публикация — выключена для экономии
data['publish']['dense_publish_en'] = False

# Сохранение PCD — реже, большие chunks
data['pcd_save']['pcd_save_en'] = True
data['pcd_save']['interval'] = 500

cfg.write_text(yaml.safe_dump(data, sort_keys=False, default_flow_style=False))
print("OK: far_range profile applied")
PYTHON

log_ok "Профиль ДАЛЬНЕГО сканирования применён"
echo ""
echo -e "${BLUE}Параметры:${NC}"
echo "  Мёртвая зона:     2.0 м  (было 1.0)"
echo "  Прореживание:     4      (было 2)"
echo "  Воксель карты:    0.5 м  (было 0.15)"
echo "  Дальность:        150 м  (было 100)"
echo "  FOV:              50°    (было 50°)"
echo "  Плотная публика:  False  (было True)"
echo "  Интервал PCD:     500    (было 200)"
echo ""
echo -e "${YELLOW}Перезапустите SLAM:${NC}"
echo -e "  ${YELLOW}./slam.sh restart${NC}"
