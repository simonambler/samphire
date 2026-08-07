@echo off
setlocal

REM Prefer Podman; fall back to Docker.
where /Q podman
if %ERRORLEVEL% EQU 0 (
  set "CONTAINER_CLI=podman"
) else (
  where /Q docker
  if %ERRORLEVEL% EQU 0 (
    set "CONTAINER_CLI=docker"
  ) else (
    echo Error: neither podman nor docker was found on PATH. 1>&2
    exit /b 1
  )
)

echo Using %CONTAINER_CLI%

REM Run with custom HTTPS settings (non-interactive self-signed cert generation)
%CONTAINER_CLI% run --detach ^
  --name samphire ^
  -p 8443:8443 ^
  -e JETTY_SSL_KEYSTORE_PASSWORD=replace-with-strong-password ^
  -e JETTY_SSL_KEYMANAGER_PASSWORD=replace-with-strong-password ^
  -e JETTY_SSL_TRUSTSTORE_PASSWORD=replace-with-strong-password ^
  -e "JETTY_SSL_CERT_DNAME=CN=localhost,OU=Samphire,O=Local,L=Local,ST=Local,C=US" ^
  -e "JETTY_SSL_CERT_SAN=dns:localhost,ip:127.0.0.1,dns:samphire.local,ip:192.168.1.50" ^
  -e JETTY_SSL_CERT_VALIDITY_DAYS=365 ^
  --volume basex-data:/var/lib/jetty/basex/data ^
  docker.io/sjambler/samphire:latest
