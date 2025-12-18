#!/usr/bin/env python3
"""
Автоматическое создание GitHub репозитория и добавление секретов
Работает через GitHub API, требует только Python и токен
"""

import os
import sys
import json
import base64
from pathlib import Path
from getpass import getpass

try:
    import requests
except ImportError:
    print("❌ Установите requests: pip install requests")
    sys.exit(1)

try:
    from nacl import encoding, public
except ImportError:
    print("❌ Установите PyNaCl: pip install pynacl")
    print("Выполните: pip install pynacl")
    sys.exit(1)


def get_github_token():
    """Получить GitHub token."""
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("\n🔐 Требуется GitHub Personal Access Token")
        print("Создайте токен: https://github.com/settings/tokens")
        print("Права: repo (полный доступ к репозиториям)")
        token = getpass("Введите токен: ")
    return token


def encrypt_secret(public_key: str, secret_value: str) -> tuple[str, str]:
    """Зашифровать секрет для GitHub."""
    public_key_obj = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key_obj)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    encrypted_value = base64.b64encode(encrypted).decode("utf-8")
    return encrypted_value


def get_repo_public_key(owner: str, repo: str, token: str) -> tuple[str, str]:
    """Получить публичный ключ репозитория."""
    url = f"https://api.github.com/repos/{owner}/{repo}/actions/secrets/public-key"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.get(url, headers=headers)
    if response.status_code != 200:
        raise Exception(f"Ошибка получения ключа: {response.status_code} - {response.text}")
    
    data = response.json()
    return data["key_id"], data["key"]


def create_repo(owner: str, repo_name: str, description: str, is_private: bool, token: str) -> bool:
    """Создать репозиторий в GitHub."""
    url = "https://api.github.com/user/repos" if owner == "user" else f"https://api.github.com/orgs/{owner}/repos"
    
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    data = {
        "name": repo_name,
        "description": description,
        "private": is_private
    }
    
    response = requests.post(url, headers=headers, json=data)
    if response.status_code == 201:
        print(f"✅ Репозиторий {owner}/{repo_name} создан")
        return True
    elif response.status_code == 422:
        print(f"⚠️  Репозиторий {owner}/{repo_name} уже существует")
        return True
    else:
        print(f"❌ Ошибка создания репозитория: {response.status_code}")
        print(response.text)
        return False


def add_secret(owner: str, repo: str, secret_name: str, secret_value: str, token: str) -> bool:
    """Добавить секрет в репозиторий."""
    try:
        key_id, public_key = get_repo_public_key(owner, repo, token)
        encrypted_value = encrypt_secret(public_key, secret_value)
        
        url = f"https://api.github.com/repos/{owner}/{repo}/actions/secrets/{secret_name}"
        headers = {
            "Authorization": f"token {token}",
            "Accept": "application/vnd.github.v3+json"
        }
        
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
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return False


def setup_git_repo(repo_path: Path, repo_url: str):
    """Настроить git репозиторий."""
    import subprocess
    
    # Инициализировать git если нужно
    if not (repo_path / ".git").exists():
        subprocess.run(["git", "init"], cwd=repo_path, check=True)
        subprocess.run(["git", "branch", "-M", "main"], cwd=repo_path, check=True)
        print("✅ Git инициализирован")
    
    # Добавить remote
    try:
        subprocess.run(["git", "remote", "remove", "origin"], cwd=repo_path, 
                      stderr=subprocess.DEVNULL, check=False)
    except:
        pass
    
    subprocess.run(["git", "remote", "add", "origin", repo_url], cwd=repo_path, check=True)
    print("✅ Remote origin добавлен")


