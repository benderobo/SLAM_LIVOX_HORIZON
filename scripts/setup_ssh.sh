#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup_ssh.sh — Настройка SSH ключей и подключение к удалённым серверам
#
# Использование:
#   chmod +x scripts/setup_ssh.sh
#   ./scripts/setup_ssh.sh
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[SSH]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_ed25519"

# Создание директории SSH
setup_ssh_dir() {
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    log_ok "Директория ~/.ssh создана"
}

# Генерация SSH ключа
generate_key() {
    if [[ -f "$KEY_FILE" ]]; then
        log_warn "SSH ключ уже существует: $KEY_FILE"
        read -p "Пересоздать? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    log_info "Генерация Ed25519 ключа..."
    ssh-keygen -t ed25519 -C "pi5-robot-$(date +%Y%m%d)" -f "$KEY_FILE" -N ""
    chmod 600 "$KEY_FILE"
    chmod 644 "$KEY_FILE.pub"
    log_ok "Ключ создан: $KEY_FILE"
}

# Добавление в authorized_keys (для локального доступа)
setup_authorized_keys() {
    AUTH_FILE="$SSH_DIR/authorized_keys"

    if [[ -f "$KEY_FILE.pub" ]]; then
        PUB_KEY=$(cat "$KEY_FILE.pub")

        if [[ -f "$AUTH_FILE" ]] && grep -q "$PUB_KEY" "$AUTH_FILE"; then
            log_ok "Ключ уже есть в authorized_keys"
        else
            log_info "Добавление ключа в authorized_keys..."
            echo "$PUB_KEY" >> "$AUTH_FILE"
            chmod 600 "$AUTH_FILE"
            log_ok "Ключ добавлен в authorized_keys"
        fi
    fi
}

# Копирование ключа на удалённый сервер
copy_to_remote() {
    read -p "Скопировать ключ на удалённый сервер? (y/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi

    read -p "IP адрес сервера (например 192.168.123.100): " REMOTE_IP
    read -p "Имя пользователя (например pi5): " REMOTE_USER

    if [[ -z "$REMOTE_IP" || -z "$REMOTE_USER" ]]; then
        log_error "IP и пользователь обязательны"
        return
    fi

    log_info "Копирование ключа на $REMOTE_USER@$REMOTE_IP..."
    ssh-copy-id -i "$KEY_FILE.pub" "$REMOTE_USER@$REMOTE_IP"
    log_ok "Ключ скопирован"

    # Проверка подключения
    log_info "Проверка подключения..."
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "echo 'Подключение успешно!'" 2>/dev/null; then
        log_ok "SSH подключение работает"
    else
        log_warn "Проверьте SSH сервер на $REMOTE_IP"
    fi
}

# Настройка SSH config
setup_ssh_config() {
    CONFIG_FILE="$SSH_DIR/config"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "Создание SSH config..."
        cat > "$CONFIG_FILE" << 'EOF'
# Raspberry Pi 5 — ROS1 Horizon SLAM
Host pi5
    HostName 192.168.123.100
    User pi5
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# Livox LiDAR
Host livox
    HostName 192.168.123.51
    Port 8080
EOF
        chmod 600 "$CONFIG_FILE"
        log_ok "SSH config создан: $CONFIG_FILE"
    else
        log_warn "SSH config уже существует"
    fi
}

# Информация о ключе
show_key_info() {
    if [[ -f "$KEY_FILE.pub" ]]; then
        echo ""
        log_info "Публичный ключ (для добавления на GitHub и другие сервера):"
        echo ""
        cat "$KEY_FILE.pub"
        echo ""
        log_info "Для добавления на GitHub:"
        echo "  1. Скопируйте ключ выше"
        echo "  2. Перейдите: https://github.com/settings/keys"
        echo "  3. Нажмите: New SSH key"
        echo "  4. Вставьте ключ и сохраните"
        echo ""
    fi
}

###############################################################################
# MAIN
###############################################################################

main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Настройка SSH ключей и подключений              ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    setup_ssh_dir
    generate_key
    setup_authorized_keys
    setup_ssh_config
    show_key_info
    copy_to_remote

    echo ""
    log_ok "Настройка SSH завершена"
}

main "$@"
