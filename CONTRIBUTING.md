# 🤝 CONTRIBUTING.md — Руководство по внесению изменений

---

## 👋 Добро пожаловать!

Спасибо за интерес к проекту **ROS1 Horizon SLAM**! Мы рады любому вкладу: от исправления опечаток до новых функций.

---

## 📋 Оглавление

1. [Кодекс поведения](#-кодекс-поведения)
2. [Как внести вклад](#-как-внести-вклад)
3. [Структура проекта](#-структура-проекта)
4. [Настройка окружения для разработки](#-настройка-окружения-для-разработки)
5. [Стандарты кода](#-стандарты-кода)
6. [Коммиты](#-коммиты)
7. [Pull Request](#-pull-request)
8. [Решение проблем](#-решение-проблем)

---

## 🌟 Кодекс поведения

- Будьте уважительны к другим участникам
- Конструктивная критика приветствуется
- Помогайте новичкам
- Фокус на качестве и безопасности

---

## 🛠️ Как внести вклад

### 1. Форк репозитория

```bash
# Нажмите кнопку "Fork" на GitHub
# Или через CLI:
gh repo fork YOUR_USERNAME/ros1-horizon-slam --clone
```

### 2. Создайте ветку

```bash
# Для новых функций
git checkout -b feature/description

# Для исправления багов
git checkout -b fix/issue-description

# Для документации
git checkout -b docs/description
```

### 3. Внесите изменения

Следуйте стандартам проекта (см. ниже).

### 4. Протестируйте

```bash
# Проверка Docker
docker compose build
docker compose up -d
./slam.sh check

# Проверка скриптов
python3 scripts/set_param.py blind 1.0
bash scripts/setup.sh --help
```

### 5. Закоммитьте

```bash
git add .
git commit -m "type: краткое описание"

# Примеры:
git commit -m "feat: добавить параметр дет_range в конфиг"
git commit -m "fix: исправить подключение Livox"
git commit -m "docs: обновить INSTALL.md"
```

### 6. Отправьте PR

```bash
git push origin feature/your-feature
gh pr create
```

---

## 📁 Структура проекта

```
ros1-horizon-slam/
├── README.md               # Главная документация
├── INSTALL.md              # Инструкция по установке
├── CONTRIBUTING.md         # Этот файл
├── docker-compose.yml      # Docker Compose
├── Dockerfile              # Образ SLAM
├── Dockerfile.rviz         # Образ RViz
├── slam.sh                 # Главный скрипт управления
├── run_horizon_ros1.sh     # Запуск Livox драйвера
├── rviz_horizon.sh         # Запуск RViz
│
├── config/                 # Конфигурации
│   ├── horizon.yaml        # Параметры SLAM
│   └── livox_lidar_config.json  # Конфиг лидара
│
├── launch/                 # ROS launch файлы
│   └── mapping_horizon.launch
│
├── scripts/                # Вспомогательные скрипты
│   ├── setup.sh            # Полная установка
│   ├── setup_ssh.sh        # Настройка SSH
│   ├── build_docker.sh     # Сборка Docker
│   ├── set_param.py        # Настройка параметров
│   └── wifi_mode.sh        # Управление Wi-Fi
│
└── ws/                     # Catkin workspace
    └── catkin_ws/
        └── src/
            ├── fast_lio/           # FAST-LIO2 SLAM
            └── livox_ros_driver/   # Livox ROS Driver
```

---

## 💻 Настройка окружения для разработки

### На хост-машине (Linux/macOS)

```bash
# Зависимости для разработки
sudo apt install -y \
    git curl wget build-essential cmake pkg-config \
    python3 python3-pip python3-venv python3-yaml \
    docker.io docker-compose-v2

# Python зависимости
pip3 install pyyaml

# VS Code (рекомендуется)
# https://code.visualstudio.com/
```

### Docker для разработки

```bash
# Сборка с кэшем
docker compose build

# Интерактивный режим
docker run --rm -it -v $(pwd):/project ros1_horizon-ros1_noetic:latest bash

# Тестирование скриптов
docker exec -it ros1_noetic_horizon bash -lc "
  source /opt/ros/noetic/setup.bash
  source /ws/catkin_ws/devel/setup.bash
  # ваши команды
"
```

---

## 📐 Стандарты кода

### Bash скрипты

```bash
#!/usr/bin/env bash
set -euo pipefail  # Строгая обработка ошибок

# Документация в начале файла
###############################################################################
# script_name.sh — Краткое описание
#
# Использование:
#   chmod +x script_name.sh
#   ./script_name.sh [аргументы]
###############################################################################

# Функции для логирования
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка аргументов
if [[ $# -lt 1 ]]; then
    log_error "Требуется аргумент"
    exit 1
fi

# Основная логика в функциях
main() {
    local arg1="${1:-}"
    log_info "Запуск с аргументом: $arg1"
    
    # код...
    
    log_ok "Завершено"
}

main "$@"
```

### Python скрипты

```python
#!/usr/bin/env python3
"""
script_name.py — Краткое описание

Использование:
    python3 script_name.py <аргумент1> <аргумент2>

Примеры:
    python3 script_name.py param1 value1
"""

from pathlib import Path
import sys
import yaml


def main():
    """Основная функция"""
    if len(sys.argv) != 3:
        print(__doc__)
        raise SystemExit(1)
    
    # код...
    print("[OK] Выполнено")


if __name__ == "__main__":
    main()
```

### YAML конфигурации

```yaml
# Комментарий к секции
section_name:
  # Параметр с описанием
  parameter_name: value
  
  # Списки
  list_parameter:
    - item1
    - item2
```

### Dockerfile

```dockerfile
# Базовый образ
FROM ros:noetic-ros-base-focal

# Метаданные
LABEL maintainer="your.email@example.com"
LABEL description="ROS1 Horizon SLAM"

# Переменные
ENV DEBIAN_FRONTEND=noninteractive

# Установка пакетов (группировка по логике)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl \
    build-essential cmake pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование и выполнение
COPY . .
RUN make build

# Порт
EXPOSE 11311

# Команда по умолчанию
CMD ["bash"]
```

---

## 📝 Коммиты

### Формат (Conventional Commits)

```
type: краткое описание

[опционально: подробное описание]

[опционально: закрывает #issue]
```

### Типы

| Тип | Описание | Пример |
|-----|----------|--------|
| `feat` | Новая функция | `feat: добавить поддержку Mid-360` |
| `fix` | Исправление бага | `fix: корректная обработка broadcast_code` |
| `docs` | Документация | `docs: обновить README.md` |
| `style` | Форматирование | `style: привести bash к стандартам` |
| `refactor` | Рефакторинг | `refactor: упростить slam.sh` |
| `test` | Тесты | `test: добавить проверку Docker` |
| `chore` | Обслуживание | `chore: обновить .gitignore` |

### Примеры хороших коммитов

```bash
git commit -m "feat: добавить скрипт настройки Wi-Fi режимов"
git commit -m "fix: исправить путь к horizon.yaml в set_param.py"
git commit -m "docs: добавить раздел по устранению проблем в INSTALL.md"
git commit -m "refactor: оптимизировать сборку Docker образа"
```

---

## 🔀 Pull Request

### Шаблон PR

```markdown
## Описание
Краткое описание изменений

## Тип изменений
- [ ] ✨ Новая функция
- [ ] 🐛 Исправление бага
- [ ] 📚 Документация
- [ ] ♻️ Рефакторинг
- [ ] ⚡ Оптимизация

## Тестирование
- [ ] Протестировано на Raspberry Pi 5
- [ ] Docker сборка проходит
- [ ] SLAM запускается
- [ ] Документация обновлена

## Скриншоты (если применимо)
...

## Дополнительные заметки
...
```

### Требования для мержа

- [ ] Код соответствует стандартам
- [ ] Документация обновлена
- [ ] Тесты проходят
- [ ] Нет конфликтов с base веткой
- [ ] Минимум 1 approve от мейнтейнера

---

## 🆘 Решение проблем

### Вопросы и обсуждения

- **GitHub Discussions:** https://github.com/YOUR_USERNAME/ros1-horizon-slam/discussions
- **GitHub Issues:** https://github.com/YOUR_USERNAME/ros1-horizon-slam/issues

### Чат

- **Discord:** [ссылка]
- **Telegram:** [ссылка]

---

## 📄 Лицензия

Внося вклад, вы соглашаетесь с условиями [LICENSE](LICENSE).

---

<div align="center">

**Спасибо за вклад! 🚀**

</div>
