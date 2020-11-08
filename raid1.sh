#!/bin/bash
# RAID 1
# Установка утилиты mdadm
yum install -y mdadm

# Занулим суперблоки
mdadm --zero-superblock --force /dev/sd{b,c}

# Создадим RAID 1 и дождёмся завершения (1 минута)
mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/sd{b,c} <<-EOF
yes
EOF
sleep 1m

# Создадим файл mdadm.conf
mkdir /etc/mdadm/
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

#Создадим раздел GPT на RAID
parted -s /dev/md0 mklabel gpt

#Создадим разделы
parted /dev/md0 mkpart primary ext4 0% 50%
parted /dev/md0 mkpart primary ext4 50% 100%

#Создадим файловые системы
for i in $(seq 1 2); do sudo mkfs.ext4 /dev/md0p$i; done

#Смонтируем разделы
mkdir -p /raid/data{1,2}
for i in $(seq 1 2); do mount /dev/md0p$i /raid/data$i; done

# Вывод списка разделоа
df -hT
