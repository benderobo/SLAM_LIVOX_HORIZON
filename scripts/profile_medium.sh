#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# profile_medium.sh — Профиль: СРЕДНЕЕ сканирование (комнаты, этажи)
#
# Диапазон: 1 — 40 м
# Точность: сбалансированная
# Производительность: средняя
#
# Использование:
#   chmod +x scripts/profile_medium.sh
#   ./scripts/profile_medium.sh
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

# Применяем параметры среднего сканирования
python3 - << 'PYTHON'
import yaml
from pathlib import Path

cfg = Path("'''$CFG'''")
data = yaml.safe_load(cfg.read_text())

# ─────────────────────────────────────────────────────
# MEDIUM RANGE — комнаты, этажи, здания
# ─────────────────────────────────────────────────────

# Мёртвая зона — стандартная
data['preprocess']['blind'] = 1.0

# Прореживание — баланс между точностью и нагрузкой
data['preprocess']['point_filter_num'] = 2

# Воксель карты — средний, хороший баланс
data['mapping']['filter_size_map'] = 0.15

# Дальность обнаружения — средняя
data['mapping']['det_range'] = 40

# Поле зрения — умеренное
data['mapping']['fov_degree'] = 70

# Плотная публикация — включена
data['publish']['dense_publish_en'] = True

# Сохранение PCD — стандартный интервал
data['pcd_save']['pcd_save_en'] = True
data['pcd_save']['interval'] = 200

cfg.write_text(yaml.safe_dump(data, sort_keys=False, default_flow_style=False))
print("OK: medium_range profile applied")
PYTHON

log_ok "Профиль СРЕДНЕГО сканирования применён"
echo ""
echo -e "${BLUE}Параметры:${NC}"
echo "  Мёртвая зона:     1.0 м"
echo "  Прореживание:     2"
echo "  Воксель карты:    0.15 м"
echo "  Дальность:        40 м"
echo "  FOV:              70°"
echo "  Интервал PCD:     200"
echo ""
echo -e "${YELLOW}Перезапустите SLAM:${NC}"
echo -e "  ${YELLOW}./slam.sh restart${NC}"
