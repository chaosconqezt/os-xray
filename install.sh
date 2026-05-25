#!/bin/sh
# Чистый инсталлятор плагина os-xray для OPNsense

set -e

PLUGIN_VERSION="3.0.0"
PLUGIN_DIR="$(dirname "$0")/plugin"
VERSION_FILE="/usr/local/opnsense/mvc/app/models/OPNsense/Xray/version.txt"

# ─── УДАЛЕНИЕ ────────────────────────────────────────────────────────────────
if [ "$1" = "uninstall" ]; then
    echo "=> Сносим плагин и все хвосты..."
    /usr/local/opnsense/scripts/Xray/xray-service-control.php stop 2>/dev/null || true
    
    # Вычищаем PID'ы, локи, флаги и сгенерированные конфиги
    rm -f /var/run/xray_core*.pid /var/run/tun2socks*.pid
    rm -f /var/run/xray_start*.lock /var/run/xray_stopped*.flag
    rm -f /usr/local/etc/xray-core/config-*.json
    rm -f /usr/local/tun2socks/config-*.yaml
    
    # Сносим файлы плагина
    rm -rf /usr/local/opnsense/scripts/Xray
    rm -rf /usr/local/opnsense/mvc/app/models/OPNsense/Xray
    rm -rf /usr/local/opnsense/mvc/app/controllers/OPNsense/Xray
    rm -rf /usr/local/opnsense/mvc/app/views/OPNsense/Xray
    rm -f /usr/local/opnsense/service/conf/actions.d/actions_xray.conf
    rm -f /usr/local/etc/inc/plugins.inc.d/xray.inc
    rm -f /usr/local/etc/rc.syshook.d/start/50-xray
    rm -f /usr/local/etc/newsyslog.conf.d/xray.conf
    
    echo "=> Перезапускаем configd..."
    service configd restart
    rm -f /var/lib/php/tmp/opnsense_menu_cache.xml
    echo "=> Удалено. Обнови страницу в браузере (Ctrl+F5)."
    exit 0
fi

# ─── УСТАНОВКА ───────────────────────────────────────────────────────────────
echo "=> Установка os-xray v${PLUGIN_VERSION}..."

if [ ! -d "$PLUGIN_DIR" ]; then
    echo "[ОШИБКА] Директория с файлами плагина ($PLUGIN_DIR) не найдена."
    exit 1
fi

if [ ! -f /usr/local/bin/xray-core ]; then
    echo "=> Скачиваем xray-core..."
    fetch -q -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-freebsd-64.zip
    unzip -q -o /tmp/xray.zip xray -d /tmp/
    install -m 0755 /tmp/xray /usr/local/bin/xray-core
    rm -f /tmp/xray.zip /tmp/xray
fi

if [ ! -f /usr/local/tun2socks/tun2socks ]; then
    echo "=> Скачиваем tun2socks..."
    fetch -q -o /tmp/t2s.zip https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/tun2socks-freebsd-amd64.zip
    unzip -q -o /tmp/t2s.zip tun2socks-freebsd-amd64 -d /tmp/
    mkdir -p /usr/local/tun2socks
    install -m 0755 /tmp/tun2socks-freebsd-amd64 /usr/local/tun2socks/tun2socks
    rm -f /tmp/t2s.zip /tmp/tun2socks-freebsd-amd64
fi

echo "=> Раскидываем файлы по системе..."

mkdir -p /usr/local/opnsense/scripts/Xray
mkdir -p /usr/local/opnsense/service/conf/actions.d
mkdir -p /usr/local/opnsense/mvc/app/models/OPNsense/Xray
mkdir -p /usr/local/opnsense/mvc/app/controllers/OPNsense/Xray
mkdir -p /usr/local/opnsense/mvc/app/views/OPNsense/Xray
mkdir -p /usr/local/etc/inc/plugins.inc.d
mkdir -p /usr/local/etc/rc.syshook.d/start
mkdir -p /usr/local/etc/newsyslog.conf.d
mkdir -p /usr/local/etc/xray-core

cp -fR "$PLUGIN_DIR/scripts/Xray/"* /usr/local/opnsense/scripts/Xray/
cp -f "$PLUGIN_DIR/service/conf/actions.d/actions_xray.conf" /usr/local/opnsense/service/conf/actions.d/
cp -fR "$PLUGIN_DIR/mvc/app/models/OPNsense/Xray/"* /usr/local/opnsense/mvc/app/models/OPNsense/Xray/
cp -fR "$PLUGIN_DIR/mvc/app/controllers/OPNsense/Xray/"* /usr/local/opnsense/mvc/app/controllers/OPNsense/Xray/
cp -fR "$PLUGIN_DIR/mvc/app/views/OPNsense/Xray/"* /usr/local/opnsense/mvc/app/views/OPNsense/Xray/
cp -f "$PLUGIN_DIR/etc/inc/plugins.inc.d/xray.inc" /usr/local/etc/inc/plugins.inc.d/
cp -f "$PLUGIN_DIR/etc/newsyslog.conf.d/xray.conf" /usr/local/etc/newsyslog.conf.d/
cp -f "$PLUGIN_DIR/etc/rc.syshook.d/start/50-xray" /usr/local/etc/rc.syshook.d/start/

echo "$PLUGIN_VERSION" > "$VERSION_FILE"

chmod +x /usr/local/opnsense/scripts/Xray/*.php
chmod +x /usr/local/etc/rc.syshook.d/start/50-xray

echo "=> Перезапускаем configd и чистим кеш веб-интерфейса..."
service configd restart
rm -f /var/lib/php/tmp/opnsense_menu_cache.xml

echo "=> Готово! Заходи в веб-интерфейс OPNsense (VPN -> Xray)."
