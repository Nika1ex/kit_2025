## Введение

Настоящий документ является структурированным отчетом с подробным описанием выполняемых действий в процессе решения ДЗ по лекции "Основы интернета - IP". Выполнены Часть 1 и Часть 2. 

ДЗ выполнено на ОС Ubuntu 24.04.2 LTS:

![img](attachments/0.1.png)

## Задание

![pdf](homework.pdf)

## Решение

### Часть 1. Настройка

Устанавливаю Containerlab:

`curl -sL https://containerlab.dev/setup | sudo -E bash -s "all"`

Собираю докер-образ:

`docker build -t lab:1 .`

Создаю файл топологии hw1.clab.yaml со следующий содержимым:

```
name: hw1

topology:
  defaults:
    kind: linux
    image: lab:1
    network-mode: none # отключаю создание стандартной сети Docker
  nodes:
    pc1:
      exec:
        - ip addr add 192.168.100.10/24 dev eth1
        - ip route add default via 192.168.100.1
    pc2:
      exec:
        - ip addr add 172.16.100.10/24 dev eth1
        - ip route add default via 172.16.100.1
    pc3:
      exec:
        - ip addr add 192.168.100.20/24 dev eth1
        - ip route add default via 192.168.100.1
    pc4:
      exec:
        - ip addr add 172.16.100.20/24 dev eth1
        - ip route add default via 172.16.100.1
    r:
      exec:
        - ip addr add 192.168.100.1/24 dev eth1
        - ip addr add 172.16.100.1/24 dev eth2
    br1:
      kind: bridge
    br2:
      kind: bridge
  links:
    - endpoints: ["pc1:eth1", "br1:pc1"]
    - endpoints: ["r:eth1", "br1:r192"]
    - endpoints: ["pc3:eth1", "br1:pc3"]
    - endpoints: ["pc2:eth1", "br2:pc2"]
    - endpoints: ["r:eth2", "br2:r172"]
    - endpoints: ["pc4:eth1", "br2:pc4"]
```

Мосты создаю по той причине, что по заданию в каждом сегменте сети у роутера должен быть задействован только один интерфейс.

В процессе создания файла топологии рукодствовался файлом топологии hw2.clab.yaml из 2 части, материалом лекции и руководством по [Linux bridge - containerlab](https://containerlab.dev/manual/kinds/bridge/))

Согласно руководству по Linux bridge вручную создаю мосты и поднимаю:

`sudo ip link add name br1 type bridge`

`sudo ip link set br1 up`

`sudo ip link add name br2 type bridge`

`sudo ip link set br2 up`

Запускаю лабу:

![img](attachments/1.1.png)

Проверяю IP связанность на PC1:

![img](attachments/1.2.png)

Проверяю IP связанность на PC2:

![img](attachments/1.3.png)

Проверяю IP связанность на PC3:

![img](attachments/1.4.png)

Проверяю IP связанность на PC4:

![img](attachments/1.5.png)

В заключении удаляю лабу:

![img](attachments/1.6.png)

**IP связанность обеспечена. Файл топологии доступен по пути part1/hw1.clab.yaml.**

А также правила iptables и созданные мосты:

`sudo iptables -vL FORWARD --line-numbers -n | grep "set by containerlab" | awk '{print $1}' | sort -r | xargs -I {} sudo iptables -D FORWARD {}`

`sudo ip link del name br1`

`sudo ip link del name br2`

### Часть 2. Траблшутинг

Создаю тег kit-lab на ранее собранный образ lab:1 для корректного запуска лабы:

`docker tag lab:1 kit-lab`

Запускаю лабу:

![img](attachments/2.1.png)

Смотрю информацию о сетевых интерфейсах и маршрутах в каждом контейнере.

PC1:

![img](attachments/2.2.png)

PC2:

![img](attachments/2.3.png)

PC3:

![img](attachments/2.4.png)

PC4:

![img](attachments/2.5.png)

На основании полученной информации формирую структуру сетевого взимодействия:

![img](attachments/2.6.png)

В процессе решения придерживался того, что необходимо сохранить исходную топологию, а именно:

- IP адреса хостов изменять нельзя;

- маршруты по-умолчанию изменять нельзя.

В процессе анализа сетевого взаимодествия было выявленно следующее:

1. Сеть 192.168.13.0/24 содержит в себе IP адрес итерфейса lo1 PC4 (192.168.13.10/24). У данного интерфейса выключен протокол ARP, поэтому достучаться до него с PC1 и PC2 нельзя. Решение - изменить маску подсети /24 на /31 для для point-to-point линка PC1-PC2.

2. Маршрут `100.100.2.12 via 10.20.13.1 dev eth2` на PC4 приводит к ненужному редиректу на PC2 и зацикливанию пакетов. Решение - удалить маршрут.

3. У eth1 PC3 и eth1 PC4 разные значения MTU. Это может привести к проблемам с передачей данных. Решение - установить на обоих интерфейсах значение MTU по-умолчанию.

4. У eth2 PC3 выключен протокол ARP, поэтому сетевой связанности PC3-PC1 не будет. Решение - включить протокол ARP.

5. Всем point-to-point соединениям целесообразно установить /31 маску подсети, как минимально возможную. Всем lo1 интерфейсам - /32. Интерфейс lo2 PC1 можно удалить ввиду ненадобности.

Учитывая изложенное, формирую структуру сетевого взимодействия:

![img](attachments/2.7.png)

Изменяю файлы `network.sh` для каждого PC, а также переписываю `/etc/hosts` (в нем изначально есть ошибки в интерфейсах PC3 и PC4)

Пересоздаю лабу и проверяю IP связанность и маршрутизацию:

PC1:

![img](attachments/2.8.png)
![img](attachments/2.9.png)

PC2:

![img](attachments/2.10.png)
![img](attachments/2.11.png)

PC3:

![img](attachments/2.12.png)
![img](attachments/2.13.png)

PC4:

![img](attachments/2.14.png)
![img](attachments/2.15.png)

**Топология сохранена, IP связанность обеспечена. Файлы `network.sh` и `/etc/hosts` расположены в директории part2/.**

На PC1 пробую скачать блоб `test`:

![img](attachments/2.16.png)

Есть проблема с PC3, выполняю команду в verbose mode:

![img](attachments/2.17.png)

Ошибка свяазана с тем, что ключ PC3 изменился по сравнению с тем, что сохранен в /root/.ssh/known_hosts. Система предлагает решение, выполняю и проверяю:

![img](attachments/2.18.png)

Выполняю проверку на остальных хостах:

PC2:

![img](attachments/2.19.png)

PC3:

![img](attachments/2.20.png)

PC4:

![img](attachments/2.21.png)

Рассмотренная топология имеет следующие недостатки:

1. Низкая отказоустойчивость: отказ одного любого интерфейса или линии связи нарушит работу сети.

2. Задержки и производительность: например, трафик от PC1 до PC3 должен пройти через PC2 и PC4. Это создает задержки и увеличивает нагрузку на промежуточные узлы.

3. Проблемы с масштабированием: при добавлении новых устройств цепочка будет удлиняться, что усугубит проблемы задержки и надежности.