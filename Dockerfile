# Repo Cortex - Dockerfile
# Multi-stage build for Linux containers (default)
# Supports: PowerShell + Python 3.10+ + ChromaDB + codemunch-pro

# Stage 1: Base image with PowerShell
FROM mcr.microsoft.com/powershell:lts-7.4-ubuntu-22.04 AS base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PSModulePath="/root/.local/share/powershell/Modules:/opt/microsoft/powershell/7/Modules" \
    LLM_WORKFLOW_TOOLKIT_SOURCE="/opt/llm-workflow/module/LLMWorkflow/templates/tools"

# Install Python 3.10+ and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Ensure python command points to python3
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Stage 2: Install Python dependencies
FROM base AS python-deps

COPY requirements.lock.txt /tmp/requirements.lock.txt

# Install from lock file with hash verification
RUN python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install -r /tmp/requirements.lock.txt --require-hashes

# Verify installations
RUN python -c "import chromadb; print('ChromaDB version:', chromadb.__version__)" && \
    codemunch-pro --version || echo "codemunch-pro installed"

# Stage 3: Final image
FROM base AS final

# Copy Python packages from python-deps stage (explicit Python 3.10 path)
COPY --from=python-deps /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=python-deps /usr/local/bin /usr/local/bin

# Create working directories
RUN mkdir -p /opt/llm-workflow \
    /workspace \
    /root/.llm-workflow \
    /root/.mempalace/palace

# Copy module and toolkit files
COPY module/ /opt/llm-workflow/module/
COPY tools/ /opt/llm-workflow/tools/
COPY docker/ /opt/llm-workflow/docker/

# Install PowerShell module (dynamically detect version from manifest)
RUN pwsh -NoProfile -Command "\
    \$manifestPath = '/opt/llm-workflow/module/LLMWorkflow/LLMWorkflow.psd1'; \
    \$manifest = Import-PowerShellDataFile -Path \$manifestPath; \
    \$moduleVersion = \$manifest.ModuleVersion; \
    \$ModulePath = '/root/.local/share/powershell/Modules/LLMWorkflow/' + \$moduleVersion; \
    New-Item -ItemType Directory -Path \$ModulePath -Force | Out-Null; \
    Copy-Item -Path '/opt/llm-workflow/module/LLMWorkflow/*' -Destination \$ModulePath -Recurse -Force; \
    Import-Module LLMWorkflow -Force; \
    Write-Host \"LLMWorkflow module v\$moduleVersion installed successfully\""

# Copy entrypoint script
COPY docker/entrypoint.sh /opt/llm-workflow/entrypoint.sh
RUN sed -i 's/\r$//' /opt/llm-workflow/entrypoint.sh && \
    chmod +x /opt/llm-workflow/entrypoint.sh

# Set working directory
WORKDIR /workspace

# Volume for persistent data
VOLUME ["/workspace", "/root/.mempalace/palace"]

# Entrypoint
ENTRYPOINT ["/bin/bash", "/opt/llm-workflow/entrypoint.sh"]

# Default command
CMD ["llmup"]

# Labels
LABEL org.opencontainers.image.title="Repo Cortex" \
      org.opencontainers.image.description="Repo Cortex workflow toolkit for AI-assisted development, retrieval, governance, and persistent project memory" \
      org.opencontainers.image.version="0.9.6" \
      org.opencontainers.image.source="https://github.com/DocDamage/RepoCortex" \
      org.opencontainers.image.licenses="MIT"
