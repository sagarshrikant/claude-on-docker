# Per-project image: the base + whatever this project needs.
# Not needed? Delete this file and use  "image": "claude-base"  in devcontainer.json.
FROM claude-base

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
USER node
