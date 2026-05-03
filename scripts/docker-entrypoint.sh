#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
# and fix volume ownership only when a remap is needed
changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

if [ "$changed" = "1" ]; then
    chown -R node:node /paperclip
fi

# Koenig customization 2026-04-30: set default agent commit identity to a GitHub-recognized
# noreply email so Vercel's Commit Author Email Verification passes. Agents may still override
# with their own role-specific identity at commit time; this is just the safe default.
gosu node git config --global user.name "Koenig Engineering Bot" 2>/dev/null || true
gosu node git config --global user.email "246262476+Vardaan97@users.noreply.github.com" 2>/dev/null || true
gosu node git config --global init.defaultBranch main 2>/dev/null || true
gosu node git config --global --add safe.directory '*' 2>/dev/null || true

# Koenig customization 2026-05-03 (V5.1): install hermes-agent into the container venv
# and expose `hermes` on PATH. Source is bind-mounted at /paperclip/.hermes/hermes-agent.
# Idempotent — only installs if hermes_agent module is missing.
HERMES_SRC="/paperclip/.hermes/hermes-agent"
HERMES_VENV="/opt/hermes-venv"

if [ -d "$HERMES_SRC" ]; then
    # Install hermes-agent into venv if not already importable.
    # Skip the editable install conflict by using regular install.
    if ! "${HERMES_VENV}/bin/python" -c "import hermes_agent" 2>/dev/null; then
        echo "Installing hermes-agent into ${HERMES_VENV}..."
        # Use --no-deps if dependencies are already satisfied; full install otherwise.
        "${HERMES_VENV}/bin/pip" install --quiet --no-cache-dir "${HERMES_SRC}" 2>&1 | tail -5 \
            || echo "WARN: hermes-agent install failed — hermes_local agents will fail until fixed"
    fi

    # Expose hermes on PATH at /usr/local/bin/hermes.
    # We force-recreate the symlink each boot to recover from any prior bind-mount mistakes.
    if [ -x "${HERMES_VENV}/bin/hermes" ]; then
        rm -f /usr/local/bin/hermes 2>/dev/null || true
        ln -sf "${HERMES_VENV}/bin/hermes" /usr/local/bin/hermes
        echo "hermes wrapper installed at /usr/local/bin/hermes -> ${HERMES_VENV}/bin/hermes"
    fi

    # hermes-py wrapper (legacy, kept for compatibility).
    if [ ! -x /usr/local/bin/hermes-py ]; then
        printf '#!/bin/sh\nexec %s/bin/hermes "$@"\n' "${HERMES_VENV}" > /usr/local/bin/hermes-py
        chmod +x /usr/local/bin/hermes-py
        ln -sf /usr/local/bin/hermes-py /usr/local/bin/hermes-container 2>/dev/null || true
    fi
else
    echo "WARN: hermes-agent source not found at ${HERMES_SRC} — bind-mount ~/.hermes into /paperclip/.hermes"
fi

exec gosu node "$@"
