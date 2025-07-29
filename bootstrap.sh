# TODO Project 1: Bootstrap

# TODO Goal: To create a script that can be downloaded then runned locally to create a secure link with an remote ubuntu server then install all the required programs for ansible to work and download a designated repository which will be use in the next phase of setup with ansible.

# TODO REQUIREMENTS:
# TODO: Must get and valdiate all necessary information for the process to run.
# # ----------------------------
# # 🌐 User Input & Validation
# # ----------------------------

# read -rp "🌐 Enter server IP address: " SERVER_IP
# while ! [[ "$SERVER_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; do
#   echo "❌ Invalid IP format. Use something like 192.168.1.10"
#   read -rp "🌐 Enter server IP address: " SERVER_IP
# done

# read -rp "👤 Enter NEW sudo username to create: " NEW_USER
# while ! [[ "$NEW_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; do
#   echo "❌ Invalid username. Use lowercase letters, digits, _ or - (max 32 chars, start with a letter or underscore)."
#   read -rp "👤 Enter NEW sudo username to create: " NEW_USER
# done

# read -rsp "🔑 Enter password for new user '$NEW_USER': " NEW_PASS
# echo
# while [[ ${#NEW_PASS} -lt 8 || ! "$NEW_PASS" =~ [A-Z] || ! "$NEW_PASS" =~ [a-z] || ! "$NEW_PASS" =~ [0-9] ]]; do
#   echo "❌ Password must be at least 8 characters and include upper-case, lower-case, and a digit."
#   read -rsp "🔑 Enter password for new user '$NEW_USER': " NEW_PASS
#   echo
# done

# read -rsp "🛡️  Enter root password for $SERVER_IP: " ROOT_PASS
# echo
# while [[ -z "$ROOT_PASS" ]]; do
#   echo "❌ Root password cannot be empty."
#   read -rsp "🛡️  Enter root password for $SERVER_IP: " ROOT_PASS
#   echo
# done

# read -rp "📦 Enter Git HTTPS repo URL for Phase 2: " GIT_REPO
# while ! [[ "$GIT_REPO" =~ ^https:\/\/[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+\/[a-zA-Z0-9._-]+(\.git)?$ ]]; do
#   echo "❌ Invalid Git URL. Use HTTPS format like https://github.com/user/repo.git"
#   read -rp "📦 Enter Git HTTPS repo URL for Phase 2: " GIT_REPO
# done

SERVER_IP="82.29.190.13"
NEW_USER="test"
NEW_PASS="Test123"
ROOT_PASS="N1xk4&SnwaDSC9ypyy"
GIT_REPO="https://github.com/Somniac2103/server-bootstrap"


echo -e "\n✅ Input Summary:"
echo "--------------------------"
echo "🌐 Server IP Address    : $SERVER_IP"
echo "👤 New Sudo Username    : $NEW_USER"
echo "🔑 New User Password    : $NEW_PASS"
echo "🛡️  Root Password       : $ROOT_PASS"
echo "📦 Git Repository URL   : $GIT_REPO"
echo "--------------------------"


# TODO:Must be able to link to server automatically.

# ----------------------------
# 🔐 SSH Connection Test
# ----------------------------

echo -e "\n🔐 Testing SSH connection to $SERVER_IP as root..."

# Install sshpass if not present
if ! command -v sshpass >/dev/null 2>&1; then
  echo "📦 Installing sshpass..."
  sudo apt-get update -qq && sudo apt-get install -y sshpass
fi

# Test SSH connection
sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$SERVER_IP" "echo '✅ Connected to remote server as root.'" || {
  echo "❌ Failed to connect to $SERVER_IP as root. Check password or SSH access."
  exit 1
}

# ----------------------------
# ✅ Remote Access Confirmation
# ----------------------------

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$SERVER_IP" << 'EOF'
echo -e "\n🚀 Remote connection established successfully!"
echo "🖥️  Hostname: $(hostname)"
echo "📅 Uptime   : $(uptime -p)"
echo "👤 Logged in as: $(whoami)"
EOF


# TODO: Must install all necessary programs to to enbale anisble to run a playbook on the remote server self.

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" << 'EOF'
echo -e "\n⚙️  Installing Ansible and dependencies on remote server (Ubuntu 24.04)...\n"

# Enable universe if not already
add-apt-repository universe -y
apt-get update -qq

