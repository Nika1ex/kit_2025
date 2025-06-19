## Введение

Настоящий документ является структурированным отчетом с подробным описанием выполняемых действий в процессе решения ДЗ по лекции "Устройство и загрузка современного сервера". Выполнена Часть 1. 

ДЗ выполнено на ОС Ubuntu 24.04.2 LTS:

![img](attachments/0.1.png)

## Задание

1. Дан образ машины, в которой перед её выключением было затёрто начало диска, и она теперь не загружается. Пароль пользователя неизвестен. Нужно восстановить работоспособность системы и суметь в неё залогиниться.
2. Найти и получить секрет.

## Решение

### Часть 1. Восстановить систему

Запускаю скрипт run.sh согласно README и получаю ошибку отсутствия systemrescue-12.01-amd64.iso:

![img](attachments/1.1.png)

Скачиваю systemrescue-12.01-amd64.iso, SHA256 checksum и проверяю целостность образа:

![img](attachments/1.2.png)

Повторно запускаю скрипт run.sh, процесс захватывает текущий терминал:

![img](attachments/1.3.png)

Иду изучать каждый аргумент команды:

```
qemu-system-x86_64 -smp cores=4,threads=1 \
	-drive if=pflash,format=raw,readonly=on,file=OVMF_CODE_4M.ms.fd \
	-drive if=pflash,format=raw,file=OVMF_VARS_4M.ms.fd \
	-drive file=task2.img,format=qcow2 \
	-m 4096 -machine q35,smm=on \
        -nic user,hostfwd=tcp:127.0.0.1:2222-:22 \
	-vnc :1,password-secret=vncpw -object secret,id=vncpw,file=vncpassword,format=raw \
	-boot menu=on \
	-cdrom systemrescue-12.01-amd64.iso
```

- **`qemu-system-x86_64`**  
    Запускает эмулятор QEMU для архитектуры x86_64 (64-битные системы).

- **`-smp cores=4,threads=1`**  
    Настраивает SMP (Symmetric Multiprocessing):
    - `cores=4` — 4 физических ядра CPU.
    - `threads=1` — 1 поток на ядро (без Hyper-Threading).  
        Итого: гостевая ОС видит 4 логических процессора.

- **`-drive if=pflash,format=raw,readonly=on,file=OVMF_CODE_4M.ms.fd`**  
    Первый pflash-диск для UEFI-прошивки:
    - `if=pflash` — интерфейс эмуляции флеш-памяти UEFI.
    - `format=raw` — образ в сыром формате.
    - `readonly=on` — доступен только для чтения (защита прошивки).
    - `file=OVMF_CODE_4M.ms.fd` — файл UEFI-прошивки (код).
        
- **`-drive if=pflash,format=raw,file=OVMF_VARS_4M.ms.fd`**  
    Второй pflash-диск для переменных UEFI (NVRAM):
    - Переменные загрузки сохраняются здесь (без `readonly`).
    - `OVMF_VARS_4M.ms.fd` — образ для хранения настроек UEFI.
        
- **`-drive file=task2.img,format=qcow2`**  
    Основной виртуальный жесткий диск:
    - `file=task2.img` — образ диска гостевой ОС.
    - `format=qcow2` — формат QCOW2 (поддержка снимков, сжатия).
        
- **`-m 4096`**  
    Выделяет 4096 МБ (4 ГБ) оперативной памяти для гостевой системы.

- **`-machine q35,smm=on`**  
    Выбирает тип системной платформы:
    - `q35` — современная платформа с PCI Express (аналог Intel Q35 чипсета).
    - `smm=on` — включает System Management Mode (режим управления системой), критично для безопасности UEFI.

- **`-nic user,hostfwd=tcp:127.0.0.1:2222-:22`**  
    Настраивает сеть в режиме пользователя (NAT):
    - `hostfwd=tcp:127.0.0.1:2222-:22` — проброс порта:  
        Хост: `127.0.0.1:2222` → Гость: `22` (SSH).  
        Подключение к гостю: `ssh -p 2222 user@localhost`.
        
- **`-vnc :1,password-secret=vncpw`**  
    Включает VNC-сервер:
    - `:1` — дисплей 1 (порт 5901).
    - `password-secret=vncpw` — использует пароль из объекта `vncpw`.

- **`-object secret,id=vncpw,file=vncpassword,format=raw`**  
    Создает объект с паролем для VNC:
    - `id=vncpw` — идентификатор, связанный с `-vnc`.
    - `file=vncpassword` — файл с паролем в сыром виде (plain text).

