# OPTIONAL per-project image: the base + tools only this project needs.
# Only used when Option B is enabled in devcontainer.json; otherwise ignored.
# After editing: F1 -> Dev Containers: Rebuild Container
FROM claude-base

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 python3-pip \
 && rm -rf /var/lib/apt/lists/*
USER node
