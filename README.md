# 🤖 ROS1 Horizon SLAM — Raspberry Pi 5 Robotics Platform

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║    ███████╗███╗   ███╗ █████╗ ██████╗ ████████╗███████╗      ║
║    ██╔════╝████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝      ║
║    ███████╗██╔████╔██║███████║██████╔╝   ██║   █████╗        ║
║    ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗   ██║   ██╔══╝        ║
║    ███████║██║ ╚═╝ ██║██║  ██║██║  ██║   ██║   ███████╗      ║
║    ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝      ║
║                                                              ║
║    S███╗   ██╗██╗████████╗ ██████╗  ██████╗                  ║
║    ██╔══██╗██║╚══██╔══╝██╔═══██╗██╔═══██╗                     ║
║    ███████║██║   ██║   ██║   ██║██║   ██║                     ║
║    ██╔══██║██║   ██║   ██║   ██║██║   ██║                     ║
║    ██║  ██║██║   ██║   ╚██████╔╝╚██████╔╝                     ║
║    ╚═╝  ╚═╝╚═╝   ╚═╝    ╚═════╝  ╚═════╝                      ║
║                                                              ║
║         LIDAR + SLAM + ROS1 NOETIC + DOCKER                  ║
╚══════════════════════════════════════════════════════════════╝
```

<div align="center">

**Полноценная робототехническая платформа для 3D-сканирования и SLAM на базе Livox Horizon**

[![Version](https://img.shields.io/badge/version-1.0.0-00ff41.svg)]()
[![Platform](https://img.shields.io/badge/platform-Raspberry%20Pi%205-00a8ff.svg)]()
[![ROS](https://img.shields.io/badge/ROS-Noetic-22314e.svg)]()
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ed.svg)]()
[![LiDAR](https://img.shields.io/badge/LiDAR-Livox%20Horizon-c0392b.svg)]()
[![Python](https://img.shields.io/badge/Python-3.12-3776AB.svg)]()
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420.svg)]()

[Обзор](#-обзор) • [Архитектура](#-архитектура) • [Установка](#-установка) • [Настройка](#-настройка) • [Запуск](#-запуск) • [Компоненты](#-компоненты) • [Node-RED](#-node-red-dashboard) • [VPN](#-vpn-и-удалённый-доступ) • [Troubleshooting](#-troubleshooting) • [Changelog](CHANGELOG.md) • [Безопасность](SECURITY.md)

</div>

---

## 📋 Обзор

**ROS1 Horizon SLAM** — это комплексное решение для развёртывания системы одновременной локализации и картографирования (SLAM) на Raspberry Pi 5 с использованием лидара **Livox Horizon**.

### Возможности

| Категория | Описание |
|-----------|----------|
| 🗺️ **SLAM** | FAST-LIO2 — высокоскоростной 3D SLAM для нелинейных лидаров |
| 📡 **LiDAR** | Livox Horizon — 6 линий, до 260k точек/сек, угол обзора 70.4°×77.2° |
| 🐳 **Docker** | Контейнеризация ROS1 Noetic с автоматическим развёртыванием |
| 🌐 **ROS Bridge** | WebSocket мост для интеграции с веб-приложениями и Node-RED | DONT WORK
| 🎛️ **Node-RED** | Визуальная автоматизация и дашборд управления |
| 🔧 **Тюнинг** | Python/YAML утилиты для динамической настройки параметров SLAM |
| 📦 **PCD** | Сохранение и обработка облаков точек в формате PCD |
| 🔒 **VPN** | Amnezia/WireGuard/Xray для удалённого доступа |You`r config!!!!
| 📶 **Wi-Fi** | Автоматическое переключение AP/Client режимов |

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Raspberry Pi 5 (Ubuntu 24.04)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Docker: ros1_noetic_horizon                     │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────────┐  │   │
│  │  │  roscore    │  │ Livox ROS    │  │   FAST-LIO2       │  │   │
│  │  │  :11311     │◄─┤ Driver       │◄─┤   SLAM Node       │  │   │
│  │  │             │  │ livox_lidar  │  │   laserMapping    │  │   │
│  │  └──────┬──────┘  └──────┬───────┘  └────────┬──────────┘  │   │
│  │         │                │                    │              │   │
│  │         │         ┌──────▼───────┐   ┌───────▼──────────┐  │   │
│  │         │         │ /livox/lidar │   │ /Laser_map       │  │   │
│  │         │         │ /livox/imu   │   │ /Odometry        │  │   │
│  │         │         │              │   │ /cloud_registered│  │   │
│  │         │         │              │   │ /path            │  │   │
│  │         └─────────┴──────────────┴───┴──────────────────┘  │   │
│  │                            ROS Topics                        │   │
│  └────────────────────────────────┬────────────────────────────┘   │
│                                   │                                 │
│  ┌────────────────────────────────┼────────────────────────────┐   │
│  │         ROS Bridge             │                            │   │
│  │    websocket :9090 ◄───────────┘                            │   │
│  └─────────────────────────────┬───────────────────────────────┘   │
│                                │                                     │
│  ┌─────────────────────────────▼───────────────────────────────┐   │
│  │                    Node-RED :1880                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │   │
│  │  │  Dashboard   │  │   Flow       │  │  LLM Plugin     │  │   │
│  │  │  UI Control  │  │  Automation  │  │  Integration    │  │   │
│  │  └──────────────┘  └──────────────┘  └─────────────────┘  │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              TheBigBrother (OSINT) :8000                     │   │
│  │              Docker: thebigbrother_the-big-brother           │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│  Внешние устройства:                                                │
│  • Livox Horizon LiDAR → 192.168.123.51                            │
│  • RViz (визуализация) → отдельный контейнер с X11                 │
└─────────────────────────────────────────────────────────────────────┘
```

### ROS Топики

| Топик | Тип | Описание |
|-------|-----|----------|
| `/livox/lidar` | sensor_msgs/PointCloud2 | Данные лидара |
| `/livox/imu` | sensor_msgs/Imu | Данные IMU |
| `/Laser_map` | sensor_msgs/PointCloud2 | Карта SLAM |
| `/Odometry` | nav_msgs/Odometry | Однометрия |
| `/cloud_registered` | sensor_msgs/PointCloud2 | Зарегистрированное облако |
| `/path` | nav_msgs/Path | Траектория движения |

---

## 🖥️ Системные требования

| Компонент | Минимальные | Рекомендуемые |
|-----------|-------------|---------------|
| **Плата** | Raspberry Pi 5 (8GB) | Raspberry Pi 5 (8GB) |
| **Накопитель** | microSD 64GB | NVMe SSD 256GB+ |
| **ОС** | Ubuntu 24.04 ARM64 | Ubuntu 24.04 ARM64 |
| **LiDAR** | Livox Horizon | Livox Horizon |
| **Сеть** | Ethernet 1Gbps | Ethernet 1Gbps + Wi-Fi 6 |

### Текущая конфигурация (Pi 5)

```
CPU: Cortex-A76 (4 ядра) @ 2.4 GHz
RAM: 8 GB
OS: Ubuntu 24.04.4 LTS (Noble Numbat)
Kernel: 6.8.0-1048-raspi
Disk: 64 GB (mmcblk0p2)
Docker: 5 контейнеров (~27 GB)
```

---

## 📦 Установка

### Шаг 1: Подготовка Raspberry Pi 5

```bash
# 1. Прошиваем Ubuntu 24.04 ARM64
# https://ubuntu.com/download/raspberry-pi

