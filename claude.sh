#!/usr/bin/env bash
# Run Claude Code in a throw-away container for the current folder.
# Usage:  cd ~/projects/my-app && /path/to/claude.sh [claude args]
IMAGE="${CLAUDE_IMAGE:-claude-base}"

SSH_ARGS=()
if [ -n "$SSH_AUTH_SOCK" ]; then
  SSH_ARGS=(-v "$SSH_AUTH_SOCK":/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent)
else
  echo "Warning: no SSH agent running - git push won't work (run: eval \$(ssh-agent) && ssh-add <key>)" >&2
fi

docker run -it --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  -v claude-home:/home/node \
  "${SSH_ARGS[@]}" \
  "$IMAGE" claude "$@"
