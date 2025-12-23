pipeline {
  agent { label 'Linux-01' }

  options {
    timestamps()
  }

  environment {
    TASK_PATH = 'TerminalBench/fix-nonroot-ci-permissions'
    // If you set this in Jenkins UI already, it will override if you remove this line.
    OPENAI_BASE_URL = 'https://api.portkey.ai/v1'
  }

  stages {
    stage('Preflight') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

echo "Node: $(hostname)"
echo "Workspace: $WORKSPACE"

docker version
harbor --help >/dev/null
'''
      }
    }

    stage('Oracle') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

harbor run --agent oracle --path "$TASK_PATH"
'''
      }
    }

    stage('Checks') {
      steps {
        sh '''#!/usr/bin/env bash
set -euo pipefail

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

# Uses OPENAI_API_KEY and OPENAI_BASE_URL from Jenkins environment
echo "Running GPT-5 agent..."
harbor run -a terminus-2 -m openai/@openai-tbench/gpt-5 -p "$TASK_PATH"

echo "Running Claude Sonnet 4.5 agent..."
harbor run -a terminus-2 -m openai/@anthropic-tbench/claude-sonnet-4-5-20250929 -p "$TASK_PATH"
'''
      }
    }
  }
}