# 2. Обновляем систему
sudo apt update && sudo apt upgrade -y

# 3. Устанавливаем базовые зависимости
sudo apt install -y git curl wget build-essential cmake pkg-config
```

### Шаг 2: Установка Docker

```bash
# Добавляем репозиторий Docker
sudo apt install -y docker.io docker-compose-v2

# Добавляем пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Проверяем
docker --version
docker compose version
```

### Шаг 3: Настройка SSH ключей

```bash
# Генерируем SSH ключ (если нет)
ssh-keygen -t ed25519 -C "pi5-robot"

# Копируем на удалённые сервера
ssh-copy-id user@remote-host

# Или добавляем вручную
cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### Шаг 4: Клонирование репозитория

```bash
# Клонируем основной проект
git clone https://github.com/YOUR_USERNAME/ros1-horizon-slam.git
cd ros1-horizon-slam

# Клонируем сабмодули (FAST-LIO2 + Livox Driver)
git submodule update --init --recursive
```

### Шаг 5: Сборка Docker образа

```bash
# Собираем образ ROS1 Noetic с Livox SDK
docker compose build

# Или используем готовый скрипт
./scripts/build_docker.sh
```

---

## ⚙️ Настройка

### Конфигурация Livox Horizon

Отредактируйте `config/livox_lidar_config.json`:

