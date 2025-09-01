#Squid tools by BMoore Solutions for Cuttlephish "Cuttle-Test"
#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ASCII Squid (actual squid this time!)
clear
echo -e "${MAGENTA}"
cat << "SQUID"
          🦑
          🦑🦑
          🦑🦑🦑
          🦑🦑🦑🦑
         🦑🦑🦑🦑🦑
        🦑🦑🦑🦑🦑🦑
       🦑🦑🦑🦑🦑🦑
        🦑🦑🦑🦑🦑🦑
       🦑🦑🦑🦑🦑🦑🦑
      🦑🦑🦑🦑🦑🦑🦑🦑
      🦑    🦑    🦑
      🦑    🦑    🦑
      🦑    🦑    🦑
      🦑    🦑    🦑
      🦑     🦑    🦑
      🦑      🦑    🦑
SQUID
echo -e "${CYAN}Welcome to Cuttle-Test: Your Squiddy Troubleshooter 🦑${NC}"
SQUID
echo -e "${CYAN}Welcome to Cuttle-Test: Your Squiddy Troubleshooter 🦑${NC}"
echo -e "${YELLOW}--------------------------------------------------------${NC}"

# Clipboard tool check
if command -v xclip &>/dev/null; then
    CLIP_CMD="xclip -selection clipboard"
elif command -v pbcopy &>/dev/null; then
    CLIP_CMD="pbcopy"
else
    CLIP_CMD=""
fi

# Log directory
LOG_DIR="$HOME/cuttle-logs"
mkdir -p "$LOG_DIR"

# Function to run command, copy, and archive
run_and_copy() {
    echo -e "\n${GREEN}🔍 Running: $1${NC}"
    echo -e "${YELLOW}--------------------------------------------------------${NC}"
    OUTPUT=$(eval "$1" 2>&1)
    echo "$OUTPUT"
    echo -e "${YELLOW}--------------------------------------------------------${NC}"

    # Archive log
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    LOG_FILE="$LOG_DIR/cuttle_$TIMESTAMP.log"
    echo "$OUTPUT" > "$LOG_FILE"
    echo -e "${CYAN}📁 Output saved to: $LOG_FILE${NC}"

    # Clipboard
    if [ -n "$CLIP_CMD" ]; then
        echo "$OUTPUT" | $CLIP_CMD
        echo -e "${CYAN}📋 Output copied to clipboard.${NC}"
    else
        echo -e "${RED}⚠️ Clipboard tool not found. Install xclip or pbcopy.${NC}"
    fi
}

# Auth test with user input
auth_test() {
    echo -e "${MAGENTA}Enter credentials to test authentication:${NC}"
    read -p "Username: " user
    read -s -p "Password: " pass
    echo ""
    echo -e "${CYAN}Choose helper type:${NC}"
    echo "1) NCSA"
    echo "2) PAM"
    read -p "Enter your choice [1-2]: " helper

    if [ "$helper" == "1" ]; then
        CMD="printf '$user $pass\n' | /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd"
    elif [ "$helper" == "2" ]; then
        CMD="printf '$user $pass\n' | /usr/lib/squid/basic_pam_auth -s squid"
    else
        echo -e "${RED}❌ Invalid helper choice.${NC}"
        return
    fi

    run_and_copy "$CMD"
    echo -e "${YELLOW}📡 Tailing Squid logs for activity...${NC}"
    sudo tail -n 20 /var/log/squid/access.log
}

# Run all tests with pause
run_all() {
    echo -e "${CYAN}Running all tests...${NC}"
    run_and_copy "ss -lntp | awk '/:3128/'"
    sleep 3
    run_and_copy "grep -RIn \"auth_param basic\" /etc/squid /etc/squid/conf.d"
    sleep 3
    auth_test
    sleep 3
    run_and_copy "sudo squid -k parse"
    sleep 3
    run_and_copy "sudo journalctl -u squid -n 80 --no-pager && sudo tail -n 100 /var/log/squid/access.log"
    echo -e "${GREEN}✅ All tests complete.${NC}"
}

# Menu loop
while true; do
    echo -e "\n${MAGENTA}Choose a test to run:${NC}"
    echo "1) Is Squid listening on 0.0.0.0:3128?"
    echo "2) Is auth helper wired the way you expect (NCSA or PAM)?"
    echo "3) Test authentication with username/password"
    echo "4) Any parse errors?"
    echo "5) Runtime logs"
    echo "6) Run all tests (with pauses)"
    echo "7) Exit"
    read -p "Enter your choice [1-7]: " choice

    case $choice in
        1) run_and_copy "ss -lntp | awk '/:3128/'" ;;
        2) run_and_copy "grep -RIn \"auth_param basic\" /etc/squid /etc/squid/conf.d" ;;
        3) auth_test ;;
        4) run_and_copy "sudo squid -k parse" ;;
        5) run_and_copy "sudo journalctl -u squid -n 80 --no-pager && sudo tail -n 100 /var/log/squid/access.log" ;;
        6) run_all ;;
        7) echo -e "${GREEN}👋 Farewell from Cuttle-Test. Swim safe!${NC}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Try again.${NC}" ;;
    esac
done

