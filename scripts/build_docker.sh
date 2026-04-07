#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# build_docker.sh — Сборка Docker образа ROS1 Horizon SLAM
#
# Использование:
#   chmod +x scripts/build_docker.sh
#   ./scripts/build_docker.sh
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[BUILD]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# Проверка Docker
if ! command -v docker &>/dev/null; then
    log_error "Docker не установлен"
    log_info "Запустите: ./scripts/setup.sh --docker"
    exit 1
fi

# Проверка docker compose
if ! docker compose version &>/dev/null; then
    log_error "docker compose v2 не найден"
    log_info "Установите: sudo apt install docker-compose-v2"
    exit 1
fi

log_info "Сборка образа ROS1 Noetic с Livox SDK..."
docker compose build slam

log_info "Сборка образа RViz..."
docker compose build rviz 2>/dev/null || log_warn "RViz образ пропущен (опционально)"

log_ok "Docker образы собраны"

# Показать список образов
echo ""
log_info "Список образов:"
docker images | grep -E "ros1_horizon|REPOSITORY" || true

echo ""
log_info "Для запуска:"
echo -e "  ${YELLOW}./slam.sh runall${NC}"