# Install Ansible the proper Ubuntu way
apt-get install -y -qq \
  python3 \
  python3-pip \
  git \
  ansible \
  software-properties-common

# Confirm versions
echo -e "\n✅ Installed Versions:"
echo -n "Ansible: " && ansible --version | head -n1
echo -n "Python : " && python3 --version
echo -n "Git    : " && git --version
EOF

# TODO: Must download a repository on the remote server directly which will be used by anisble.

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" << EOF
echo -e "\n📦 Cloning repository into /tmp/bootstrap-repo..."

# Create directory in /tmp
mkdir -p /tmp/bootstrap-repo
cd /tmp/bootstrap-repo

# Clone or pull latest
if [ -d ".git" ]; then
  echo "🔄 Repo already exists. Pulling latest..."
  git pull
else
  git clone "$GIT_REPO" .
fi

echo -e "\n✅ Repo is ready in /tmp/bootstrap-repo"
EOF

# TODO OPTIONAL:

# TODO: Create new user, password, add to sudoer list and give necessary permission .

sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" << EOF
echo -e "\n👤 Creating new sudo user: $NEW_USER"

# Check if user already exists
if id "$NEW_USER" &>/dev/null; then
  echo "ℹ️  User '$NEW_USER' already exists."
else
  # Create user with disabled password (avoids interactive prompt)
  adduser --disabled-password --gecos "" "$NEW_USER"

  # Set the password
  echo "$NEW_USER:$NEW_PASS" | chpasswd

  # Add user to sudo group
  usermod -aG sudo "$NEW_USER"
  echo "✅ User '$NEW_USER' created and added to sudo group."
fi

# Confirm sudo access
if groups "$NEW_USER" | grep -qw "sudo"; then
  echo "🔐 '$NEW_USER' has sudo privileges."
else
  echo "❌ Failed to assign sudo to '$NEW_USER'"
  exit 1
fi
EOF

# TODO: Disable root entirely (no password or login access remotely).
# TODO: UNCOMMENT THIS SECTION TO BLOCK ROOT IN PRODUCTIONS!!!
# sshpass -p "$ROOT_PASS" ssh -o StrictHostKeyChecking=no root@"$SERVER_IP" << 'EOF'
# echo -e "\n🔒 Disabling remote root SSH login..."

# # Backup existing ssh config
# cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# # Set PermitRootLogin to no
# if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
#   sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# else
#   echo "PermitRootLogin no" >> /etc/ssh/sshd_config
# fi

# # Restart SSH to apply
# systemctl restart ssh

# echo "✅ Remote root login is now disabled."
# EOF

# TODO: Generate a ssh key on local pc and setup ssh connection with remote.

# ----------------------------
# 🔑 Generate and Configure SSH Key
# ----------------------------

echo -e "\n🔑 Setting up SSH key-based login for $NEW_USER@$SERVER_IP..."

# 1. Generate SSH key if it doesn't exist
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
  echo "🛠️  Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -C "bootstrap@local" -N "" -f "$HOME/.ssh/id_rsa"
else
  echo "📎 SSH key already exists: $HOME/.ssh/id_rsa"
fi

# 2. Copy public key to remote user's authorized_keys
echo "🚀 Copying public key to remote server..."
sshpass -p "$NEW_PASS" ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" <<EOF
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo "$(cat $HOME/.ssh/id_rsa.pub)" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF

# 3. Test login
echo "🧪 Testing SSH key login..."
if ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" "whoami" | grep -q "$NEW_USER"; then
  echo "✅ SSH key login successful for $NEW_USER@$SERVER_IP"
else
  echo "❌ SSH key login failed. Password login still required."
fi

# TODO: Disable password logon for new user remotely.
ssh -o StrictHostKeyChecking=no "$NEW_USER@$SERVER_IP" << 'EOF'
echo -e "\n🔐 Disabling password login for all users except root..."

# Backup ssh config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Remove any existing global PasswordAuthentication lines
sudo sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config

# Add global default to disable password login
echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Allow root to keep using password login
echo -e "\nMatch User root\n  PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null

# Restart SSH
sudo systemctl restart ssh

echo "✅ Password login disabled for all users except root."
EOF


# TODO: Also allow the script to run using arguments in the terminal

# TODO EXTRAS:
# TODO : Generate error for debugging.
# TODO: Log all activities in console and logfile on local computer.
# TODO: Run test check to validate all processes has been completed.
# TODO: Give a completed report with all the secret information in a file on the local pc.