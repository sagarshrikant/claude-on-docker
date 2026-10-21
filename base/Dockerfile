# Base image: Claude Code + git + ssh client, running as non-root user "node" (UID 1000).
# Build:  docker build -t claude-base base/
FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git openssh-client ca-certificates curl ripgrep less sudo \
 && rm -rf /var/lib/apt/lists/* \
 && echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node \
 && chmod 0440 /etc/sudoers.d/node \
 && ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

RUN npm install -g @anthropic-ai/claude-code

# System-wide Claude settings (outside the home volume, so they survive any reset)
COPY managed-settings.json /etc/claude-code/managed-settings.json

USER node
WORKDIR /workspace
CMD ["bash"]
