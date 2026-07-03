#########################
## Build stage - basex ##
#########################

FROM docker.io/library/jetty:12.0.32-jre21-eclipse-temurin AS basex

LABEL Name=samphire Version=0.0.1

# BaseX version parameters (override at build time if needed).
ARG BASEX_VERSION=12.2
ARG BASEX_APP_DIR=BaseX122
ENV BASEX_VERSION=${BASEX_VERSION}
ENV BASEX_APP_DIR=${BASEX_APP_DIR}

# Default TLS settings. Override at runtime with environment variables.
ENV JETTY_SSL_KEYSTORE_PATH=/var/lib/jetty/etc/ssl/jetty-selfsigned.p12
ENV JETTY_SSL_KEYSTORE_PASSWORD=changeit
ENV JETTY_SSL_KEYMANAGER_PASSWORD=changeit
ENV JETTY_SSL_TRUSTSTORE_PASSWORD=changeit
ENV JETTY_SSL_CERT_ALIAS=jetty
ENV JETTY_SSL_CERT_DNAME="CN=localhost,OU=Samphire,O=Local,L=Local,ST=Local,C=US"
ENV JETTY_SSL_CERT_SAN="dns:localhost,ip:127.0.0.1"
ENV JETTY_SSL_CERT_VALIDITY_DAYS=825

# Avoid JVM bug on Apple 64-bit architecture.
# https://bugs.openjdk.org/browse/JDK-8345296
#ENV JAVA_TOOL_OPTIONS="-XX:UseSVE=0"

# Switch to root user.
USER root

# Disable interactive prompts.
ARG DEBIAN_FRONTEND=noninteractive

# Install apt packages.
RUN apt-get update && \
    apt-get install -y unzip curl libtagsoup-java

# Switch to jetty user.
USER jetty

#####################################
# JETTY_HOME    =  /usr/local/jetty
# JETTY_BASE    =  /var/lib/jetty
# TMPDIR        =  /tmp/jetty
#####################################

# Create directories.
RUN mkdir -p $TMPDIR/basex && \
    mkdir -p $JETTY_BASE/basex/data && \
    mkdir -p $JETTY_BASE/basex/deploy/${BASEX_APP_DIR} && \
    mkdir -p $JETTY_BASE/basex/sample

# Download WAR distribution of BaseX.
ADD --chown=jetty:jetty \
    https://files.basex.org/releases/${BASEX_VERSION}/${BASEX_APP_DIR}.war \
    $TMPDIR/basex/

# Unpack contents of WAR.
RUN cd $JETTY_BASE/basex/deploy/${BASEX_APP_DIR} && \
    unzip $TMPDIR/basex/${BASEX_APP_DIR}.war

# Enable modules required for deploying BaseX as a web application.
RUN java -jar "$JETTY_HOME/start.jar" --add-modules=server,http,ssl,https,ee9-deploy,ee9-webapp,ee9-websocket-jetty

# Copy startup script that creates a self-signed TLS certificate non-interactively.
COPY --chown=jetty:jetty ./run-basex.sh /usr/local/bin/run-basex.sh
RUN chmod +x /usr/local/bin/run-basex.sh

# Override the embedded web.xml deployment descriptor.
COPY --chown=jetty:jetty \
    ./basex/webapps/BaseX122-override-web.xml \
    $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}-override-web.xml

# Deploy BaseX using a context file.
COPY --chown=jetty:jetty \
    ./basex/webapps/BaseX122.xml \
    $JETTY_BASE/webapps/${BASEX_APP_DIR}.xml

# Add login credentials.
COPY --chown=jetty:jetty \
    ./basex/data/users.xml $JETTY_BASE/basex/data

# Copy sample database.
COPY --chown=jetty:jetty \
    ./basex/sample/demo $JETTY_BASE/basex/sample/demo

# Create directory for samphire restxq modules and Vue.js application.
RUN mkdir -p $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/samphire


##########################
## Build stage - nodejs ##
##########################

FROM basex AS nodejs

# Switch to root user.
USER root

# Disable interactive prompts.
ARG DEBIAN_FRONTEND=noninteractive

# Instructions for installing node at
# https://github.com/nodesource/distributions
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs

# Switch to jetty user.
USER jetty


################################
## Build stage - devcontainer ##
################################

FROM nodejs AS devcontainer

# Switch to root user.
USER root

# Set environment variable to indicate development mode.
ENV SAMPHIRE_DEPLOYMENT=development

# Override TMPDIR from jetty.
ENV TMPDIR=/tmp

# Disable interactive prompts.
ARG DEBIAN_FRONTEND=noninteractive

# Install apt packages.
RUN apt-get update && \
    apt-get install -y git sudo

# Link source directory from workspace.
RUN ln -s /workspaces/samphire/basex/restxq $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/samphire/restxq

# Link static files from workspace.
RUN ln -s /workspaces/samphire/basex/static $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/static/samphire

# Create a default user.
RUN groupadd -g 1010 vscode && \
    useradd --system --create-home --shell /bin/bash/ --uid 1010 --gid 1010 vscode

# Give default user permission to sudo.
RUN echo 'vscode ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers.d/vscode

# Switch to default user.
USER vscode


################################
## Build stage - distribution ##
################################

FROM nodejs AS distribution

# Switch to root user.
USER root

# Copy source code (exclude node_modules, .vscode and dist directories).
COPY vue /root/vue

# Set working directory.
WORKDIR /root/vue
    
# Install dependencies and build the Vue.js application.
RUN npm install && \
    npm run build


##########################
## Build stage - webapp ##
##########################

FROM basex AS webapp

# Switch to root user.
USER root

# Set environment variable to indicate production mode.
ENV SAMPHIRE_DEPLOYMENT=production

# Copy restxq modules.
COPY --chown=jetty:jetty \
    ./basex/restxq $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/samphire/restxq

# Copy static files.
COPY --chown=jetty:jetty \
    ./basex/static $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/static/samphire/

# Copy license file.
COPY --chown=jetty:jetty \
    ./LICENSE.txt $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/static/samphire/

# Copy the built Vue.js application from the distribution stage.
COPY --from=distribution --chown=jetty:jetty \
    /root/vue/dist $JETTY_BASE/basex/deploy/${BASEX_APP_DIR}/static/samphire/dist

# Switch to jetty user.
USER jetty

# Set working directory.
WORKDIR $JETTY_BASE

# Expose ports for HTTP and HTTPS.
EXPOSE 8080 8443

# Start Jetty server.
CMD ["/usr/local/bin/run-basex.sh"]
