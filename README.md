# Install Luxtorpeda on Steam Deck / Desktop Linux
## _Run OpenMW, Daggerfall Unity, etc. through Steam._

### Instructions:
1) Go to https://luxtorpeda.lol
2) Run the installer.

### To run from the command line:
```bash
# Run as your user! Do not run as root or with sudo.
rm -f /tmp/install-luxtorpeda.sh; curl -S -s -L -O --output-dir /tmp --connect-timeout 60 "https://github.com/MrAwesome/luxtorpeda-openmw-helpers/raw/main/install-luxtorpeda.sh"; bash -x /tmp/install-luxtorpeda.sh
```
