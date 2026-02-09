# Исправление клавиш Fn на Huawei MateBook 14s (Debian GNOME X11)

[English version](../README.md)

![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-12%2F13-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![systemd](https://img.shields.io/badge/systemd-service-DA2525?style=for-the-badge&logo=linux&logoColor=white)

Этот проект отключает лишние события громкости от `Huawei WMI hotkeys` через `input-remapper`, чтобы горячие клавиши Fn работали корректно в Debian.

## Что включено

- `install.sh` — установка `input-remapper`, создание пресета и настройка автозагрузки.
- Пресет `volume-ignore` — отключает лишние события `XF86AudioLowerVolume`/`XF86AudioRaiseVolume`.

## Требования

- Debian 12 или 13
- Доступ к `sudo` для установки пакетов
- `systemd` (для автозапуска демона)

## Установка

```bash
./install.sh
```

Опции:

- `--debug` — полный вывод команд (без лог‑файлов).
- `-y`, `--yes` — авто‑принятие запросов.

## Что делает скрипт

- Выполняет `apt update` и ставит `input-remapper`.
- Создаёт пресет в `~/.config/input-remapper/presets/Huawei WMI hotkeys/volume-ignore.json`.
- Включает `input-remapper-daemon` и автозагрузку пресета (по запросу).

## Удаление

Отключить демон и автозагрузку:

```bash
sudo systemctl disable --now input-remapper-daemon.service
```

Удалить пресет:

```bash
rm -f ~/.config/input-remapper/presets/"Huawei WMI hotkeys"/volume-ignore.json
```

## Логи

По умолчанию логи установщика хранятся здесь:

```
~/.cache/huawei-fnkeys-fix/logs
```

## Примечания

- Если `apt update` падает из‑за стороннего репозитория, временно отключите его в `/etc/apt/sources.list.d/`.
- Проверьте устройство в списке:  
  `input-remapper-control --list-devices`