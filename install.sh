#!/usr/bin/env bash
# Bounce Gateway — Install Script
# Copies scripts to ~/.local/bin/ and config to ~/.bounce/

set -e

INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.bounce"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/src" && pwd)"
CONFIG_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/config" && pwd)"

echo "📦 Bounce Gateway — Installing"

# 1. Create directories
mkdir -p "${INSTALL_DIR}"
mkdir -p "${CONFIG_DIR}"

# 2. Copy scripts
echo "   Copying scripts → ${INSTALL_DIR}"
cp "${SCRIPT_DIR}/bounce-gateway" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/bounce" "${INSTALL_DIR}/"
cp "${SCRIPT_DIR}/bounce-panel" "${INSTALL_DIR}/"
chmod +x "${INSTALL_DIR}/bounce"*
echo "   ✅ Scripts installed"

# 3. Copy config templates (don't overwrite existing config)
if [ -f "${CONFIG_DIR}/config.json" ]; then
    echo "   ⏭️  Config exists, keeping yours: ${CONFIG_DIR}/config.json"
else
    echo '{"providers":[],"gateway":{"port":3001,"no_demo":false}}' > "${CONFIG_DIR}/config.json"
    echo "   ✅ Default config created: ${CONFIG_DIR}/config.json"
fi

if [ -f "${CONFIG_DIR}/templates.json" ]; then
    echo "   ⏭️  Templates exist, keeping yours"
else
    cp "${CONFIG_SRC}/templates.json" "${CONFIG_DIR}/templates.json"
    echo "   ✅ Templates installed: ${CONFIG_DIR}/templates.json"
fi

# 4. Check PATH
case ":${PATH}:" in
    *:"${INSTALL_DIR}":*)
        ;;
    *)
        echo "   ⚠️  ${INSTALL_DIR} not in PATH"
        echo "   Add to ~/.bashrc: export PATH=\"\${PATH}:${INSTALL_DIR}\""
        ;;
esac

# 5. Check dependencies
echo "   Checking Python dependencies..."
python3 -c "import flask, requests" 2>/dev/null && \
    echo "   ✅ flask + requests OK" || \
    echo "   ⚠️  Run: pip install flask requests"

echo ""
echo "🎉 Bounce Gateway installed!"
echo ""
echo "   Start the Gateway:"
echo "     bounce-gateway"
echo ""
echo "   Or via CLI:"
echo "     bounce gateway start"
echo ""
echo "   First run? It'll ask if you want a free local model."
echo "   Or add cloud providers:"
echo "     bounce provider add deepseek-cp --key sk-xxx"
echo ""