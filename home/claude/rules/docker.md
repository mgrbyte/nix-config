---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/compose*.yml"
  - "**/compose*.yaml"
  - "**/.dockerignore"
---

# Docker Preferences

- Prefer uv for Docker images when the main application is Python
- Use docker compose for orchestration
- Use .dockerignore to reduce context size, especially exclude any `.<tool>_cache` directories and the `.git` directory
- Prefer the new form `docker compose` vs older `docker-compose`
