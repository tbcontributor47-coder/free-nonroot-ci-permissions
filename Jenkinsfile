pipeline {
  agent { label 'Linux-01' }

  options {
    timestamps()
  }

  environment {
    // This repo's Harbor task lives at the repository root.
    TASK_PATH = '.'
    OPENAI_BASE_URL = 'https://api.portkey.ai/v1'
    // Set to 'true' in Jenkins job env to push logs back to Git.
    PUSH_LOGS_TO_GIT = 'false'
  }

  stages {
    stage('Preflight') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs

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
(
  set -euo pipefail
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source "$HOME/.local/bin/env"
  uv tool install harbor==0.1.25 --python 3.13
  export PATH="$HOME/.local/bin:$PATH"
  harbor --help >/dev/null
) 2>&1 | tee logs/preflight.log
'''
      }
    }

    stage('Oracle') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs
mkdir -p harborws

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  # Adds uv/uvx and other tool shims to PATH
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

# Harbor uses Docker Compose under the hood and derives the compose project name
# from the current working directory. Jenkins workspaces can include '@2' etc,
# which Docker Compose rejects. Run Harbor from a safe subdir.
TASK_ABS="$(cd "$WORKSPACE/$TASK_PATH" && pwd)"
cd harborws

harbor run --agent oracle --path "$TASK_ABS" 2>&1 | tee ../logs/oracle.log
'''
      }
    }

    stage('Checks') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs
mkdir -p harborws

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

TASK_ABS="$(cd "$WORKSPACE/$TASK_PATH" && pwd)"
cd harborws

harbor tasks check "$TASK_ABS" --model openai/@openai-tbench/gpt-5 2>&1 | tee ../logs/checks.log
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

mkdir -p logs
mkdir -p harborws

export PATH="$HOME/.local/bin:$PATH"
if [ -f "$HOME/.local/bin/env" ]; then
  source "$HOME/.local/bin/env"
fi

command -v harbor >/dev/null || { echo "harbor not found in PATH (did Preflight run?)"; exit 127; }

TASK_ABS="$(cd "$WORKSPACE/$TASK_PATH" && pwd)"
cd harborws

echo "Running GPT-5 agent..."
harbor run -a terminus-2 -m openai/@openai-tbench/gpt-5 -p "$TASK_ABS" 2>&1 | tee ../logs/agent-gpt5.log

echo "Running Claude Sonnet 4.5 agent..."
harbor run -a terminus-2 -m openai/@anthropic-tbench/claude-sonnet-4-5-20250929 -p "$TASK_ABS" 2>&1 | tee ../logs/agent-claude.log
'''
      }
    }

    stage('Publish Logs to Git (optional)') {
      when {
        expression { return env.PUSH_LOGS_TO_GIT?.trim()?.toLowerCase() == 'true' }
      }
      steps {
        // Requires a Jenkins credential with push access. Common choice: a GitHub PAT.
        // If your credential type differs, tell me the credentialId/type and I’ll tailor it.
        withCredentials([usernamePassword(credentialsId: 'github-user', usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_TOKEN')]) {
          sh '''#!/usr/bin/env bash
set -euo pipefail

mkdir -p logs

git status --porcelain

git config user.email "jenkins@local"
git config user.name "jenkins"

# Push logs to a dedicated branch to avoid triggering your main pipeline.
LOG_BRANCH="jenkins-logs"

git fetch origin "+refs/heads/${LOG_BRANCH}:refs/remotes/origin/${LOG_BRANCH}" || true
git checkout -B "${LOG_BRANCH}" || true

git add -A logs

if git diff --cached --quiet; then
  echo "No log changes to publish."
  exit 0
fi

git commit -m "chore(logs): ${JOB_NAME} #${BUILD_NUMBER} [skip ci]"

# Use token auth for push
REPO_URL="$(git config --get remote.origin.url)"

# Normalize to https host/path
if [[ "$REPO_URL" =~ ^git@github.com:(.+)$ ]]; then
  REPO_URL="github.com/${BASH_REMATCH[1]}"
elif [[ "$REPO_URL" =~ ^https?://(.+)$ ]]; then
  REPO_URL="${BASH_REMATCH[1]}"
fi

git push "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@${REPO_URL}" "${LOG_BRANCH}:${LOG_BRANCH}"
'''
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'logs/**', allowEmptyArchive: true
    }
  }
}