def main():
    print("🚀 Автоматическое создание GitHub репозитория")
    print("=" * 50)
    print()
    
    # Получить токен
    token = get_github_token()
    if not token:
        print("❌ GitHub token обязателен")
        sys.exit(1)
    
    # Проверить токен
    headers = {"Authorization": f"token {token}"}
    response = requests.get("https://api.github.com/user", headers=headers)
    if response.status_code != 200:
        print("❌ Неверный токен или нет доступа")
        sys.exit(1)
    
    user_data = response.json()
    default_owner = user_data.get("login", "")
    
    # Запрос данных
    print("📋 Введите данные:")
    repo_name = input(f"Название репозитория: ").strip()
    owner = input(f"GitHub username/org [{default_owner}]: ").strip() or default_owner
    description = input("Описание [BoofMebel API]: ").strip() or "BoofMebel API"
    is_private_input = input("Приватный репозиторий? (y/n) [n]: ").strip().lower()
    is_private = is_private_input == "y"
    
    print()
    print("📋 Настройка сервера:")
    server_host = input("IP или домен сервера: ").strip()
    server_user = input("Пользователь SSH [deploy]: ").strip() or "deploy"
    
    ssh_key_path = input("Путь к SSH ключу [~/.ssh/id_ed25519]: ").strip() or "~/.ssh/id_ed25519"
    ssh_key_path = Path(ssh_key_path).expanduser()
    
    if not ssh_key_path.exists():
        print(f"❌ SSH ключ не найден: {ssh_key_path}")
        create = input("Создать новый ключ? (y/n): ").strip().lower()
        if create == "y":
            import subprocess
            subprocess.run(["ssh-keygen", "-t", "ed25519", "-C", "github-actions@server", 
                          "-f", str(ssh_key_path), "-N", ""], check=True)
            print(f"✅ SSH ключ создан: {ssh_key_path}")
            print(f"Добавьте публичный ключ на сервер: cat {ssh_key_path}.pub")
        else:
            sys.exit(1)
    
    ssh_key = ssh_key_path.read_text()
    
    print()
    print("📋 Будет создано:")
    print(f"  Репозиторий: {owner}/{repo_name}")
    print(f"  Описание: {description}")
    print(f"  Приватный: {is_private}")
    print(f"  SERVER_HOST: {server_host}")
    print(f"  SERVER_USER: {server_user}")
    print()
    
    confirm = input("Продолжить? (y/n): ").strip().lower()
    if confirm != "y":
        print("Отменено")
        sys.exit(0)
    
    print()
    print("🔄 Создание репозитория...")
    
    # Создать репозиторий
    if not create_repo(owner, repo_name, description, is_private, token):
        sys.exit(1)
    
    full_repo = f"{owner}/{repo_name}"
    repo_url = f"https://github.com/{full_repo}.git"
    
    # Настроить git
    repo_path = Path.cwd()
    print()
    print("🔄 Настройка git...")
    setup_git_repo(repo_path, repo_url)
    
    # Добавить секреты
    print()
    print("🔐 Добавление секретов...")
    success = True
    success &= add_secret(owner, repo_name, "SERVER_HOST", server_host, token)
    success &= add_secret(owner, repo_name, "SERVER_USER", server_user, token)
    success &= add_secret(owner, repo_name, "SERVER_SSH_KEY", ssh_key, token)
    
    if not success:
        print("❌ Произошли ошибки при добавлении секретов")
        sys.exit(1)
    
    # Первый коммит
    print()
    print("📤 Подготовка первого коммита...")
    import subprocess
    
    # Добавить .gitignore если нет
    gitignore = repo_path / ".gitignore"
    if not gitignore.exists():
        gitignore.write_text("""# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
logs/
*.log

# Database
*.db
*.sqlite
*.sqlite3

# OS
.DS_Store
Thumbs.db
""")
        print("✅ .gitignore создан")
    
    # Коммит и push
    try:
        subprocess.run(["git", "add", "."], cwd=repo_path, check=True, 
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(["git", "commit", "-m", "Initial commit: FastAPI backend with auth and deploy setup"], 
                      cwd=repo_path, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("✅ Коммит создан")
        
        subprocess.run(["git", "push", "-u", "origin", "main"], cwd=repo_path, 
                      check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("✅ Код отправлен в репозиторий")
    except subprocess.CalledProcessError as e:
        print(f"⚠️  Git операции пропущены (возможно, уже есть коммиты или нет доступа)")
    
    print()
    print("=" * 50)
    print("✅ Готово!")
    print()
    print(f"📋 Репозиторий: https://github.com/{full_repo}")
    print("📋 Секреты добавлены: SERVER_HOST, SERVER_USER, SERVER_SSH_KEY")
    print()
    print("🔍 Проверить секреты:")
    print(f"  https://github.com/{full_repo}/settings/secrets/actions")
    print()
    print("🚀 Следующий шаг: Настроить деплой на сервере")
    print("  См. DEPLOY_CHECKLIST.md")


if __name__ == "__main__":
    main()

