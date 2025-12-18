#!/usr/bin/env python3
"""
Скрипт для добавления GitHub Secrets через GitHub API
Требует: GITHUB_TOKEN в переменных окружения или .env файле
"""

import os
import sys
import base64
from getpass import getpass
from pathlib import Path

try:
    import requests
except ImportError:
    print("❌ Установите requests: pip install requests")
    sys.exit(1)

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


def get_github_token():
    """Получить GitHub token из окружения или запросить."""
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        token = getpass("Введите GitHub Personal Access Token: ")
    return token


def add_secret(repo: str, secret_name: str, secret_value: str, token: str):
    """Добавить секрет в GitHub репозиторий."""
    owner, repo_name = repo.split("/")
    
    # Получить публичный ключ репозитория
    url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/public-key"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        print(f"❌ Ошибка получения публичного ключа: {response.status_code}")
        print(response.text)
        return False
    
    public_key_data = response.json()
    key_id = public_key_data["key_id"]
    public_key = public_key_data["key"]
    
    # Зашифровать секрет (требует PyNaCl)
    try:
        from nacl import encoding, public
    except ImportError:
        print("❌ Установите PyNaCl: pip install pynacl")
        print("Или используйте скрипт add-github-secrets.sh с GitHub CLI")
        return False
    
    public_key_obj = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key_obj)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    encrypted_value = base64.b64encode(encrypted).decode("utf-8")
    
    # Отправить секрет
    url = f"https://api.github.com/repos/{owner}/{repo_name}/actions/secrets/{secret_name}"
    data = {
        "encrypted_value": encrypted_value,
        "key_id": key_id
    }
    
    response = requests.put(url, headers=headers, json=data)
    if response.status_code in [201, 204]:
        print(f"✅ {secret_name} добавлен")
        return True
    else:
        print(f"❌ Ошибка добавления {secret_name}: {response.status_code}")
        print(response.text)
        return False


def main():
    print("🔐 GitHub Secrets Setup Script (Python)")
    print("=========================================")
    print("")
    
    # Получить токен
    token = get_github_token()
    if not token:
        print("❌ GitHub token обязателен")
        sys.exit(1)
    
    # Запрос данных
    repo = input("GitHub репозиторий (формат: owner/repo): ").strip()
    server_host = input("IP или домен сервера (SERVER_HOST): ").strip()
    server_user = input("Пользователь SSH (SERVER_USER) [deploy]: ").strip() or "deploy"
    
    ssh_key_path = input("Путь к приватному SSH ключу [~/.ssh/id_ed25519]: ").strip() or "~/.ssh/id_ed25519"
    ssh_key_path = Path(ssh_key_path).expanduser()
    
    if not ssh_key_path.exists():
        print(f"❌ Файл SSH ключа не найден: {ssh_key_path}")
        sys.exit(1)
    
    ssh_key = ssh_key_path.read_text()
    
    print("")
    print("📋 Будут добавлены секреты:")
    print(f"  Репозиторий: {repo}")
    print(f"  SERVER_HOST: {server_host}")
    print(f"  SERVER_USER: {server_user}")
    print(f"  SERVER_SSH_KEY: [из файла {ssh_key_path}]")
    print("")
    
    confirm = input("Продолжить? (y/n): ").strip().lower()
    if confirm != "y":
        print("Отменено")
        sys.exit(0)
    
    print("")
    print("🔄 Добавление секретов...")
    
    # Добавить секреты
    success = True
    success &= add_secret(repo, "SERVER_HOST", server_host, token)
    success &= add_secret(repo, "SERVER_USER", server_user, token)
    success &= add_secret(repo, "SERVER_SSH_KEY", ssh_key, token)
    
    if success:
        print("")
        print("✅ Все секреты успешно добавлены!")
    else:
        print("")
        print("❌ Произошли ошибки при добавлении секретов")
        sys.exit(1)


if __name__ == "__main__":
    main()

