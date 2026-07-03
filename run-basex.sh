#!/bin/sh
set -eu

: "${JETTY_SSL_KEYSTORE_PATH:=$JETTY_BASE/etc/ssl/jetty-selfsigned.p12}"
: "${JETTY_SSL_KEYSTORE_PASSWORD:=changeit}"
: "${JETTY_SSL_KEYMANAGER_PASSWORD:=$JETTY_SSL_KEYSTORE_PASSWORD}"
: "${JETTY_SSL_TRUSTSTORE_PASSWORD:=$JETTY_SSL_KEYSTORE_PASSWORD}"
: "${JETTY_SSL_CERT_ALIAS:=jetty}"
: "${JETTY_SSL_CERT_DNAME:=CN=localhost,OU=Samphire,O=Local,L=Local,ST=Local,C=US}"
: "${JETTY_SSL_CERT_SAN:=dns:localhost,ip:127.0.0.1}"
: "${JETTY_SSL_CERT_VALIDITY_DAYS:=825}"

KEYTOOL_BIN="$(command -v keytool)"
JAVA_BIN="$(command -v java)"
KEYSTORE_DIR="$(dirname "$JETTY_SSL_KEYSTORE_PATH")"
JETTY_RUN_USER="jetty"

if [ ! -w "$KEYSTORE_DIR" ] && command -v sudo >/dev/null 2>&1; then
	sudo mkdir -p "$KEYSTORE_DIR"
	sudo rm -f "$JETTY_SSL_KEYSTORE_PATH"
	sudo "$KEYTOOL_BIN" -genkeypair -noprompt \
		-alias "$JETTY_SSL_CERT_ALIAS" \
		-keyalg RSA \
		-keysize 2048 \
		-storetype PKCS12 \
		-keystore "$JETTY_SSL_KEYSTORE_PATH" \
		-storepass "$JETTY_SSL_KEYSTORE_PASSWORD" \
		-keypass "$JETTY_SSL_KEYMANAGER_PASSWORD" \
		-dname "$JETTY_SSL_CERT_DNAME" \
		-ext "SAN=$JETTY_SSL_CERT_SAN" \
		-validity "$JETTY_SSL_CERT_VALIDITY_DAYS"
	# Ensure Jetty can read the keystore when the service runs as the jetty user.
	sudo chown "$JETTY_RUN_USER:$JETTY_RUN_USER" "$JETTY_SSL_KEYSTORE_PATH"
else
	mkdir -p "$KEYSTORE_DIR"
	rm -f "$JETTY_SSL_KEYSTORE_PATH"
	"$KEYTOOL_BIN" -genkeypair -noprompt \
		-alias "$JETTY_SSL_CERT_ALIAS" \
		-keyalg RSA \
		-keysize 2048 \
		-storetype PKCS12 \
		-keystore "$JETTY_SSL_KEYSTORE_PATH" \
		-storepass "$JETTY_SSL_KEYSTORE_PASSWORD" \
		-keypass "$JETTY_SSL_KEYMANAGER_PASSWORD" \
		-dname "$JETTY_SSL_CERT_DNAME" \
		-ext "SAN=$JETTY_SSL_CERT_SAN" \
		-validity "$JETTY_SSL_CERT_VALIDITY_DAYS"
	if [ "$(id -un)" != "$JETTY_RUN_USER" ]; then
		if command -v sudo >/dev/null 2>&1; then
			sudo chown "$JETTY_RUN_USER:$JETTY_RUN_USER" "$JETTY_SSL_KEYSTORE_PATH"
		else
			echo "Error: keystore owner is $(id -un), but runtime user must be $JETTY_RUN_USER and sudo is unavailable to fix ownership." >&2
			exit 1
		fi
	fi
fi

cd "$JETTY_BASE"

if [ "$(id -un)" = "$JETTY_RUN_USER" ]; then
	exec "$JAVA_BIN" \
		"-Djetty.sslContext.keyStorePath=$JETTY_SSL_KEYSTORE_PATH" \
		"-Djetty.sslContext.keyStorePassword=$JETTY_SSL_KEYSTORE_PASSWORD" \
		"-Djetty.sslContext.keyManagerPassword=$JETTY_SSL_KEYMANAGER_PASSWORD" \
		"-Djetty.sslContext.trustStorePath=$JETTY_SSL_KEYSTORE_PATH" \
		"-Djetty.sslContext.trustStorePassword=$JETTY_SSL_TRUSTSTORE_PASSWORD" \
		-jar "$JETTY_HOME/start.jar"
fi

if command -v sudo >/dev/null 2>&1; then
	exec sudo -u "$JETTY_RUN_USER" "$JAVA_BIN" \
		"-Djetty.sslContext.keyStorePath=$JETTY_SSL_KEYSTORE_PATH" \
		"-Djetty.sslContext.keyStorePassword=$JETTY_SSL_KEYSTORE_PASSWORD" \
		"-Djetty.sslContext.keyManagerPassword=$JETTY_SSL_KEYMANAGER_PASSWORD" \
		"-Djetty.sslContext.trustStorePath=$JETTY_SSL_KEYSTORE_PATH" \
		"-Djetty.sslContext.trustStorePassword=$JETTY_SSL_TRUSTSTORE_PASSWORD" \
		-jar "$JETTY_HOME/start.jar"
fi

echo "Error: must run Jetty as $JETTY_RUN_USER, but current user is $(id -un) and sudo is unavailable." >&2
exit 1
