#!/bin/bash
# Deploy Datadog Agent to Kubernetes
# RDB-007: Datadog APM Instrumentation - Phase 1
#
# Prerequisites:
# - kubectl configured for target cluster
# - Helm 3.x installed
# - Datadog API and APP keys

set -e

# Configuration
NAMESPACE="monitoring"
RELEASE_NAME="datadog-agent"
VALUES_FILE="datadog-agent-values.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Datadog Agent Deployment ===${NC}"
echo "RDB-007: Phase 1 - Infrastructure Setup"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm not found${NC}"
    exit 1
fi

# Check for API keys
if [ -z "$DD_API_KEY" ] || [ -z "$DD_APP_KEY" ]; then
    echo -e "${RED}Error: DD_API_KEY and DD_APP_KEY must be set${NC}"
    echo "Export them before running:"
    echo "  export DD_API_KEY=<your-api-key>"
    echo "  export DD_APP_KEY=<your-app-key>"
    exit 1
fi

echo -e "${GREEN}Prerequisites OK${NC}"
echo ""

# Create namespace if not exists
echo -e "${YELLOW}Creating namespace ${NAMESPACE}...${NC}"
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Create secrets
echo -e "${YELLOW}Creating Datadog secrets...${NC}"
kubectl create secret generic datadog-keys \
    --from-literal=api-key=${DD_API_KEY} \
    --from-literal=app-key=${DD_APP_KEY} \
    -n ${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Secrets created${NC}"
echo ""

# Add Datadog Helm repo
echo -e "${YELLOW}Adding Datadog Helm repository...${NC}"
helm repo add datadog https://helm.datadoghq.com
helm repo update

# Install/Upgrade Datadog Agent
echo -e "${YELLOW}Deploying Datadog Agent...${NC}"
helm upgrade --install ${RELEASE_NAME} datadog/datadog \
    -f ${VALUES_FILE} \
    -n ${NAMESPACE} \
    --wait \
    --timeout 5m

echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""

# Verify deployment
echo -e "${YELLOW}Verifying deployment...${NC}"
kubectl get pods -n ${NAMESPACE} -l app=datadog

echo ""
echo -e "${YELLOW}Checking Agent status...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=datadog \
    -n ${NAMESPACE} \
    --timeout=120s

echo ""
echo -e "${GREEN}=== Datadog Agent Ready ===${NC}"
echo ""
echo "Next steps:"
echo "1. Verify agent in Datadog UI: https://app.datadoghq.com/infrastructure"
echo "2. Check OTLP endpoints:"
echo "   - gRPC: <node-ip>:4317"
echo "   - HTTP: <node-ip>:4318"
echo "3. Verify APM: https://app.datadoghq.com/apm/home"
echo ""
echo "To check agent logs:"
echo "  kubectl logs -n ${NAMESPACE} -l app=datadog -c agent --tail=100"
echo ""
echo "To uninstall:"
echo "  helm uninstall ${RELEASE_NAME} -n ${NAMESPACE}"
