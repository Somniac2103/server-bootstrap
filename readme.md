🚀 Ubuntu Bootstrap Script

Instantly set up and secure a remote Ubuntu server — no manual fiddling.

Whether you're prepping for Ansible provisioning or just tired of typing the same SSH commands over and over, this script does the dirty work for you.

---

⚡️ Quick Start

📦 Requirements

- 🐧 Remote Ubuntu Server (root SSH access)
- 💻 Local machine with Bash (Linux/macOS)
- 🔐 [`sshpass`](https://linux.die.net/man/1/sshpass) (auto-installed if missing)

---

🔧 Run with Arguments (Non-Interactive)

```bash
./bootstrap.sh \
  --ip 192.168.1.10 \
  --user devops \
  --pass MySecurePass1 \
  --rootpass RootPass123 \
  --repo https://github.com/myuser/bootstrap.git
💡 Need help?

./bootstrap.sh --help

🤖 Or Run with Prompts (Interactive Mode)
Just run it without arguments, and it’ll guide you step-by-step with validation:

./bootstrap.sh

You’ll be prompted for:

🧠 Server IP
👤 New username
🔑 Secure password (with rules)
🔐 Root password
📦 Git repo URL

🧠 What It Does

All from your local machine:

🧠 Validates all inputs (args or prompts)
🔐 Connects to the remote server via root SSH
👤 Creates a new sudo user
🔑 Generates and deploys SSH keys
⚙️ Installs Python, Git, Ansible & dependencies
📦 Clones your Git repo into /tmp/bootstrap-repo
🔒 Locks things down:
    Disables password login globally (except for root)
    Disables SSH login for root entirely 
📄 Saves a full report locally with all critical info

📥 CLI Arguments
Flag	Description	Required
--ip	Remote server IP (e.g. 192.168.1.10)	✅
--user	New sudo user to create	✅
--pass	Password for the new user	✅
--rootpass	Root password for SSH login	✅
--repo	Git repo to clone	✅
--help	Show usage guide	❌

✨ Omit any of these to be prompted interactively.

---

🔐 Security Notes

✅ Password login is disabled for all users (except root)
✅ SSH root login is fully disabled after key login verification

✅ New user is secured with SSH key-based login only

📄 A bootstrap_report.txt file is saved locally with sensitive info

⚠️ Move or encrypt the report file after reviewing it!

📄 Output Report

You'll find a report at:
/home/yourname/bootstrap_report.txt

It includes:
    🌐 Server IP
    👤 Username & password
    🔑 Public SSH key used
    📦 Git repo & clone location
    🔒 Security settings applied

🛡️ Example:

    🚀 Bootstrap Report
    ---------------------
    📌 Server IP:         192.168.1.10
    👤 Username:          devops
    🔑 User Password:     *********
    🔐 Root Password:     *********
    📦 Git Repo:          https://github.com/myuser/bootstrap.git
    📁 Cloned To:         /tmp/bootstrap-repo
    🔐 Public Key:
    ssh-rsa AAAAB3...
    🔒 Sensitive file — store it safely!

mv ~/bootstrap_report.txt ~/secure-location/

🪪 License
MIT — free to use, modify, and automate your life.

🧃 Bonus
☕ Found this helpful? Star the repo, contribute improvements, or drop a thank-you in the issues! Your future self (and other sysadmins) will appreciate it.