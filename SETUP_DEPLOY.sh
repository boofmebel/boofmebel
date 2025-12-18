#!/bin/bash
# 🚀 ОДИН СКРИПТ ДЛЯ ВСЕГО: Создание репозитория + секреты + автодеплой
# Запустите этот скрипт один раз - он настроит всё автоматически

set -e

cd "$(dirname "$0")"

echo "🚀 Настройка автодеплоя BoofMebel"
echo "=================================="
echo ""

# Установить зависимости
echo "📦 Установка зависимостей Python..."
python3 -m pip install --quiet --user requests pynacl 2>/dev/null || {
    python3 -m pip install --user requests pynacl
}

echo ""
echo "📋 Нужны следующие данные:"
echo ""

# Запросить минимальные данные
read -p "1. GitHub username/org: " GITHUB_USER
read -p "2. Название репозитория (например: boofmebel): " REPO_NAME
echo ""
echo "3. GitHub Personal Access Token"
echo "   Создайте здесь: https://github.com/settings/tokens"
echo "   Права: repo (полный доступ)"
read -sp "   Введите токен: " GITHUB_TOKEN
echo ""
echo ""
read -p "4. IP или домен сервера: " SERVER_HOST
read -p "5. Пользователь SSH [deploy]: " SERVER_USER
SERVER_USER=${SERVER_USER:-deploy}

SSH_KEY_PATH=~/.ssh/id_ed25519
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo ""
    echo "🔑 SSH ключ не найден. Создать новый? (y/n)"
    read CREATE_KEY
    if [ "$CREATE_KEY" = "y" ]; then
        ssh-keygen -t ed25519 -C "github-actions@server" -f "$SSH_KEY_PATH" -N ""
        echo "✅ SSH ключ создан: $SSH_KEY_PATH"
        echo "📋 Добавьте публичный ключ на сервер:"
        echo "   cat ${SSH_KEY_PATH}.pub"
        echo ""
        read -p "Нажмите Enter после добавления ключа на сервер..."
    fi
fi

FULL_REPO="${GITHUB_USER}/${REPO_NAME}"

echo ""
echo "📋 Будет создано:"
echo "  ✅ Репозиторий: ${FULL_REPO}"
echo "  ✅ Секреты: SERVER_HOST, SERVER_USER, SERVER_SSH_KEY"
echo "  ✅ GitHub Actions workflow"
echo "  ✅ Первый коммит и push"
echo ""

read -p "Продолжить? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "🔄 Настройка..."

# Запустить Python скрипт
python3 << PYEOF
import os
import sys
import json
import base64
import subprocess
from pathlib import Path

try:
    import requests
    from nacl import encoding, public
except ImportError:
    print("❌ Установите: pip install requests pynacl")
    sys.exit(1)

# Данные
token = "${GITHUB_TOKEN}"
owner = "${GITHUB_USER}"
repo_name = "${REPO_NAME}"
server_host = "${SERVER_HOST}"
server_user = "${SERVER_USER}"
ssh_key_path = os.path.expanduser("${SSH_KEY_PATH}")
project_dir = os.getcwd()
repo_url = f"https://github.com/{owner}/{repo_name}.git"

headers = {
    "Authorization": f"token {token}",
    "Accept": "application/vnd.github.v3+json"
}

# 1. Создать репозиторий
print("🔄 Создание репозитория...")
url = "https://api.github.com/user/repos"
data = {
    "name": repo_name,
    "description": "BoofMebel API - FastAPI backend with auth and deploy",
    "private": False
}
response = requests.post(url, headers=headers, json=data)
if response.status_code == 201:
    print("✅ Репозиторий создан")
elif response.status_code == 422:
    print("⚠️  Репозиторий уже существует (продолжаем...)")
else:
    print(f"❌ Ошибка создания: {response.status_code}")
    print(response.text)
    sys.exit(1)

# 2. Получить публичный ключ для секретов
print("🔐 Настройка секретов...")
url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/public-key"
response = requests.get(url, headers=headers)
if response.status_code != 200:
    print(f"❌ Ошибка получения ключа: {response.status_code}")
    sys.exit(1)
key_data = response.json()
key_id = key_data["key_id"]
public_key = key_data["key"]

# 3. Зашифровать и добавить секреты
def encrypt_secret(pub_key, value):
    pub_key_obj = public.PublicKey(pub_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(pub_key_obj)
    encrypted = sealed_box.encrypt(value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")

ssh_key = Path(ssh_key_path).read_text()

secrets = {
    "SERVER_HOST": server_host,
    "SERVER_USER": server_user,
    "SERVER_SSH_KEY": ssh_key
}

for name, value in secrets.items():
    encrypted = encrypt_secret(public_key, value)
    url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/{name}"
    data = {
        "encrypted_value": encrypted,
        "key_id": key_id
    }
    response = requests.put(url, headers=headers, json=data)
    if response.status_code in [201, 204]:
        print(f"✅ {name} добавлен")
    else:
        print(f"❌ Ошибка {name}: {response.status_code}")

# 4. Настроить git remote
print("🔄 Настройка git...")
try:
    subprocess.run(["git", "remote", "remove", "origin"], 
                  stderr=subprocess.DEVNULL, check=False)
except:
    pass

subprocess.run(["git", "remote", "add", "origin", repo_url], check=True)
print("✅ Remote добавлен")

# 5. Push в репозиторий
print("📤 Отправка кода в GitHub...")
try:
    subprocess.run(["git", "push", "-u", "origin", "main"], 
                  check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("✅ Код отправлен")
except subprocess.CalledProcessError:
    print("⚠️  Push не выполнен (возможно, нужна настройка доступа)")
    print("   Выполните вручную: git push -u origin main")

print("")
print("=" * 50)
print("✅ ГОТОВО! Автодеплой настроен!")
print("")
print(f"📋 Репозиторий: https://github.com/{owner}/{repo_name}")
print(f"📋 Actions: https://github.com/{owner}/{repo_name}/actions")
print(f"📋 Секреты: https://github.com/{owner}/{repo_name}/settings/secrets/actions")
print("")
print("🚀 При каждом push в main будет автоматический деплой!")
PYEOF

echo ""
echo "✅ Всё настроено!"
echo ""
echo "📝 Следующий шаг: Настроить сервер (см. DEPLOY_CHECKLIST.md)"

