#!/bin/bash

# Start all required dependencies for Metabridge

set -e

echo "🚀 Starting Metabridge Dependencies..."
echo ""

# Start PostgreSQL
echo "1️⃣  Starting PostgreSQL..."
if systemctl is-active --quiet postgresql; then
    echo "   ✓ PostgreSQL already running"
else
    sudo systemctl start postgresql
    sleep 2
    echo "   ✓ PostgreSQL started"
fi

# Start Redis
echo ""
echo "2️⃣  Starting Redis..."
if systemctl is-active --quiet redis; then
    echo "   ✓ Redis already running"
elif systemctl is-active --quiet redis-server; then
    echo "   ✓ Redis already running"
else
    if systemctl list-unit-files | grep -q redis.service; then
        sudo systemctl start redis
    elif systemctl list-unit-files | grep -q redis-server.service; then
        sudo systemctl start redis-server
    else
        echo "   ✗ Redis service not found. Please install Redis:"
        echo "     sudo apt-get install redis-server"
        exit 1
    fi
    sleep 2
    echo "   ✓ Redis started"
fi

# Start NATS (if installed as systemd service)
echo ""
echo "3️⃣  Starting NATS..."
if pgrep -x "nats-server" > /dev/null; then
    echo "   ✓ NATS already running"
elif systemctl is-active --quiet nats; then
    echo "   ✓ NATS already running"
else
    # Check if NATS is installed
    if command -v nats-server &> /dev/null; then
        # Start NATS in background
        nohup nats-server -js > /root/projects/metabridge-engine-hub/logs/nats.log 2>&1 &
        sleep 2
        echo "   ✓ NATS started (running in background)"
    else
        echo "   ⚠ NATS not found. Installing..."
        cd /tmp
        wget -q https://github.com/nats-io/nats-server/releases/download/v2.10.7/nats-server-v2.10.7-linux-amd64.tar.gz
        tar -xzf nats-server-v2.10.7-linux-amd64.tar.gz
        sudo mv nats-server-v2.10.7-linux-amd64/nats-server /usr/local/bin/
        rm -rf nats-server-v2.10.7-linux-amd64*

        # Start NATS
        nohup nats-server -js > /root/projects/metabridge-engine-hub/logs/nats.log 2>&1 &
        sleep 2
        echo "   ✓ NATS installed and started"
    fi
fi

echo ""
echo "✅ All dependencies are running!"
echo ""
echo "Next steps:"
echo "  1. Run the dependency checker: bash scripts/check-dependencies.sh"
echo "  2. Start the services:"
echo "     sudo systemctl start metabridge-api"
echo "     sudo systemctl start metabridge-relayer"
echo "     sudo systemctl start metabridge-listener"
echo "     sudo systemctl start metabridge-batcher"
echo ""
