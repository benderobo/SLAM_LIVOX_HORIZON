#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup.sh — Полный скрипт установки ROS1 Horizon SLAM на Raspberry Pi 5
#
# Использование:
#   chmod +x setup.sh
#   ./setup.sh              # полная установка
#   ./setup.sh --docker     # только Docker
#   ./setup.sh --ssh        # только SSH ключи
#   ./setup.sh --repos      # только клонирование репозиториев
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка архитектуры
check_architecture() {
    log_info "Проверка архитектуры..."
    ARCH=$(uname -m)
    if [[ "$ARCH" != "aarch64" ]]; then
        log_warn "Архитектура: $ARCH (рекомендуется aarch64 для Raspberry Pi 5)"
    else
        log_ok "Архитектура: aarch64 ✅"
    fi
}

# Обновление системы
update_system() {
    log_info "Обновление системы..."
    sudo apt update -y
    sudo apt upgrade -y
    log_ok "Система обновлена"
}

# Установка базовых зависимостей
install_base_deps() {
    log_info "Установка базовых зависимостей..."
    sudo apt install -y \
        git curl wget build-essential cmake pkg-config \
        python3 python3-pip python3-venv python3-yaml \
        net-tools iproute2 \
        jq
    log_ok "Базовые зависимости установлены"
}

# Установка Docker
install_docker() {
    if command -v docker &>/dev/null; then
        log_ok "Docker уже установлен: $(docker --version)"
        return
    fi

    log_info "Установка Docker..."
    sudo apt install -y docker.io docker-compose-v2
    sudo usermod -aG docker "$USER"
    log_ok "Docker установлен: $(docker --version)"
    log_warn "Перезагрузите систему или выполните: newgrp docker"
}

# Настройка SSH ключей
setup_ssh_keys() {
    if [[ -f ~/.ssh/id_ed25519 ]]; then
        log_ok "SSH ключ уже существует: ~/.ssh/id_ed25519"
        return
    fi

    log_info "Генерация SSH ключа..."
    ssh-keygen -t ed25519 -C "pi5-robot-$(date +%Y%m%d)" -f ~/.ssh/id_ed25519 -N ""

    log_info "Добавление ключа в authorized_keys..."
    cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh

    log_ok "SSH ключ создан: ~/.ssh/id_ed25519"
    log_info "Публичный ключ для добавления на другие сервера:"
    cat ~/.ssh/id_ed25519.pub
}

# Клонирование репозиториев
clone_repositories() {
    local PROJECT_DIR="${1:-.}"

    log_info "Клонирование сабмодулей (FAST-LIO2 + Livox Driver)..."
    
    # FAST-LIO2
    if [[ ! -d "$PROJECT_DIR/ws/catkin_ws/src/fast_lio/.git" ]]; then
        log_info "Клонирование FAST-LIO2..."
        mkdir -p "$PROJECT_DIR/ws/catkin_ws/src"
        git clone https://github.com/hku-mars/FAST_LIO.git "$PROJECT_DIR/ws/catkin_ws/src/fast_lio"
        log_ok "FAST-LIO2 клонирован"
    else
        log_ok "FAST-LIO2 уже существует"
    fi

    # Livox ROS Driver
    if [[ ! -d "$PROJECT_DIR/ws/catkin_ws/src/livox_ros_driver/.git" ]]; then
        log_info "Клонирование Livox ROS Driver..."
        git clone https://github.com/Livox-SDK/livox_ros_driver.git "$PROJECT_DIR/ws/catkin_ws/src/livox_ros_driver"
        log_ok "Livox ROS Driver клонирован"
    else
        log_ok "Livox ROS Driver уже существует"
    fi
}

