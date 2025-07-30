#!/bin/bash

# --------------------------------------
# 🚀 Project 1: Bootstrap Remote Ubuntu Server
# --------------------------------------
# 🧾 GOAL:
# Download and run this script locally to:
# 1. Connect to a remote Ubuntu server using SSH with root password.
# 2. Create a new sudo user.
# 3. Set up Ansible + dependencies.
# 4. Clone a Git repo for the next phase.
# 5. Set up key-based login.
# 6. Secure the server by disabling password logins and root SSH.

# --------------------------------------
# 📥 CLI ARGUMENT PARSING + HELP
# --------------------------------------

show_help() {
  echo -e "\n🔧 Usage: ./bootstrap.sh [options]"
  echo -e "\nOPTIONS:"
  echo "  --ip         <IPv4>        Required. Remote Ubuntu server IP (e.g. 192.168.1.10)"
  echo "  --user       <username>    Required. New sudo user to create"
  echo "  --pass       <password>    Required. Password for the new user"
  echo "  --rootpass   <password>    Required. Root SSH password"
  echo "  --repo       <URL>         Required. Git repo to clone (e.g. https://github.com/user/repo.git)"
  echo "  --help                     Show this help message"
  echo -e "\n💡 Example:"
  echo './bootstrap.sh --ip 192.168.1.10 --user somniac --pass StrongPass1 --rootpass RootPass123 --repo https://github.com/user/bootstrap.git'
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip) SERVER_IP="$2"; shift 2 ;;
    --user) NEW_USER="$2"; shift 2 ;;
    --pass) NEW_PASS="$2"; shift 2 ;;
    --rootpass) ROOT_PASS="$2"; shift 2 ;;
    --repo) GIT_REPO="$2"; shift 2 ;;
    --help) show_help ;;
    *) echo "❌ Unknown option: $1"; show_help ;;
  esac
done

# --------------------------------------
# 🌐 VALIDATE INPUT
# --------------------------------------

