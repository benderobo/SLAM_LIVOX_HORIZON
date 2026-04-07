#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# profile_close.sh — Профиль: БЛИЖНЕЕ сканирование (помещение, коридоры)
#
# Диапазон: 0.5 — 15 м
# Точность: максимальная
# Производительность: высокая (меньше точек для обработки)
#
# Использование:
#   chmod +x scripts/profile_close.sh
#   ./scripts/profile_close.sh
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

# Применяем параметры ближнего сканирования
python3 - << 'PYTHON'
import yaml
from pathlib import Path
import sys

cfg = Path("'''$CFG'''")
data = yaml.safe_load(cfg.read_text())

# ─────────────────────────────────────────────────────
# CLOSE RANGE — помещение, коридоры, мелкие объекты
# ─────────────────────────────────────────────────────

# Мёртвая зона — минимальная, видим всё рядом
data['preprocess']['blind'] = 0.3

# Прореживание — меньше, больше точек для точности
data['preprocess']['point_filter_num'] = 1

# Воксель карты — мелкий, высокая детализация
data['mapping']['filter_size_map'] = 0.05

# Дальность обнаружения — ограничена для помещения
data['mapping']['det_range'] = 15

# Поле зрения — шире для близких стен
data['mapping']['fov_degree'] = 90

# Плотная публикация — включена для детальной карты
data['publish']['dense_publish_en'] = True

# Сохранение PCD — чаще для мелких деталей
data['pcd_save']['pcd_save_en'] = True
data['pcd_save']['interval'] = 50

cfg.write_text(yaml.safe_dump(data, sort_keys=False, default_flow_style=False))
print("OK: close_range profile applied")
PYTHON

log_ok "Профиль БЛИЖНЕГО сканирования применён"
echo ""
echo -e "${BLUE}Параметры:${NC}"
echo "  Мёртвая зона:     0.3 м  (было 1.0)"
echo "  Прореживание:     1      (было 2)"
echo "  Воксель карты:    0.05 м (было 0.15)"
echo "  Дальность:        15 м   (было 100)"
echo "  FOV:              90°    (было 50°)"
echo "  Интервал PCD:     50     (было 200)"
echo ""
echo -e "${YELLOW}Перезапустите SLAM:${NC}"
echo -e "  ${YELLOW}./slam.sh restart${NC}"
