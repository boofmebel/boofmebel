#!/bin/bash
# Автоматическая настройка обоих окружений на сервере
# Запускать на сервере: bash deploy/auto-setup-server.sh

set -e

echo "🚀 Автоматическая настройка окружений BoofMebel"
echo ""

# Определяем базовые параметры
SITE_NAME="boofmebel"
DOMAIN_PROD="boofmebel.com"
DOMAIN_TEST="boofmebel-test.com"

# Проверяем что мы в правильной директории
if [ ! -f "deploy/setup.sh" ]; then
    echo "❌ Ошибка: скрипт должен запускаться из корня репозитория"
    exit 1
fi

echo "📋 Параметры:"
echo "   Сайт: ${SITE_NAME}"
echo "   Продакшн домен: ${DOMAIN_PROD}"
echo "   Тест домен: ${DOMAIN_TEST}"
echo ""

# 1. Настройка продакшн окружения
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Настройка ПРОДАКШН окружения (порт 80)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "/var/www/${SITE_NAME}" ]; then
    echo "⚠️  Директория /var/www/${SITE_NAME} уже существует"
    read -p "   Перезаписать? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Пропускаем продакшн..."
    else
        bash deploy/setup.sh ${SITE_NAME} ${DOMAIN_PROD} prod
    fi
else
    bash deploy/setup.sh ${SITE_NAME} ${DOMAIN_PROD} prod
fi

echo ""
echo "✅ Продакшн окружение настроено!"
echo ""

# 2. Настройка тестового окружения
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Настройка ТЕСТОВОГО окружения (порт 9000)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "/var/www/${SITE_NAME}-test" ]; then
    echo "⚠️  Директория /var/www/${SITE_NAME}-test уже существует"
    read -p "   Перезаписать? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Пропускаем тест..."
    else
        bash deploy/setup.sh ${SITE_NAME} ${DOMAIN_TEST} test
    fi
else
    bash deploy/setup.sh ${SITE_NAME} ${DOMAIN_TEST} test
fi

echo ""
echo "✅ Тестовое окружение настроено!"
echo ""

# 3. Проверка статуса
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Проверка статуса сервисов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📊 Статус сервисов:"
sudo systemctl status ${SITE_NAME}.service --no-pager -l || echo "   ⚠️  ${SITE_NAME}.service не найден"
echo ""
sudo systemctl status ${SITE_NAME}-test.service --no-pager -l || echo "   ⚠️  ${SITE_NAME}-test.service не найден"

echo ""
echo "🌐 Проверка портов:"
sudo netstat -tlnp 2>/dev/null | grep -E ':(80|9000)' || ss -tlnp 2>/dev/null | grep -E ':(80|9000)' || echo "   Порты не слушаются"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Настройка завершена!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Следующие шаги:"
echo ""
echo "1. Настройте SSL для продакшна:"
echo "   sudo certbot --nginx -d ${DOMAIN_PROD}"
echo ""
echo "2. Проверьте доступ:"
echo "   Продакшн: http://$(hostname -I | awk '{print $1}')"
echo "   Тест: http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "3. GitHub Actions настроен:"
echo "   - Push в 'main' → деплой на продакшн"
echo "   - Push в 'dev' → деплой на тест"
echo ""
