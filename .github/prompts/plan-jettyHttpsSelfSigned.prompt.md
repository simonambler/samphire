## Plan: Jetty 12 HTTPS Self-Signed Setup

Configure Jetty 12 HTTPS in a fully non-interactive Docker build by generating a self-signed certificate with keytool, enabling Jetty https/ssl modules, and wiring passwords via runtime environment variables. Keep HTTP (8080) active in parallel with HTTPS (8443), and parameterize SAN values so localhost plus custom DNS/IP entries are supported without rebuilding image logic.

**Steps**
1. Phase 1 - Parameterize certificate and password inputs
1. Add Docker ARG/ENV inputs in /workspaces/samphire/Dockerfile for certificate subject and SAN list defaults, plus placeholder env var names for keystore/truststore/key manager passwords.
2. Define a single source of truth for password variable names (for example JETTY_SSL_KEYSTORE_PASSWORD) and ensure non-interactive defaults are only development-safe.
3. Decide where runtime values are injected (docker run -e, compose env_file, or orchestrator secret-to-env mapping).

2. Phase 2 - Generate non-interactive self-signed keystore during build
1. Add a Dockerfile RUN step using keytool -genkeypair with -noprompt, explicit -dname, and -ext SAN values.
2. Write keystore to a stable Jetty base path and set ownership so jetty user can read it.
3. Ensure the keytool command is deterministic and does not pause for prompts in any environment.

3. Phase 3 - Enable Jetty 12 HTTPS modules and configure SSL properties
1. In Dockerfile, enable Jetty 12 modules using --add-modules (https plus its ssl dependencies).
2. Add/start.d SSL property configuration for keystore path and password property bindings.
3. Bind passwords from runtime env vars into Jetty property resolution so credentials are not baked into image layers.
4. Keep existing HTTP module enabled to satisfy dual-port requirement.

4. Phase 4 - Expose networking and document runtime contract
1. Update container exposure to include 8443 while retaining 8080.
2. Document required and optional environment variables, SAN input format, and example run/compose usage in project docs.
3. Document browser trust behavior for self-signed certs and expected warning flow.

5. Phase 5 - Validate build and runtime behavior
1. Build image with defaults and verify no interactive prompts appear.
2. Run container with explicit password env vars and custom SAN list.
3. Verify HTTP on 8080 and HTTPS on 8443 both respond.
4. Inspect presented certificate SAN entries and validity window.
5. Verify BaseX app context still deploys and serves as before over both schemes.

**Relevant files**
- /workspaces/samphire/Dockerfile - add keytool generation, Jetty module enablement, SSL property wiring, and port exposure updates.
- /workspaces/samphire/basex/webapps/BaseX122.xml - reuse unchanged unless context-level transport constraints are later required.
- /workspaces/samphire/basex/webapps/BaseX122-override-web.xml - reuse unchanged unless strict transport guarantee rules are intentionally added.
- /workspaces/samphire/README.md (or existing ops doc) - document env vars, SAN format, and run examples.

**Verification**
1. docker build --target webapp . completes with no prompts and no missing-module errors.
2. docker run with env vars for SSL passwords starts Jetty cleanly and loads http + https connectors.
3. curl http://localhost:8080/... returns expected response.
4. curl -k https://localhost:8443/... returns expected response.
5. openssl s_client -connect localhost:8443 -servername localhost plus certificate inspection confirms SAN and self-signed issuer.
6. Jetty startup logs confirm https module active and keystore loaded from configured path.

**Decisions**
- Included scope: self-signed cert generation inside image build, runtime password injection, dual HTTP/HTTPS listeners, SAN parameterization for localhost plus custom DNS/IP values.
- Excluded scope: CA-issued certificates, automated trust distribution to clients, HTTP-to-HTTPS redirect enforcement, and mTLS.
- Security posture: runtime env vars are baseline acceptable; if stronger controls are needed later, migrate password source to mounted secrets without changing core module wiring.

**Further Considerations**
1. Password source hardening path: Option A keep runtime env vars now, Option B move to secret-file mapping next, Option C full secret manager injection in orchestration.
2. Transport policy path: Option A keep dual-port behavior as requested, Option B add optional redirect module flag later, Option C strict HTTPS-only profile for production.
3. Certificate lifecycle: Option A long-lived self-signed for internal dev, Option B periodic rotate on rebuild, Option C split dev self-signed and prod CA cert profiles.
