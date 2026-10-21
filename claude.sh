#!/usr/bin/env bash
# Run Claude Code in a throw-away container for the current folder.
# Usage:  cd ~/projects/my-app && /path/to/claude.sh [claude args]
IMAGE="${CLAUDE_IMAGE:-claude-base}"
# Mount at /workspace/<folder-name> so each project keeps its own Claude sessions (/resume)
WS="/workspace/$(basename "$PWD")"

SSH_ARGS=()
if [ -n "$SSH_AUTH_SOCK" ]; then
  SSH_ARGS=(-v "$SSH_AUTH_SOCK":/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent)
else
  echo "Warning: no SSH agent running - git push won't work (run: eval \$(ssh-agent) && ssh-add <key>)" >&2
fi

docker run -it --rm \
  -v "$PWD":"$WS" \
  -w "$WS" \
  -v claude-home:/home/node \
  "${SSH_ARGS[@]}" \
  "$IMAGE" claude "$@"