- **`-boot menu=on`**  
    Включает меню загрузки при старте:
    - Позволяет выбрать загрузку с HDD, CD-ROM и т.д.
    - Особенно полезно с подключенным `-cdrom`.

- **`-cdrom systemrescue-12.01-amd64.iso`**  
    Подключает ISO-образ как CD-ROM:
    - `systemrescue-12.01-amd64.iso` — загрузочный диск для аварийного восстановления.

Открываю второй терминал, и согласно `-vnc :1,password-secret=vncpw` проверяю, что VNC-сервер слушает на порту 5901:

![img](attachments/1.4.png)

Устанавливаю remmina для управления запущенной виртуальной машиной (ВМ) по протоколу VNC:

`sudo apt install remmina -y`

Подключаюсь к ВМ:

![img](attachments/1.5.png)

![img](attachments/1.6.png)

Обращаю внимание на ошибку загрузки с диска (Ассеss Denied):

![img](attachments/1.7.png)

Проверяю в Boot Manager Menu включен ли SecureBoot:

![img](attachments/1.8.png)

Отключаю SecureBoot и перезагружаю систему. 
В меню GRUB выбираю загрузиться с параметрами по умолчанию:

![img](attachments/1.9.png)

SystemRescue 12.01 загружена, вход в систему выполнен под пользователем root:

![img](attachments/1.10.png)

Проверяю состояние ssh-сервера:

![img](attachments/1.11.png)

Проверяю состояние firewall:

![img](attachments/1.12.png)

Проверяю правила iptables и добавляю правило для SSH:

![img](attachments/1.13.png)

Устанавливаю пароль для root используя утилиту `passwd`

Подключаюсь с хоста на ВМ по SSH согласно правилу проброса портов при запуске qemu:

![img](attachments/1.14.png)

Смотрю информацию о дисках:

![img](attachments/1.15.png)

/dev/sda - интерсующий меня проблемный диск

Проверяю таблицу разделов:

![img](attachments/1.16.png)

Основная таблица повреждена, но резервная копия цела, перехожу к восстанавлению таблицы разделов:

Последовательно выбираю:

1 - Use current GPT

r - recovery and transformation options (experts only)

v	- verify disk

![img](attachments/1.17.png)

p - print the partition table

![img](attachments/1.18.png)

w	- write table to disk and exit

y - подтверждаю изменения

Смотрю информацию о /dev/sda:

![img](attachments/1.19.png)

/dev/sda1 - загрузочный раздел с файловой системой vfat

/dev/sda2 - корневой раздел с файловой системой ext4

Оцениваю состояние /dev/sda1 без внесения изменений и обнаруживаю повреждения загрузочного сектора, FSINFO-сектора и FAT-таблиц:

![img](attachments/1.20.png)

Восстановление файловой системы посредством утилиты fsck.fat не помогло (загрузочный сектор полностью повреждён), пересоздаю файловую систему:

![img](attachments/1.21.png)

Проверяю /dev/sda2, проблем нет:

![img](attachments/1.22.png)

Монтирую корневой и загрузочный разделы с жёсткого диска к файловой системе RescueCD:

![img](attachments/1.23.png)

Проверяю монтирование:

![img](attachments/1.24.png)

Выполняю chroot в собранную ФС и вижу, что UUID /dev/sda1 отличается от записи в /etc/fstab:

![img](attachments/1.25.png)

Правлю /etc/fstab:

![img](attachments/1.26.png)

Устанавливаю GRUB:

![img](attachments/1.27.png)

Размонтирую ФС:

![img](attachments/1.28.png)

Перезагружаю систему и включаю SecureBoot в Boot Manager Menu.

Войти в систему не удается, так как не знаю пароля.
Перезапускаю ВМ и запускаю меню GRUB:

![img](attachments/1.29.png)

Нажимаю 'e' и редактирую параметры ядра, заменяя ro на rw init=/bin/bash, и загружаю систему (Ctrl-x):

![img](attachments/1.30.png)

Вывожу список пользователей, задача - залогиниться под пользователем kit:

![img](attachments/1.31.png)

Меняю пароль у пользователя kit:

![img](attachments/1.32.png)

Перезагружаю систему:

`reboot -f`

Вхожу в систему под пользователем kit:

![img](attachments/1.33.png)

Проверяю, что SecureBoot включен, а также то, что примонтированы все незакомментированные в исходной системе ФС:

![img](attachments/1.34.png)
