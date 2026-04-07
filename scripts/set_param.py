#!/usr/bin/env python3
"""
set_param.py — Динамическая настройка параметров SLAM

Использование:
    python3 set_param.py <параметр> <значение>

Доступные параметры:
    blind               — Мёртвая зона лидара (метры)
    point_filter_num    — Прореживание точек
    filter_size_map     — Размер вокселя карты
    det_range           — Дальность обнаружения (метры)
    dense_publish_en    — Плотная публикация (true/false)
    scan_publish_en     — Публикация сканов (true/false)
    path_en             — Публикация траектории (true/false)
    pcd_save_en         — Сохранение PCD (true/false)
    interval            — Интервал сохранения PCD (точки)

Примеры:
    python3 set_param.py blind 1.5
    python3 set_param.py dense_publish_en true
    python3 set_param.py filter_size_map 0.2
"""

from pathlib import Path
import sys
import yaml

# Путь к конфигу (относительно корня проекта или абсолютный)
CFG_CANDIDATES = [
    Path(__file__).parent.parent / "config" / "horizon.yaml",
    Path("/home/pi5/ros1_horizon/ws/catkin_ws/src/fast_lio/config/horizon.yaml"),
]

ALLOWED = {
    "blind": ("preprocess", "blind", float),
    "point_filter_num": ("preprocess", "point_filter_num", int),
    "filter_size_map": ("mapping", "filter_size_map", float),
    "det_range": ("mapping", "det_range", int),
    "dense_publish_en": ("publish", "dense_publish_en", lambda v: str(v).lower() in ("1", "true", "yes", "on")),
    "scan_publish_en": ("publish", "scan_publish_en", lambda v: str(v).lower() in ("1", "true", "yes", "on")),
    "scan_bodyframe_pub_en": ("publish", "scan_bodyframe_pub_en", lambda v: str(v).lower() in ("1", "true", "yes", "on")),
    "path_en": ("publish", "path_en", lambda v: str(v).lower() in ("1", "true", "yes", "on")),
    "pcd_save_en": ("pcd_save", "pcd_save_en", lambda v: str(v).lower() in ("1", "true", "yes", "on")),
    "interval": ("pcd_save", "interval", int),
}


def find_config() -> Path:
    """Найти конфигурационный файл horizon.yaml"""
    for candidate in CFG_CANDIDATES:
        if candidate.exists():
            return candidate
    raise SystemExit(f"ERROR: horizon.yaml не найден в: {CFG_CANDIDATES}")


def load_cfg(cfg_path: Path) -> dict:
    """Загрузить YAML конфигурацию"""
    if not cfg_path.exists():
        raise SystemExit(f"Config not found: {cfg_path}")
    data = yaml.safe_load(cfg_path.read_text())
    if not isinstance(data, dict):
        raise SystemExit("Config root is not a dict")
    return data


def backup_cfg(cfg_path: Path):
    """Создать резервную копию конфига"""
    bak = cfg_path.with_name(cfg_path.name + ".bak")
    bak.write_text(cfg_path.read_text())
    print(f"[BACKUP] Создана резервная копия: {bak}")


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        raise SystemExit(1)

    param = sys.argv[1].strip()
    raw_value = sys.argv[2].strip()

    if param not in ALLOWED:
        print(f"ERROR: Unsupported param: {param}")
        print(f"Доступные: {', '.join(ALLOWED.keys())}")
        raise SystemExit(1)

    section, key, caster = ALLOWED[param]

    try:
        value = caster(raw_value)
    except Exception as e:
        raise SystemExit(f"ERROR: Bad value for {param}: {raw_value} ({e})")

    cfg_path = find_config()
    data = load_cfg(cfg_path)

    # Проверка секции
    if section not in data or not isinstance(data[section], dict):
        data[section] = {}

    # Создание бэкапа
    backup_cfg(cfg_path)

    # Обновление параметра
    old_value = data[section].get(key)
    data[section][key] = value

    # Сохранение
    cfg_path.write_text(yaml.safe_dump(data, sort_keys=False, default_flow_style=False))

    print(f"[OK] {section}.{key} = {value} (было: {old_value})")
    print(f"[CONFIG] {cfg_path}")


if __name__ == "__main__":
    main()
