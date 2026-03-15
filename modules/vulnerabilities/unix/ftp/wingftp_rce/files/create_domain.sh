#!/bin/bash
# Script to create FTP domain in Wing FTP Server via admin web service API
# Usage: create_domain.sh <domain_name> <anonymous_home> <admin_user> <admin_pass>

# Don't use set -e as curl returns may vary

DOMAIN_NAME="${1:-ftp_domain}"
ANONYMOUS_HOME="${2:-/home/ftp}"
ADMIN_USER="${3:-admin}"
ADMIN_PASS="${4:-password123WingFTP}"

WINGFTP_URL="http://127.0.0.1:5466"

echo "Waiting for Wing FTP Server to start..."
for i in {1..30}; do
  if curl -s "${WINGFTP_URL}/admin_login.html" > /dev/null 2>&1; then
    echo "Wing FTP Server is ready"
    break
  fi
  sleep 1
done

echo "Creating Wing FTP domain: $DOMAIN_NAME"
echo "Anonymous home: $ANONYMOUS_HOME"

# Create the domain using admin_webservice.html
# Parameters: domain_name, bind_address, ftp_port, ftps_port, http_port, https_port, ssh_port
echo "Creating domain..."
RESULT1=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_AddDomain('${DOMAIN_NAME}','*',21,990,80,443,22)" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "Domain creation result: $RESULT1"

# Create anonymous user
# c_AddUser parameters: domain, username, password, permission_bits, password_enabled, account_enabled, ...
# Permission bits: 63 = full access
# Anonymous user has empty password and password_enabled=0
echo "Creating anonymous user..."
RESULT2=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_AddUser('${DOMAIN_NAME}','anonymous','',63,0,1,0,0,10,0,0,10,0,1,1,1,0,0,0,0,0,0,0,0,'','','','','','','',{},{},{},{},0,{},0,0,0,0,0,0,0,0,'',{},0,0,0,0,'','')" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "User creation result: $RESULT2"

# Set the home directory for anonymous user
echo "Setting home directory for anonymous user: ${ANONYMOUS_HOME}"
RESULT3=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_SetUserHomeDir('${DOMAIN_NAME}','anonymous','${ANONYMOUS_HOME}')" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "Home directory result: $RESULT3"

# Add directory permissions for the anonymous user
echo "Adding directory permissions..."
RESULT4=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_AddUserDirectory('${DOMAIN_NAME}','anonymous','${ANONYMOUS_HOME}','/',true,true,true,true,true,true,true,true,true)" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "Directory permissions result: $RESULT4"

# Enable anonymous access on the domain
echo "Enabling anonymous access..."
RESULT5=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_SetDomainOption('${DOMAIN_NAME}','enable_anonymous',1)" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "Anonymous access result: $RESULT5"

# Start the domain listener
echo "Starting domain..."
RESULT6=$(curl -s -F "admin=${ADMIN_USER}" -F "pass=${ADMIN_PASS}" \
  -F "cmd=c_StartDomain('${DOMAIN_NAME}')" \
  "${WINGFTP_URL}/admin_webservice.html?")
echo "Domain start result: $RESULT6"

echo ""
echo "=========================================="
echo "Domain setup complete for: ${DOMAIN_NAME}"
echo "FTP should be listening on port 21"
echo "=========================================="

# Verify FTP is listening
sleep 2
if netstat -tlnp 2>/dev/null | grep -q ":21 "; then
  echo "SUCCESS: FTP port 21 is listening"
else
  echo "WARNING: FTP port 21 may not be listening yet"
fi