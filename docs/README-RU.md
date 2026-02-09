# Исправление Fn-кнопок Huawei (Debian GNOME X11)

[English version](../README.md)

![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-13-A81D33?style=for-the-badge&logo=debian&logoColor=white)
![GNOME](https://img.shields.io/badge/GNOME-48-4A86CF?style=for-the-badge&logo=gnome&logoColor=white)
![Xorg](https://img.shields.io/badge/Xorg-X11-FF6600?style=for-the-badge&logo=xorg&logoColor=white)
![systemd](https://img.shields.io/badge/systemd-service-DA2525?style=for-the-badge&logo=linux&logoColor=white)

Этот проект устраняет лаги при регулировке громкости (Fn+F5/F6) на Huawei MateBook 14s в Debian 13 GNOME X11, блокируя дублирующиеся события от Huawei WMI hotkeys и сохраняя работу остальных Fn-кнопок.

## Что включено

- `install.sh` - установка input-remapper, создание пресета и настройка автозагрузки.
- Пресет input-remapper, отключающий только XF86AudioLowerVolume и XF86AudioRaiseVolume на Huawei WMI hotkeys.
- Настройка демона для автоматической загрузки на старте.

## Требования

- Debian 13
- GNOME на Xorg (X11 сессия)
- Доступ к `sudo` для установки пакетов

## Проблема

На Huawei MateBook 14s в Debian 13 GNOME X11 при нажатии Fn+F5/F6 появляется заметная задержка. Одна физическая кнопка генерирует два события:

- стандартная клавиатура (AT Translated Set 2 keyboard)
- Huawei WMI hotkeys

GNOME обрабатывает оба события, дважды показывает оверлей громкости и дважды меняет уровень звука, что вызывает подтормаживания.

## Задача

Сделать работу регулировки громкости плавной без потери остальных Fn-кнопок Huawei:

- Fn + Mute
- Fn + Mic Mute
- Fn + Airplane mode
- Fn + Settings
- Fn + Brightness

## Решение

Использовать input-remapper, чтобы отключить только дублирующиеся события громкости от Huawei WMI hotkeys, оставив события обычной клавиатуры.

## Установка

```bash
./install.sh
```

Опции:

- `--debug` - полный вывод команд (без лог-файлов).
- `-y`, `--yes` - авто-принятие запросов.

После установки регулировка громкости должна работать плавно, а остальные Fn-кнопки останутся рабочими.

## Альтернативные решения

| Метод | Описание | Плюсы | Минусы |
|-------|----------|-------|--------|
| **xorg.conf.d** | Полностью отключить Huawei WMI устройство | Не нужно доп. ПО, работает на уровне X11 | Ломает все Fn-кнопки Huawei |
| **xmodmap** | Установить NoSymbol для keycodes 122/123 | Простой автозапуск | Глобальная замена, ломает громкость везде |
| **udev hwdb** | Установить KEYBOARD_KEY_72=reserved | Уровень ядра | Не блокирует события X11, нужен ребут |
| **input-remapper** | Отключить только события громкости | Точное управление, GUI, демон, автозагрузка | Доп. процесс (~38MB RAM) |

## Проверка

```bash
sudo systemctl status input-remapper-daemon.service
input-remapper-control --list-devices
xinput test "Huawei WMI hotkeys"
```

Fn+F5/F6 не должны выдавать события на Huawei WMI устройстве, звук меняется плавно.