while [[ -z "$SERVER_IP" || ! "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; do
  read -rp "🌐 Enter server IP address: " SERVER_IP
  [[ "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || echo "❌ Invalid IP format."
done

while [[ -z "$NEW_USER" || ! "$NEW_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; do
  read -rp "👤 Enter new sudo username: " NEW_USER
done

while [[ -z "$NEW_PASS" || ${#NEW_PASS} -lt 8 || ! "$NEW_PASS" =~ [A-Z] || ! "$NEW_PASS" =~ [a-z] || ! "$NEW_PASS" =~ [0-9] ]]; do
  read -rsp "🔑 Enter password for '$NEW_USER': " NEW_PASS
  echo
done

while [[ -z "$ROOT_PASS" ]]; do
  read -rsp "🛡️  Enter root password: " ROOT_PASS
  echo
done

while [[ -z "$GIT_REPO" || ! "$GIT_REPO" =~ ^https:\/\/[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+(\.git)?$ ]]; do
  read -rp "📦 Enter Git repo URL: " GIT_REPO
done

# --------------------------------------
# 🔐 TEST SSH CONNECTION
# --------------------------------------

echo -e "\n🔐 Testing SSH connection to $SERVER_IP as root..."

if ! command -v sshpass >/dev/null 2>&1; then
  echo "📦 Installing sshpass..."
  sudo apt-get update -qq && sudo apt-get install -y sshpass
fi

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$SERVER_IP" "echo '✅ Connected as root.'" || {
  echo "❌ Connection failed."
  exit 1
}

# --------------------------------------
# 👤 CREATE NEW USER
# --------------------------------------

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" << EOF
echo -e "\n👤 Creating new sudo user '$NEW_USER'..."

if id "$NEW_USER" &>/dev/null; then
  echo "ℹ️  User exists."
else
  adduser --disabled-password --gecos "" "$NEW_USER"
  echo "$NEW_USER:$NEW_PASS" | chpasswd
  usermod -aG sudo "$NEW_USER"
  echo "✅ User '$NEW_USER' added to sudo."
fi
EOF

# --------------------------------------
# 🔑 SETUP SSH KEY
# --------------------------------------

echo -e "\n🔑 Generating SSH key (if needed)..."
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 4096 -C "bootstrap@local" -N "" -f "$HOME/.ssh/id_rsa"
fi

echo "🚀 Copying key to $NEW_USER@$SERVER_IP..."
sshpass -p "$NEW_PASS" ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" <<EOF
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "$(cat ~/.ssh/id_rsa.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF

echo "🧪 Verifying SSH key login..."
if ssh -o PasswordAuthentication=no "$NEW_USER@$SERVER_IP" "whoami" | grep -q "$NEW_USER"; then
  echo "✅ SSH key login works."
else
  echo "❌ SSH key login failed."
fi

# --------------------------------------
# ⚙️ INSTALL ANSIBLE & DEPENDENCIES (as NEW_USER)
# --------------------------------------

ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" <<EOF
echo "$NEW_PASS" | sudo -S bash -c '
add-apt-repository universe -y
apt-get update -qq
apt-get install -y python3 python3-pip git ansible software-properties-common

echo -e "\n✅ Versions:"
ansible --version | head -n1
python3 --version
git --version
'
EOF

# --------------------------------------
# 📦 CLONE GIT REPO (as NEW_USER)
# --------------------------------------

ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" <<EOF
echo -e "\n📦 Cloning repository..."

mkdir -p /tmp/bootstrap-repo
cd /tmp/bootstrap-repo

if [ -d ".git" ]; then
  git pull
else
  git clone "$GIT_REPO" .
fi

echo "✅ Repo ready in /tmp/bootstrap-repo"
EOF

# --------------------------------------
# 🔒 DISABLE PASSWORD LOGIN FOR ALL USERS EXCEPT ROOT
# --------------------------------------

ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" <<EOF
echo -e "\n🔐 Disabling password login globally (except root)..."

echo "$NEW_PASS" | sudo -S bash -c '
# 1. Backup main config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 2. Remove "PasswordAuthentication" from ALL override conf files
for file in /etc/ssh/sshd_config.d/*.conf; do
  if grep -q "^PasswordAuthentication" "\$file"; then
    echo "🧹 Cleaning override: \$file"
    sed -i "/^PasswordAuthentication/d" "\$file"
  fi
done

# 3. Sanitize main sshd_config
sed -i "/^PasswordAuthentication/d" /etc/ssh/sshd_config
sed -i "/^Match User /,+2d" /etc/ssh/sshd_config

# 4. Enforce password disable globally, except root
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo -e "\nMatch User root\n  PasswordAuthentication yes" >> /etc/ssh/sshd_config

# 5. Restart SSH
systemctl restart ssh
'

echo "✅ Password login disabled (except root)."
EOF

# --------------------------------------
# 🔒 Disable Root SSH Access (with override file cleanup)
# --------------------------------------

echo -e "\n🧪 Verifying SSH key login for $NEW_USER@$SERVER_IP before disabling root access..."

if ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" "whoami" | grep -q "$NEW_USER"; then
  echo "✅ Key-based login verified for $NEW_USER. Proceeding to disable root SSH access..."

  ssh -t "$NEW_USER@$SERVER_IP" bash <<EOF
echo "$NEW_PASS" | sudo -S bash -c '
  echo -e "\n🔒 Disabling remote root SSH login..."

  # 1. Backup sshd_config
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  # 2. Remove conflicting overrides (PermitRootLogin)
  for file in /etc/ssh/sshd_config.d/*.conf; do
    if grep -q "^PermitRootLogin" "\$file"; then
      echo "🧹 Cleaning override in \$file..."
      sed -i "/^PermitRootLogin/d" "\$file"
    fi
  done

  # 3. Clean main config
  sed -i "/^PermitRootLogin/d" /etc/ssh/sshd_config
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config

  # 4. Restart SSH
  systemctl restart ssh

  echo "✅ Remote root SSH login is now disabled, including overrides."
'
EOF

else
  echo "❌ Key-based login for $NEW_USER failed. Root SSH access NOT disabled to prevent lockout."
fi