# Настройка конфигов
setup_configs() {
    log_info "Настройка конфигураций..."

    # Livox конфиг
    if [[ ! -f config/livox_lidar_config.json ]]; then
        cat > config/livox_lidar_config.json << 'EOF'
{
  "lidar_config": [
    {
      "broadcast_code": "YOUR_BROADCAST_CODE_HERE",
      "enable_connect": true,
      "host_ip": "192.168.123.100",
      "lidar_ip": "192.168.123.51"
    }
  ]
}
EOF
        log_warn "Отредактируйте config/livox_lidar_config.json и укажите ваш broadcast_code"
    fi

    # Horizon YAML
    if [[ ! -f config/horizon.yaml ]]; then
        cat > config/horizon.yaml << 'EOF'
common:
  lid_topic: /livox/lidar
  imu_topic: /livox/imu
  time_sync_en: true
  time_offset_lidar_to_imu: 0.0
preprocess:
  lidar_type: 1
  scan_line: 6
  blind: 1.0
  point_filter_num: 2
mapping:
  filter_size_map: 0.15
  acc_cov: 0.1
  gyr_cov: 0.01
  b_acc_cov: 0.0001
  b_gyr_cov: 0.0001
  fov_degree: 50
  det_range: 100
  extrinsic_est_en: false
  extrinsic_T:
  - 0
  - 0
  - 0
  extrinsic_R:
  - 1
  - 0
  - 0
  - 0
  - 1
  - 0
  - 0
  - 0
  - 1
publish:
  path_en: true
  scan_publish_en: true
  dense_publish_en: true
  scan_bodyframe_pub_en: true
pcd_save:
  pcd_save_en: true
  interval: 200
EOF
        log_ok "config/horizon.yaml создан"
    fi
}

# Сборка Docker образа
build_docker() {
    log_info "Сборка Docker образа ROS1 Noetic..."
    docker compose build
    log_ok "Docker образ собран"
}

# Настройка Node-RED
setup_node_red() {
    log_info "Настройка Node-RED..."
    
    if command -v node &>/dev/null; then
        if [[ -d ~/.node-red ]]; then
            cd ~/.node-red
            npm install node-red-dashboard @background404/node-red-contrib-llm-plugin
            log_ok "Node-RED плагины установлены"
        else
            log_warn "Node-RED не установлен, пропуск..."
        fi
    else
        log_warn "Node.js не найден, пропуск Node-RED..."
    fi
}

# Настройка Tailscale (опционально)
setup_tailscale() {
    log_info "Настройка Tailscale..."
    
    if command -v tailscale &>/dev/null; then
        log_ok "Tailscale уже установлен"
        return
    fi

    read -p "Установить Tailscale для удалённого доступа? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo tailscale up
        log_ok "Tailscale установлен"
    else
        log_info "Пропуск Tailscale"
    fi
}

# Финальная информация
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ Установка завершена успешно!                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Следующие шаги:${NC}"
    echo ""
    echo "  1. Отредактируйте config/livox_lidar_config.json"
    echo "     Укажите ваш broadcast_code с наклейки лидара"
    echo ""
    echo "  2. Запустите SLAM:"
    echo -e "     ${YELLOW}./slam.sh runall${NC}"
    echo ""
    echo "  3. Проверьте состояние:"
    echo -e "     ${YELLOW}./slam.sh check${NC}"
    echo ""
    echo "  4. Визуализация в RViz (на хост-машине):"
    echo -e "     ${YELLOW}./rviz_horizon.sh${NC}"
    echo ""
    echo -e "${BLUE}Документация:${NC}"
    echo "  • README.md — полное описание проекта"
    echo "  • INSTALL.md — подробная инструкция по установке"
    echo "  • https://github.com/YOUR_USERNAME/ros1-horizon-slam"
    echo ""
}

###############################################################################
# MAIN
###############################################################################

main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     ROS1 Horizon SLAM — Установка на Raspberry Pi 5     ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    case "${1:-}" in
        --docker)
            install_docker
            build_docker
            ;;
        --ssh)
            setup_ssh_keys
            ;;
        --repos)
            clone_repositories
            ;;
        --node-red)
            setup_node_red
            ;;
        --tailscale)
            setup_tailscale
            ;;
        --help|-h)
            echo "Использование: $0 [опция]"
            echo ""
            echo "Опции:"
            echo "  --docker      Только Docker"
            echo "  --ssh         Только SSH ключи"
            echo "  --repos       Только клонирование репозиториев"
            echo "  --node-red    Только Node-RED"
            echo "  --tailscale   Только Tailscale"
            echo "  --help, -h    Показать эту справку"
            echo ""
            echo "Без опций — полная установка"
            ;;
        *)
            check_architecture
            update_system
            install_base_deps
            install_docker
            setup_ssh_keys
            clone_repositories
            setup_configs
            build_docker
            setup_node_red
            setup_tailscale
            print_summary
            ;;
    esac
}

main "$@"
