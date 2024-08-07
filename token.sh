#!/bin/bash

# Путь к файлу конфигурации Alertmanager
CONFIG_FILE="/etc/alertmanager/alertmanager.yml"

# Извлекаем токен из файла конфигурации
TOKEN=$(grep -oP "(?<=/alertmanager/)[^']+" "$CONFIG_FILE")

# Определяем IP-адрес машины
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Проверяем, удалось ли извлечь токен
if [ -z "$TOKEN" ]; then
  echo "Токен не найден в файле конфигурации."
else
  # Выводим токен в терминал
  echo "Извлеченный токен: $TOKEN"
fi

# Проверяем, удалось ли определить IP-адрес
if [ -z "$IP_ADDRESS" ]; then
  echo "Не удалось определить IP-адрес."
else
  # Выводим IP-адрес в терминал
  echo "IP-адрес машины: $IP_ADDRESS"
fi
