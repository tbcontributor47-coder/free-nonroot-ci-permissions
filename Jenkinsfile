pipeline {
  agent { label 'Linux-01' }

  options {
    timestamps()
  }

  environment {
    // This repo's Harbor task lives at the repository root.
    TASK_PATH = '.'
    OPENAI_BASE_URL = 'https://api.portkey.ai/v1'
  }

  stages {
    stage('Preflight') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

echo "Node: $(hostname)"
echo "Workspace: $WORKSPACE"
echo "User: $(id -un)"

echo "Task path: $TASK_PATH"
if [ ! -d "$TASK_PATH" ]; then
  echo "ERROR: TASK_PATH does not exist: $TASK_PATH"
  echo "PWD: $(pwd)"
  echo "Workspace contents:"
  ls -la
  exit 1
fi

echo "Checking Docker access..."
if ! docker version >/dev/null 2>&1; then
  echo ""
  echo "ERROR: Jenkins user cannot access Docker."
  echo "To fix: Add the agent service user to the docker group and restart the agent."
  echo "Example: sudo usermod -aG docker $(id -un) && sudo systemctl restart jenkins-agent"
  exit 1
fi

        # Install Harbor CLI and ensure PATH
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source "$HOME/.local/bin/env"
        uv tool install harbor==0.1.25 --python 3.13
        export PATH="$HOME/.local/bin:$PATH"
        harbor --help >/dev/null
'''
      }
    }

    stage('Oracle') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  # Adds uv/uvx and other tool shims to PATH
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

harbor run --agent oracle --path "$TASK_PATH"
'''
      }
    }

    stage('Checks') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

harbor tasks check "$TASK_PATH" --model openai/@openai-tbench/gpt-5
'''
      }
    }

    stage('Agent Runs (optional)') {
      when {
        expression { return env.OPENAI_API_KEY?.trim() }
      }
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

echo "Running GPT-5 agent..."
harbor run -a terminus-2 -m openai/@openai-tbench/gpt-5 -p "$TASK_PATH"

echo "Running Claude Sonnet 4.5 agent..."
harbor run -a terminus-2 -m openai/@anthropic-tbench/claude-sonnet-4-5-20250929 -p "$TASK_PATH"
'''
      }
    }
  }
}
