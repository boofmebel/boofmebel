#!/bin/bash
# Скрипт для создания GitHub репозитория и добавления секретов
# Автоматически создаёт репозиторий, настраивает git и добавляет секреты

set -e

echo "🚀 GitHub Repository & Secrets Setup"
echo "======================================"
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки команды
check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

# Проверка GitHub CLI
USE_GH_CLI=false
if check_command gh; then
    if gh auth status &> /dev/null; then
        USE_GH_CLI=true
        echo -e "${GREEN}✅ GitHub CLI установлен и авторизован${NC}"
    else
        echo -e "${YELLOW}⚠️  GitHub CLI установлен, но не авторизован${NC}"
        echo "Выполните: gh auth login"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub CLI не установлен${NC}"
    echo "Установите: https://cli.github.com/"
    echo "Или используйте GitHub API с токеном"
fi

echo ""

# Запрос данных
read -p "Название репозитория (без owner): " REPO_NAME
read -p "GitHub username/org: " GITHUB_USER
read -p "Описание репозитория [BoofMebel API]: " REPO_DESC
REPO_DESC=${REPO_DESC:-BoofMebel API}

read -p "Приватный репозиторий? (y/n) [n]: " IS_PRIVATE
IS_PRIVATE=${IS_PRIVATE:-n}

echo ""
echo "📋 Настройка сервера:"
read -p "IP или домен сервера: " SERVER_HOST
read -p "Пользователь SSH [deploy]: " SERVER_USER
SERVER_USER=${SERVER_USER:-deploy}

read -p "Путь к приватному SSH ключу [~/.ssh/id_ed25519]: " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_ed25519}
SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ Файл SSH ключа не найден: $SSH_KEY_PATH${NC}"
    echo "Создать новый ключ? (y/n)"
    read CREATE_KEY
    if [ "$CREATE_KEY" = "y" ]; then
        ssh-keygen -t ed25519 -C "github-actions@server" -f "$SSH_KEY_PATH"
        echo -e "${GREEN}✅ SSH ключ создан${NC}"
        echo "Добавьте публичный ключ на сервер:"
        echo "  cat ${SSH_KEY_PATH}.pub"
    else
        exit 1
    fi
fi

FULL_REPO="${GITHUB_USER}/${REPO_NAME}"

echo ""
echo "📋 Будет создано:"
echo "  Репозиторий: ${FULL_REPO}"
echo "  Описание: ${REPO_DESC}"
echo "  Приватный: ${IS_PRIVATE}"
echo "  SERVER_HOST: ${SERVER_HOST}"
echo "  SERVER_USER: ${SERVER_USER}"
echo "  SERVER_SSH_KEY: ${SSH_KEY_PATH}"
echo ""

read -p "Продолжить? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Отменено"
    exit 0
fi

echo ""
echo "🔄 Создание репозитория..."

# Создание репозитория
if [ "$USE_GH_CLI" = true ]; then
    # Через GitHub CLI
    PRIVATE_FLAG=""
    if [ "$IS_PRIVATE" = "y" ]; then
        PRIVATE_FLAG="--private"
    else
        PRIVATE_FLAG="--public"
    fi
    
    gh repo create "$FULL_REPO" \
        --description "$REPO_DESC" \
        $PRIVATE_FLAG \
        --source=. \
        --remote=origin \
        --push || {
        echo -e "${YELLOW}⚠️  Репозиторий уже существует или ошибка создания${NC}"
        echo "Продолжаем с настройкой git..."
    }
else
    # Через API (требует токен)
    echo -e "${YELLOW}Использование GitHub API (требует токен)${NC}"
    read -sp "GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    
    PRIVATE_VAL="false"
    if [ "$IS_PRIVATE" = "y" ]; then
        PRIVATE_VAL="true"
    fi
    
    curl -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/user/repos \
        -d "{\"name\":\"${REPO_NAME}\",\"description\":\"${REPO_DESC}\",\"private\":${PRIVATE_VAL}}" || {
        echo -e "${RED}❌ Ошибка создания репозитория${NC}"
        exit 1
    }
    
    # Настроить git remote
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin "https://github.com/${FULL_REPO}.git"
    else
        git remote set-url origin "https://github.com/${FULL_REPO}.git"
    fi
fi

echo -e "${GREEN}✅ Репозиторий создан${NC}"

# Инициализация git (если ещё не инициализирован)
if [ ! -d ".git" ]; then
    echo "🔄 Инициализация git..."
    git init
    git branch -M main
    echo -e "${GREEN}✅ Git инициализирован${NC}"
fi

# Добавление .gitignore если нет
if [ ! -f ".gitignore" ]; then
    echo "📝 Создание .gitignore..."
    cat > .gitignore << 'EOF'
# Python
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
EOF
    echo -e "${GREEN}✅ .gitignore создан${NC}"
fi

# Добавление секретов
echo ""
echo "🔐 Добавление секретов..."

if [ "$USE_GH_CLI" = true ]; then
    # Через GitHub CLI
    SSH_KEY=$(cat "$SSH_KEY_PATH")
    
    gh secret set SERVER_HOST --repo "$FULL_REPO" --body "$SERVER_HOST"
    echo -e "${GREEN}✅ SERVER_HOST добавлен${NC}"
    
    gh secret set SERVER_USER --repo "$FULL_REPO" --body "$SERVER_USER"
    echo -e "${GREEN}✅ SERVER_USER добавлен${NC}"
    
    echo "$SSH_KEY" | gh secret set SERVER_SSH_KEY --repo "$FULL_REPO"
    echo -e "${GREEN}✅ SERVER_SSH_KEY добавлен${NC}"
