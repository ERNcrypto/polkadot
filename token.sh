#!/bin/bash

# Путь к файлу конфигурации Alertmanager
CONFIG_FILE="/etc/alertmanager/alertmanager.yml"

# Извлекаем токен из файла конфигурации
TOKEN=$(grep -oP "(?<=/alertmanager/)[^']+" "$CONFIG_FILE")

# Проверяем, удалось ли извлечь токен
if [ -z "$TOKEN" ]; then
  echo "Токен не найден в файле конфигурации."
else
  # Выводим токен в терминал
  echo "Извлеченный токен: $TOKEN"
fi
