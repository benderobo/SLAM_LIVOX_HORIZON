# 📦 INSTALL.md — Подробная инструкция по установке ROS1 Horizon SLAM

---

## 📋 Оглавление

1. [Требования](#-требования)
2. [Подготовка Raspberry Pi 5](#-подготовка-raspberry-pi-5)
3. [Установка Docker](#-установка-docker)
4. [Настройка SSH ключей](#-настройка-ssh-ключей)
5. [Подключение к GitHub](#-подключение-к-github)
6. [Клонирование репозитория](#-клонирование-репозитория)
7. [Установка Livox SDK](#-установка-livox-sdk)
8. [Сборка Docker образа](#-сборка-docker-образа)
9. [Настройка конфигурации](#-настройка-конфигурации)
10. [Запуск системы](#-запуск-системы)
11. [Node-RED Dashboard](#-node-red-dashboard)
12. [VPN и удалённый доступ](#-vpn-и-удалённый-доступ)
13. [Проверка работоспособности](#-проверка-работоспособности)

---

## ✅ Требования

### Аппаратные

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| Плата | Raspberry Pi 5 (4GB) | Raspberry Pi 5 (8GB) |
| Накопитель | microSD 64GB Class 10 | NVMe SSD 256GB+ |
| LiDAR | Livox Horizon | Livox Horizon + Mid-360 |
| Сеть | Ethernet 1Gbps | Ethernet 1Gbps + Wi-Fi 6 |
| Питание | 5V/3A USB-C | 5V/5A USB-C PD |

### Программные

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| ОС | Ubuntu 24.04 ARM64 | Noble Numbat |
| Docker | 24.0+ | docker.io + docker-compose-v2 |
| ROS | Noetic | Только в контейнере |
| Python | 3.12+ | Для скриптов настройки |
| Git | 2.43+ | Для клонирования репозиториев |

---

## 🛠️ Подготовка Raspberry Pi 5

### 1. Установка Ubuntu 24.04

1. Скачайте образ: https://ubuntu.com/download/raspberry-pi
2. Запишите на microSD/SSD через **Raspberry Pi Imager**:
   ```bash
   # Или через командную строку
   sudo dd if=ubuntu-24.04-preinstalled-server-arm64+raspi.img of=/dev/sdX bs=4M status=progress
   ```
3. Вставьте носитель в Pi 5 и включите питание
4. Пройдите первоначальную настройку (пользователь, сеть, часовой пояс)

### 2. Обновление системы

```bash
# Подключение по SSH или напрямую
ssh pi5@192.168.123.100

# Обновление пакетов
sudo apt update && sudo apt upgrade -y

# Перезагрузка (если требуется)
sudo reboot
```

### 3. Установка базовых зависимостей

```bash
sudo apt install -y \
    git curl wget build-essential cmake pkg-config \
    python3 python3-pip python3-venv python3-yaml \
    net-tools iproute2 jq \
    openssh-server
```

---

## 🐳 Установка Docker

### Вариант 1: Из репозиториев Ubuntu (рекомендуется)

```bash
# Установка
sudo apt install -y docker.io docker-compose-v2

# Добавление пользователя в группу docker (чтобы не использовать sudo)
sudo usermod -aG docker $USER

# Применить группу (или перелогиниться)
newgrp docker

# Проверка
docker --version
docker compose version

# Тест
docker run hello-world
```

### Вариант 2: Официальный репозиторий Docker

```bash
# Добавление ключа
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Добавление репозитория
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Добавление пользователя
sudo usermod -aG docker $USER
newgrp docker
```

### Проверка Docker

```bash
# Информация о Docker
docker info

# Список образов
docker images

# Список контейнеров
docker ps -a

# docker compose
docker compose version
```

---

## 🔑 Настройка SSH ключей

### 1. Генерация ключа

```bash
# Создание SSH ключа Ed25519
ssh-keygen -t ed25519 -C "pi5-robot-$(date +%Y%m%d)"

# Нажмите Enter для сохранения в ~/.ssh/id_ed25519
# Можно оставить passphrase пустым для автоматизации
```

### 2. Добавление в authorized_keys (локальный доступ)

```bash
# Добавить публичный ключ в авторизованные
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

# Проверка прав
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### 3. Добавление на GitHub

1. Скопируйте публичный ключ:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

2. Перейдите на GitHub: https://github.com/settings/keys

3. Нажмите **New SSH key**

4. Вставьте ключ и дайте название (например, "Pi 5 Robot")

5. Сохраните

### 4. Копирование на другие сервера

```bash
# Автоматически
ssh-copy-id user@remote-server

# Вручную
ssh user@remote-server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/id_ed25519.pub
```

### 5. SSH Config (опционально)

Создайте `~/.ssh/config`:

```
# Raspberry Pi 5
Host pi5
    HostName 192.168.123.100
    User pi5
    Port 22
    IdentityFile ~/.ssh/id_ed25519

# Livox LiDAR
Host livox
    HostName 192.168.123.51
    Port 8080
```

Теперь можно подключаться просто: `ssh pi5`

---

## 🐙 Подключение к GitHub

### 1. Настройка Git

```bash
# Глобальная конфигурация
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Проверка
git config --global --list
```

### 2. Тест подключения к GitHub

```bash
ssh -T git@github.com

# Должно вывести:
# Hi YOUR_USERNAME! You've successfully authenticated, but GitHub does not provide shell access.
```

### 3. Создание репозитория

1. Перейдите на https://github.com/new
2. Создайте репозиторий `ros1-horizon-slam`
3. **Не** инициализируйте с README (у нас уже есть)

---

## 📥 Клонирование репозитория

### 1. Клонирование основного проекта

```bash
# По SSH (рекомендуется)
git clone git@github.com:YOUR_USERNAME/ros1-horizon-slam.git
cd ros1-horizon-slam

# Или по HTTPS
git clone https://github.com/YOUR_USERNAME/ros1-horizon-slam.git
cd ros1-horizon-slam
```

### 2. Инициализация сабмодулей

```bash
# Клонирование FAST-LIO2
mkdir -p ws/catkin_ws/src
git clone https://github.com/hku-mars/FAST_LIO.git ws/catkin_ws/src/fast_lio

# Клонирование Livox ROS Driver
git clone https://github.com/Livox-SDK/livox_ros_driver.git ws/catkin_ws/src/livox_ros_driver
```

### 3. Проверка структуры

```bash
tree -L 3 -d
# Должно показать:
# ├── config/
# ├── launch/
# ├── scripts/
# └── ws/
#     └── catkin_ws/
#         └── src/
#             ├── fast_lio/
#             └── livox_ros_driver/
```

---

## 📡 Установка Livox SDK

### Внутри Docker контейнера (автоматически)

Livox SDK2 устанавливается автоматически при сборке Docker образа:

```dockerfile
# В Dockerfile:
WORKDIR /opt
RUN git clone --recursive https://github.com/Livox-SDK/Livox-SDK2.git \
 && cd Livox-SDK2 \
 && mkdir -p build && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && make -j$(nproc) \
 && make install \
 && ldconfig
```

### На хост-машине (опционально)

Если нужно на хосте:

```bash
# Зависимости
sudo apt install -y cmake build-essential git

# Клонирование
cd /opt
sudo git clone --recursive https://github.com/Livox-SDK/Livox-SDK2.git
cd Livox-SDK2

# Сборка
mkdir -p build && cd build
sudo cmake .. -DCMAKE_BUILD_TYPE=Release
sudo make -j$(nproc)
sudo make install
sudo ldconfig

# Проверка
ls -la /usr/local/lib/liblivox_sdk*
```

---

## 🐳 Сборка Docker образа

### 1. Подготовка

```bash
cd ros1-horizon-slam

# Проверка файлов
ls -la Dockerfile docker-compose.yml
```

### 2. Сборка

```bash
# Через docker compose (рекомендуется)
docker compose build slam

# Или полный билд со всеми сервисами
docker compose build

# Без кэша (чистая сборка)
docker compose build --no-cache
```

### 3. Проверка образа

```bash
# Список образов
docker images | grep ros1_horizon

# Тест запуска
docker run --rm ros1_horizon-ros1_noetic:latest bash -c "
  source /opt/ros/noetic/setup.bash
  rosversion -d
"
# Должно вывести: noetic
```

### 4. RViz образ (опционально)

```bash
# Сборка образа с RViz
docker compose build rviz
```

---

## ⚙️ Настройка конфигурации

### 1. Livox LiDAR конфиг

```bash
# Копирование шаблона
cp config/livox_lidar_config.json.example config/livox_lidar_config.json

# Редактирование
nano config/livox_lidar_config.json
```

Заполните реальные значения:

```json
{
  "lidar_config": [
    {
      "broadcast_code": "3WEDH5900101971",  ← ЗАМЕНИТЕ на ваш
      "enable_connect": true,
      "host_ip": "192.168.123.100",         ← IP Raspberry Pi
      "lidar_ip": "192.168.123.51"          ← IP Livox Horizon
    }
  ]
}
```

> ⚠️ **Где найти broadcast_code?**
> - На наклейке на корпусе лидара
> - В приложении Livox Viewer
> - Формат: `XXXXXXXXXXXXXXX` (15 символов)

### 2. Horizon YAML

```bash
# Копирование шаблона
cp config/horizon.yaml.example config/horizon.yaml

# Редактирование
nano config/horizon.yaml
```

Основные параметры для настройки:

| Параметр | Описание | Рекомендуемое |
|----------|----------|---------------|
| `blind` | Мёртвая зона (м) | 1.0 |
| `point_filter_num` | Прореживание | 2-3 |
| `filter_size_map` | Воксель карты | 0.15-0.5 |
| `det_range` | Дальность (м) | 100 |
| `dense_publish_en` | Плотная публикация | true |
| `pcd_save_en` | Сохранение PCD | true |

### 3. Динамическая настройка

```bash
# Изменение параметров без редактирования YAML
python3 scripts/set_param.py blind 1.5
python3 scripts/set_param.py dense_publish_en true
python3 scripts/set_param.py filter_size_map 0.2
```

---

## 🚀 Запуск системы

### Быстрый старт

```bash
# Запуск всего стека
./slam.sh runall
```

### Пошаговый запуск

```bash
# 1. Запуск SLAM контейнера
./slam.sh up

# 2. Проверка контейнера
docker ps

# 3. Запуск драйвера Livox (в фоне)
./slam.sh driver bg

# 4. Запуск ROS Bridge (WebSocket :9090)
./slam.sh bridge bg

# 5. Проверка ROS
./slam.sh check
```

### Проверка ROS топиков

```bash
# Вход в контейнер
docker exec -it ros1_noetic_horizon bash -lc "
  source /opt/ros/noetic/setup.bash
  source /ws/catkin_ws/devel/setup.bash
  
  # Список нод
  rosnode list
  
  # Список топиков
  rostopic list
  
  # Частота лидара
  rostopic hz /livox/lidar
  
  # Частота карты
  rostopic hz /cloud_registered
"
```

### Сохранение карты

```bash
# Сохранение в PCD
./slam.sh save

# Файлы появятся в ws/maps/
ls -la ws/maps/
```

### Остановка

```bash
# Остановка стека
./slam.sh down

# Или полная остановка + удаление
docker compose down --remove-orphans
```

---

## 🎛️ Node-RED Dashboard

### 1. Установка Node-RED

```bash
# Установка Node.js (если нет)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Установка Node-RED
sudo npm install -g --unsafe-perm node-red

# Автозапуск
sudo systemctl enable nodered
sudo systemctl start nodered
```

### 2. Установка плагинов

```bash
cd ~/.node-red
npm install node-red-dashboard @background404/node-red-contrib-llm-plugin

# Перезапуск
sudo systemctl restart nodered
```

### 3. Доступ

| URL | Описание |
|-----|----------|
| `http://192.168.123.100:1880` | Редактор флоу |
| `http://192.168.123.100:1880/ui` | Dashboard UI |

---

## 🔐 VPN и удалённый доступ

### Tailscale (рекомендуется)

```bash
# Установка
curl -fsSL https://tailscale.com/install.sh | sh

# Авторизация
sudo tailscale up

# Проверка
tailscale status
ip addr show tailscale0
```

Теперь Pi 5 доступен по адресу Tailscale из любой точки мира.

### WireGuard

```bash
# Установка
sudo apt install -y wireguard

# Настройка
sudo cp vpn_conf/amnezia_for_wireguard.conf /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Проверка
sudo wg show
```

### Wi-Fi точка доступа

```bash
# Создание собственной сети
sudo ./scripts/wifi_mode.sh ap

# Подключение к существующей сети
sudo ./scripts/wifi_mode.sh client

# Автоматический режим
sudo ./scripts/wifi_mode.sh auto
```

---

## ✅ Проверка работоспособности

### Чеклист

- [ ] Docker работает: `docker ps`
- [ ] Контейнер запущен: `docker ps | grep ros1_noetic_horizon`
- [ ] ROS Master доступен: `docker exec ros1_noetic_horizon bash -lc "source /opt/ros/noetic/setup.bash && rosnode list"`
- [ ] Livox подключён: проверить логи `docker logs ros1_noetic_horizon`
- [ ] Топики публикуются: `rostopic hz /livox/lidar`
- [ ] SLAM работает: `rostopic hz /Laser_map`
- [ ] ROS Bridge работает: `curl http://192.168.123.100:9090`
- [ ] Node-RED доступен: `curl http://192.168.123.100:1880`

### Скрипт проверки

```bash
#!/usr/bin/env bash
echo "=== Docker ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"

echo ""
echo "=== ROS Nodes ==="
docker exec ros1_noetic_horizon bash -lc "
  source /opt/ros/noetic/setup.bash
  source /ws/catkin_ws/devel/setup.bash
  rosnode list
" 2>/dev/null || echo "ROS не запущен"

echo ""
echo "=== ROS Topics ==="
docker exec ros1_noetic_horizon bash -lc "
  source /opt/ros/noetic/setup.bash
  source /ws/catkin_ws/devel/setup.bash
  rostopic list
" 2>/dev/null || echo "Топики недоступны"

echo ""
echo "=== Ports ==="
ss -lntp | grep -E '9090|11311|1880|8000' || echo "Порты не слушают"
```

---

## 🆘 Решение проблем

### Docker не запускается

```bash
sudo systemctl restart docker
sudo systemctl status docker
```

### Livox не подключается

1. Проверьте IP: `ping 192.168.123.51`
2. Проверьте broadcast_code в конфиге
3. Перезапустите драйвер: `./slam.sh driver bg`

### SLAM не строит карту

1. Проверьте топики: `rostopic hz /livox/lidar`
2. Проверьте конфиг: `cat config/horizon.yaml`
3. Перезапустите: `./slam.sh restart`

---

<div align="center">

**Для дополнительных вопросов см. [README.md](README.md) и [CONTRIBUTING.md](CONTRIBUTING.md)**

</div>