else
    # Через API
    if [ -z "$GITHUB_TOKEN" ]; then
        read -sp "GitHub Personal Access Token (для секретов): " GITHUB_TOKEN
        echo ""
    fi
    
    SSH_KEY=$(cat "$SSH_KEY_PATH")
    
    # Получить публичный ключ репозитория
    PUBLIC_KEY_RESPONSE=$(curl -s \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${FULL_REPO}/actions/secrets/public-key")
    
    KEY_ID=$(echo "$PUBLIC_KEY_RESPONSE" | grep -o '"key_id":"[^"]*' | cut -d'"' -f4)
    PUBLIC_KEY=$(echo "$PUBLIC_KEY_RESPONSE" | grep -o '"key":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$KEY_ID" ] || [ -z "$PUBLIC_KEY" ]; then
        echo -e "${RED}❌ Ошибка получения публичного ключа${NC}"
        echo "Убедитесь, что токен имеет права repo"
        exit 1
    fi
    
    # Зашифровать секреты (требует Python с PyNaCl)
    echo "🔐 Шифрование секретов..."
    
    python3 << EOF
import base64
import sys
import json

try:
    from nacl import encoding, public
except ImportError:
    print("❌ Установите PyNaCl: pip install pynacl", file=sys.stderr)
    sys.exit(1)

def encrypt_secret(public_key: str, secret_value: str) -> str:
    public_key_obj = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key_obj)
    encrypted = sealed_box.encrypt(secret_value.encode("utf-8"))
    return base64.b64encode(encrypted).decode("utf-8")

public_key = "${PUBLIC_KEY}"
key_id = "${KEY_ID}"

secrets = {
    "SERVER_HOST": "${SERVER_HOST}",
    "SERVER_USER": "${SERVER_USER}",
    "SERVER_SSH_KEY": """${SSH_KEY}"""
}

for name, value in secrets.items():
    encrypted = encrypt_secret(public_key, value)
    print(f"{name}:{encrypted}:{key_id}")
EOF
    
    # Добавить секреты через API
    for secret_data in $(python3 << 'PYEOF'
import base64
import sys
try:
    from nacl import encoding, public
    public_key = "${PUBLIC_KEY}"
    key_id = "${KEY_ID}"
    secrets = {
        "SERVER_HOST": "${SERVER_HOST}",
        "SERVER_USER": "${SERVER_USER}",
        "SERVER_SSH_KEY": """${SSH_KEY}"""
    }
    public_key_obj = public.PublicKey(public_key.encode("utf-8"), encoding.Base64Encoder())
    sealed_box = public.SealedBox(public_key_obj)
    for name, value in secrets.items():
        encrypted = sealed_box.encrypt(value.encode("utf-8"))
        encrypted_b64 = base64.b64encode(encrypted).decode("utf-8")
        print(f"{name}|{encrypted_b64}")
except Exception as e:
    print(f"ERROR:{e}", file=sys.stderr)
    sys.exit(1)
PYEOF
    ); do
        if [[ $secret_data == ERROR:* ]]; then
            echo -e "${RED}${secret_data}${NC}"
            echo "Установите PyNaCl: pip install pynacl"
            exit 1
        fi
        
        IFS='|' read -r name encrypted <<< "$secret_data"
        
        curl -X PUT \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${FULL_REPO}/actions/secrets/${name}" \
            -d "{\"encrypted_value\":\"${encrypted}\",\"key_id\":\"${KEY_ID}\"}" \
            -s -o /dev/null
        
        echo -e "${GREEN}✅ ${name} добавлен${NC}"
    done
fi

# Первый коммит и push
echo ""
echo "📤 Первый коммит и push..."

if [ -z "$(git status --porcelain)" ]; then
    echo "Нет изменений для коммита"
else
    git add .
    git commit -m "Initial commit: FastAPI backend with auth and deploy setup" || echo "Коммит не создан (возможно, уже есть коммиты)"
fi

# Push в репозиторий
if git remote get-url origin &> /dev/null; then
    echo "🔄 Push в GitHub..."
    git push -u origin main || git push -u origin master || echo -e "${YELLOW}⚠️  Push не выполнен (возможно, нужно настроить доступ)${NC}"
    echo -e "${GREEN}✅ Код отправлен в репозиторий${NC}"
fi

echo ""
echo -e "${GREEN}✅ Готово!${NC}"
echo ""
echo "📋 Сводка:"
echo "  Репозиторий: https://github.com/${FULL_REPO}"
echo "  Секреты добавлены: SERVER_HOST, SERVER_USER, SERVER_SSH_KEY"
echo ""
echo "🔍 Проверить секреты:"
if [ "$USE_GH_CLI" = true ]; then
    echo "  gh secret list --repo ${FULL_REPO}"
else
    echo "  Репозиторий → Settings → Secrets and variables → Actions"
fi
echo ""
echo "🚀 Следующий шаг: Настроить деплой на сервере"
echo "  См. DEPLOY_CHECKLIST.md"