```json
{
  "lidar_config": [
    {
      "broadcast_code": "3WEDH5900101971",
      "enable_connect": true,
      "return_mode": 0,
      "coordinate": 0,
      "imu_rate": 1
    }
  ],
  "timesync_config": {
    "enable_timesync": false,
    "device_name": "/dev/ttyUSB0",
    "comm_device_type": 0,
    "baudrate_index": 2,
    "parity_index": 0
  }
}
```

> ⚠️ **Важно:** `broadcast_code` уникален для каждого устройства Livox. Найдите его на наклейке лидара или в приложении Livox Viewer.

### Параметры SLAM (horizon.yaml)

```yaml
common:
  lid_topic: /livox/lidar
  imu_topic: /livox/imu
  time_sync_en: true
  time_offset_lidar_to_imu: 0.0

preprocess:
  lidar_type: 1        # 1 = Livox Horizon
  scan_line: 6         # Количество линий сканирования
  blind: 1.0           # Мёртвая зона (метры)
  point_filter_num: 2  # Прореживание точек

mapping:
  filter_size_map: 0.15    # Размер вокселя карты
  acc_cov: 0.1             # Ковариация акселерометра
  gyr_cov: 0.01            # Ковариация гироскопа
  b_acc_cov: 0.0001        # Ковариация смещения акселерометра
  b_gyr_cov: 0.0001        # Ковариация смещения гироскопа
  fov_degree: 50           # Угол обзора (градусы)
  det_range: 100           # Дальность обнаружения (метры)
  extrinsic_est_en: false  # Оценка внешнего преобразования

publish:
  path_en: true               # Публиковать траекторию
  scan_publish_en: true       # Публиковать сканы
  dense_publish_en: true      # Плотная публикация
  scan_bodyframe_pub_en: true  # Публикация в системе координат корпуса

pcd_save:
  pcd_save_en: true   # Сохранять PCD
  interval: 200       # Интервал сохранения (точки)
```

### Динамическая настройка параметров

```bash
# Изменить мёртвую зону
./scripts/set_param.sh blind 1.5

# Включить плотную публикацию
./scripts/set_param.sh dense_publish_en true

# Изменить размер вокселя карты
./scripts/set_param.sh filter_size_map 0.2

# Включить сохранение PCD
./scripts/set_param.sh pcd_save_en true
```

---

## 🚀 Запуск

### Быстрый старт (все компоненты)

```bash
# Запуск всего стека одной командой
./slam.sh runall
```

### Пошаговый запуск

```bash
# 1. Запуск SLAM контейнера
./slam.sh up

# 2. Запуск драйвера Livox
./slam.sh driver bg

# 3. Запуск ROS Bridge (WebSocket)
./slam.sh bridge bg

# 4. Проверка состояния
./slam.sh check
```

### Команды управления

