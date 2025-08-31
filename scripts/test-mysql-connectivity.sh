#!/bin/bash

# MySQL Connectivity Test Script for ZenML Infrastructure
# This script tests database connectivity from your Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Testing MySQL connectivity from Kubernetes cluster...${NC}"

# Get cluster credentials
echo -e "${YELLOW}📋 Getting GKE cluster credentials...${NC}"
PROJECT_ID=$(terraform output -raw project_id 2>/dev/null || echo "your-project-id")
REGION=$(terraform output -raw region 2>/dev/null || echo "your-region") 
CLUSTER_NAME=$(terraform output -raw gke_cluster_name 2>/dev/null || echo "your-cluster-name")

if [[ "$PROJECT_ID" != "your-project-id" ]]; then
    gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
else
    echo -e "${YELLOW}⚠️  Please update PROJECT_ID, REGION, and CLUSTER_NAME in this script${NC}"
    exit 1
fi

# Get MySQL connection info from terraform outputs
echo -e "${YELLOW}🗄️  Retrieving MySQL connection information...${NC}"
MYSQL_HOST=$(terraform output -json mysql | jq -r '.mysql_instance_private_ip')
MYSQL_DB=$(terraform output -json mysql | jq -r '.zenml_database_name')
MYSQL_USER=$(terraform output -json mysql | jq -r '.zenml_database_username')

echo -e "${GREEN}✅ MySQL Host: ${MYSQL_HOST}${NC}"
echo -e "${GREEN}✅ Database: ${MYSQL_DB}${NC}"
echo -e "${GREEN}✅ Username: ${MYSQL_USER}${NC}"

# Test 1: Basic network connectivity
echo -e "${YELLOW}🌐 Test 1: Network connectivity (ping)${NC}"
kubectl run connectivity-test --image=busybox --rm -it --restart=Never -- sh -c "
  echo 'Testing network connectivity to MySQL...'
  if ping -c 3 $MYSQL_HOST; then
    echo 'Network connectivity: OK'
  else
    echo 'Network connectivity: FAILED'
    exit 1
  fi
" || echo -e "${RED}❌ Network connectivity test failed${NC}"

# Test 2: Port connectivity
echo -e "${YELLOW}🔌 Test 2: Port connectivity (telnet)${NC}"
kubectl run port-test --image=busybox --rm -it --restart=Never -- sh -c "
  echo 'Testing MySQL port 3306...'
  if timeout 10 telnet $MYSQL_HOST 3306; then
    echo 'Port connectivity: OK'
  else
    echo 'Port connectivity: FAILED'
    exit 1
  fi
" || echo -e "${RED}❌ Port connectivity test failed${NC}"

# Test 3: MySQL client connection (requires password from Secret Manager)
echo -e "${YELLOW}🔐 Test 3: MySQL authentication${NC}"
echo "To test MySQL authentication, retrieve the password from Secret Manager:"
echo ""
echo "# Get the password:"
echo "gcloud secrets versions access latest --secret=\"${PROJECT_ID}-zenml-db-password\" --project=\"${PROJECT_ID}\""
echo ""
echo "# Then run this command to test the connection:"
echo "kubectl run mysql-client --image=mysql:8.0 --rm -it --restart=Never -- mysql -h $MYSQL_HOST -u $MYSQL_USER -p $MYSQL_DB"

# Test 4: ZenML connection test
echo -e "${YELLOW}🧪 Test 4: ZenML connection simulation${NC}"
cat << EOF
To test the full ZenML connection, create a test pod with this configuration:

apiVersion: v1
kind: Pod
metadata:
  name: zenml-db-test
spec:
  containers:
  - name: zenml-test
    image: python:3.9-slim
    command: ["/bin/bash"]
    args: ["-c", "pip install pymysql && python -c \"
import pymysql
try:
    connection = pymysql.connect(
        host='$MYSQL_HOST',
        user='$MYSQL_USER',
        password='PASSWORD_FROM_SECRET_MANAGER',
        database='$MYSQL_DB',
        ssl_disabled=False
    )
    print('✅ ZenML MySQL connection successful!')
    connection.close()
except Exception as e:
    print(f'❌ Connection failed: {e}')
\""]
  restartPolicy: Never
EOF

echo -e "${GREEN}🎉 Connectivity tests completed!${NC}"
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Ensure your GKE nodes can reach the MySQL private IP"
echo "2. Verify firewall rules allow port 3306 traffic"
echo "3. Test ZenML deployment with the database connection"
