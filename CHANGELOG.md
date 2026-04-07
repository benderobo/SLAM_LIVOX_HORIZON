# Changelog

Все значимые изменения проекта документируются в этом файле.

Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.0.0/).

## [Unreleased]

### Добавлено
- Профили сканирования: `close` (0.3–15м), `medium` (1–40м), `far` (2–150м)
- Скрипт переключения профилей `switch_profile.sh` с опцией `--restart`
- Автоматическая резервная копия `horizon.yaml.bak` при смене профиля

---

## [1.0.0] — 2026-04-07

### Добавлено
- 🐳 **Docker Compose** — 4 сервиса: SLAM, ROS Bridge, RViz, TheBigBrother
- 🗺️ **FAST-LIO2 SLAM** — интеграция с Livox Horizon LiDAR
- 📡 **Livox ROS Driver** — драйвер с broadcast и unicast режимами
- 🎛️ **Node-RED Dashboard** — визуальная автоматизация и LLM плагин
- 🔧 **Динамическая настройка** — Python/YAML скрипт `set_param.py`
- 📶 **Wi-Fi режимы** — AP/Client/Auto переключение
- 🔐 **VPN поддержка** — WireGuard, Tailscale, Xray конфиги
- 📦 **Скрипты установки** — `setup.sh`, `setup_ssh.sh`, `build_docker.sh`
- 🤖 **CI/CD** — GitHub Actions для проверки Docker и линтинга
- 📚 **Документация** — README.md, INSTALL.md, CONTRIBUTING.md
- 🎨 **Профили сканирования** — close/medium/far для разных дистанций

### Изменено
- Livox конфиг обновлён с поддержкой return_mode, coordinate, imu_rate, timesync_config

### Исправлено
- Формат `livox_lidar_config.json` приведён в соответствие с реальной версией на Pi 5

---

## [0.1.0] — 2026-03-03

### Добавлено
- Первоначальная настройка ROS1 Noetic на Raspberry Pi 5
- Livox SDK2 сборка и интегра
- Catkin workspace с FAST-LIO2
- Базовые скрипты запуска (`slam.sh`, `run_horizon_ros1.sh`)
- Docker образ `ros1_horizon-ros1_noetic`
- Node-RED установка и флоу