| Команда | Описание |
|---------|----------|
| `./slam.sh up` | Запуск SLAM контейнера |
| `./slam.sh driver` | Запуск драйвера Livox |
| `./slam.sh driver bg` | Драйвер в фоне |
| `./slam.sh bridge` | Запуск rosbridge |
| `./slam.sh bridge bg` | Rosbridge в фоне |
| `./slam.sh check` | Проверка состояния ROS |
| `./slam.sh build` | Пересборка catkin workspace |
| `./slam.sh save` | Сохранение карты в PCD |
| `./slam.sh logs` | Просмотр логов |
| `./slam.sh down` | Остановка стека |
| `./slam.sh restart` | Перезапуск стека |

### Запуск драйвера с параметрами

```bash
# Указать broadcast_code, IP хоста и лидара
./run_horizon_ros1.sh 3WEDH5900101971 192.168.123.100 192.168.123.51
```

### Визуализация в RViz

```bash
# На хост-машине с дисплеем
./rviz_horizon.sh
```

---

## 🧩 Компоненты

### 1. FAST-LIO2

Высокоскоростная система SLAM для нелинейных лидаров на основе фильтров Ли.

- **Репозиторий:** `ws/catkin_ws/src/fast_lio/`
- **Узел:** `fastlio_mapping`
- **Основа:** [HKU FAST-LIO2](https://github.com/hku-mars/FAST_LIO)

### 2. Livox ROS Driver

Драйвер для подключения лидаров Livox к ROS.

- **Репозиторий:** `ws/catkin_ws/src/livox_ros_driver/`
- **SDK:** Livox SDK2 (установлен в `/usr/local`)
- **Конфиг:** `livox_lidar_config.json`

### 3. TheBigBrother (OSINT)

Фреймворк для разведки и сбора данных (опционально).

- **Директория:** `TheBigBrother/`
- **Порт:** `8000`
- **Стек:** Python + FastAPI + Playwright
- **GitHub:** [chadi0x/TheBigBrother](https://github.com/chadi0x/TheBigBrother)

### 4. Node-RED [Пока не работает, в разработке]

Визуальная автоматизация и дашборд.

- **Порт:** `1880`
- **Плагины:**
  - `node-red-dashboard` — UI компоненты
  - `@background404/node-red-contrib-llm-plugin` — LLM интеграация
- **Флоу:** `~/.node-red/flows.json`

---

## 🌐 Node-RED Dashboard [Пока не

### Установка

```bash
cd ~/.node-red
npm install node-red-dashboard @background404/node-red-contrib-llm-plugin
```

### Доступные эндпоинты

| URL | Описание |
|-----|----------|
| `http://192.168.123.100:1880/ui` | Dashboard UI |
| `http://192.168.123.100:1880/flows.json` | Конфигурация флоу |

---

## 🔐 VPN и удалённый доступ

### WireGuard / Amnezia VPN

Конфигурации расположены в `~/vpn_conf/`:

```
vpn_conf/
├── amnezia_for_wireguard.conf    # WireGuard конфиг
├── amnezia_for_xray (2).json    # Xray конфиг
├── config.json                  # Основной конфиг
└── config2.json                 # Альтернативный конфиг
```

### Подключение через Tailscale

```bash
# Установка Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Авторизация
sudo tailscale up

# Проверка
tailscale status
```

---

## 📶 Wi-Fi режимы

Скрипт `wifi_mode.sh` поддерживает три режима:

```bash
# Клиент — подключение к существующей сети
sudo ./wifi_mode.sh client

# Точка доступа — создание собственной сети (192.168.77.1/24)
sudo ./wifi_mode.sh ap

# Автоматический — если сеть найдена → клиент, иначе → точка доступа
sudo ./wifi_mode.sh auto
```

---

## 🗂️ Структура проекта

```
ros1-horizon-slam/
├── README.md                           # Этот файл
├── INSTALL.md                          # Подробная инструкция по установке
├── CONTRIBUTING.md                     # Руководство по внесению изменений
├── docker-compose.yml                  # Docker Compose для SLAM
├── Dockerfile                          # Образ ROS1 Noetic
├── .env.example                        # Шаблон переменных окружения
│
├── config/
│   ├── horizon.yaml                   # Параметры SLAM
│   └── livox_lidar_config.json        # Конфигурация лидара
│
├── launch/
│   └── mapping_horizon.launch         # ROS launch файл
│
├── scripts/
│   ├── build_docker.sh                # Сборка Docker образа
│   ├── set_param.py                   # Динамическая настройка параметров
│   ├── set_mode_chunked.sh            # Режим блочной карты
│   ├── set_mode_onefile.sh            # Режим единого файла карты
│   └── wifi_mode.sh                   # Управление Wi-Fi режимами
│
├── slam.sh                             # Главный скрипт управления SLAM
├── run_horizon_ros1.sh                # Запуск драйвера Livox
├── rviz_horizon.sh                    # Запуск RViz
│
├── ws/
│   ├── catkin_ws/                     # Catkin workspace
│   │   └── src/
│   │       ├── fast_lio/              # FAST-LIO2 SLAM
│   │       └── livox_ros_driver/      # Livox ROS Driver
│   ├── maps/                          # Сохранённые карты
│   └── pcd/                           # PCD файлы облаков точек
│
├── TheBigBrother/                      # OSINT фреймворк (опционально)
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── the_big_brother/
│
└── vpn_conf/                           # VPN конфигурации
    ├── amnezia_for_wireguard.conf
    ├── config.json
    └── config2.json
```

---

## 🔧 Troubleshooting

### Драйвер Livox не подключается

```bash
# 1. Проверить broadcast_code
cat ~/ros1_horizon/ws/catkin_ws/src/livox_ros_driver/livox_ros_driver/config/livox_lidar_config.json

# 2. Перезапустить драйвер
./slam.sh down && ./slam.sh runall

# 3. Проверить сеть до лидара
ping 192.168.123.51
```

### SLAM не публикует карту

```bash
# Проверить топики
docker exec ros1_noetic_horizon bash -lc "
  source /opt/ros/noetic/setup.bash
  source /ws/catkin_ws/devel/setup.bash
  rostopic list | grep Laser_map
"

# Проверить YAML конфиг
./scripts/set_param.py filter_size_map 0.15
```

### Контейнер не запускается

```bash
# Просмотр логов
docker logs ros1_noetic_horizon

# Пересборка
docker compose build --no-cache

# Проверка прав
sudo chown -R 1000:1000 ~/ros1_horizon/ws
```

### Node-RED не запускается

```bash
# Проверить зависимости
cd ~/.node-red && npm install

# Перезапустить
sudo systemctl restart nodered
```

---

## 📊 Производительность

| Метрика | Значение |
|---------|----------|
| Запуск SLAM | ~15 сек |
| Загрузка карты (1M точек) | ~8 сек |
| Частота /livox/lidar | 10 Hz |
| Частота /cloud_registered | 10 Hz |
| CPU (4 ядра) | 60-80% |
| RAM | 2.8 GB / 8 GB |

---

## 🤝 Вклад в проект

См. [CONTRIBUTING.md](CONTRIBUTING.md) для подробного руководства по внесению изменений.

---

## 📄 Лицензия

MIT License — см. [LICENSE](LICENSE) файл.

---

## 📞 Контакты и поддержка

- **GitHub Issues:** [Сообщить об ошибке](https://github.com/YOUR_USERNAME/ros1-horizon-slam/issues)
- **Документация:** [Wiki проекта](https://github.com/YOUR_USERNAME/ros1-horizon-slam/wiki)

---

<div align="center">

**Создано для Raspberry Pi 5 + Livox Horizon**

`FAST-LIO2` • `ROS Noetic` • `Docker` • `Node-RED`

</div>
