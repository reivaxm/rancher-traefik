#!/usr/bin/env sh

TRAEFIK_HTTP_PORT=${TRAEFIK_HTTP_PORT:-"80"}
TRAEFIK_HTTPS_ENABLE=${TRAEFIK_HTTPS_ENABLE:-"true"}
TRAEFIK_HTTPS_PORT=${TRAEFIK_HTTPS_PORT:-"443"}
TRAEFIK_ADMIN_PORT=${TRAEFIK_ADMIN_PORT:-"8000"}
TRAEFIK_DEBUG=${TRAEFIK_DEBUG:="true"}
TRAEFIK_LOG_LEVEL=${TRAEFIK_LOG_LEVEL:-"INFO"}
TRAEFIK_LOG_FILE=${TRAEFIK_LOG_FILE:-"${SERVICE_HOME}/log/traefik.log"}
TRAEFIK_ACCESS_FILE=${TRAEFIK_ACCESS_FILE:-"${SERVICE_HOME}/log/access.log"}
TRAEFIK_SSL_PATH=${TRAEFIK_SSL_PATH:-"${SERVICE_HOME}/certs"}
TRAEFIK_ACME_ENABLE=${TRAEFIK_ACME_ENABLE:-"false"}
TRAEFIK_ACME_EMAIL=${TRAEFIK_ACME_EMAIL:-"test@traefik.io"}
TRAEFIK_ACME_ONDEMAND=${TRAEFIK_ACME_ONDEMAND:-"true"}
TRAEFIK_ACME_ONHOSTRULE=${TRAEFIK_ACME_ONHOSTRULE:-"true"}
TRAEFIK_K8S_ENABLE=${TRAEFIK_K8S_ENABLE:-"false"}
TRAEFIK_K8S_OPTS=${TRAEFIK_K8S_OPTS:-""}
TRAEFIK_RANCHER_ENDPOINT=${TRAEFIK_RANCHER_ENDPOINT}
TRAEFIK_RANCHER_DOMAIN=${TRAEFIK_RANCHER_DOMAIN}
TRAEFIK_RANCHER_ACCESS_KEY=${TRAEFIK_RANCHER_ACCESSKEY}
TRAEFIK_RANCHER_SECRET_KEY=${TRAEFIK_RANCHER_SECRET}

TRAEFIK_ENTRYPOINTS_HTTP="
  [entryPoints.web]
    address = \":${TRAEFIK_HTTP_PORT}\"
    [entryPoints.web.redirect]
      entryPoint = \"websecure\""

if [ "X${TRAEFIK_ACME_ENABLE}" == "Xfalse" ]; then
TRAEFIK_ENTRYPOINTS_HTTPS="
  [entryPoints.websecure]
    address = \":${TRAEFIK_HTTPS_PORT}\"
    [entryPoints.websecure.tls]
      [[entryPoints.websecure.tls.certificates]]
        certFile = \"$TRAEFIK_SSL_CERT\"
        keyFile = \"$TRAEFIK_SSL_PRIVATE_KEY\""
else
TRAEFIK_ENTRYPOINTS_HTTPS="
  [entryPoints.websecure]
    address = \":${TRAEFIK_HTTPS_PORT}\"
  [entryPoints.websecure.http.tls]
    certResolver = \"traefikresolver\""
fi

if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ]; then
    TRAEFIK_ENTRYPOINTS_OPTS="
${TRAEFIK_ENTRYPOINTS_HTTP}
${TRAEFIK_ENTRYPOINTS_HTTPS}"
    TRAEFIK_ENTRYPOINTS='"web", "websecure"'
elif [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ]; then
    TRAEFIK_ENTRYPOINTS_OPTS="
${TRAEFIK_ENTRYPOINTS_HTTP}
${TRAEFIK_ENTRYPOINTS_HTTPS}"
    TRAEFIK_ENTRYPOINTS='"web", "websecure"'
else
    TRAEFIK_ENTRYPOINTS_OPTS=${TRAEFIK_ENTRYPOINTS_HTTP}
    TRAEFIK_ENTRYPOINTS='"web"'
fi

if [ "X${TRAEFIK_K8S_ENABLE}" == "Xtrue" ]; then
TRAEFIK_K8S_OPTS="
[kubernetes]"
fi

TRAEFIK_ACME_CFG=""
if [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xtrue" ] || [ "X${TRAEFIK_HTTPS_ENABLE}" == "Xonly" ] && [ "X${TRAEFIK_ACME_ENABLE}" == "Xtrue" ]; then
TRAEFIK_ACME_CFG="
[certificatesResolvers.traefikresolver.acme]
  email = \"${TRAEFIK_ACME_EMAIL}\"
  storage = \"${SERVICE_HOME}/acme/acme.json\"
  [certificatesResolvers.traefikresolver.acme.tlsChallenge]"
fi

cat > ${SERVICE_HOME}/etc/traefik.toml << EOF
# traefik.toml
debug = ${TRAEFIK_DEBUG}
logLevel = "${TRAEFIK_LOG_LEVEL}"
traefikLogsFile = "${TRAEFIK_LOG_FILE}"
accessLogsFile = "${TRAEFIK_ACCESS_FILE}"
defaultEntryPoints = [${TRAEFIK_ENTRYPOINTS}]
[entryPoints]
${TRAEFIK_ENTRYPOINTS_OPTS}
[web]
address = ":${TRAEFIK_ADMIN_PORT}"
${TRAEFIK_K8S_OPTS}
[rancher]
domain = "${TRAEFIK_RANCHER_DOMAIN}"
Watch = true
Endpoint = "${TRAEFIK_RANCHER_ENDPOINT}"
AccessKey = "${TRAEFIK_RANCHER_ACCESS_KEY}"
SecretKey = "${TRAEFIK_RANCHER_SECRET_KEY}"


[file]
filename = "${SERVICE_HOME}/etc/rules.toml"
watch = true

${TRAEFIK_ACME_CFG}
EOF
