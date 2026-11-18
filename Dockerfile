# Cognee API server for Railway.
# Upstream image pinned by version and digest. Bump both together, add a CHANGELOG entry.
FROM cognee/cognee:1.6.8@sha256:808773bb4b35883f2ff3d4d72f32c58e5230e97df7ea09d9a6f73bdef9bddc8e

USER root

COPY wrapper/railway_guard.py /app/railway_guard.py
COPY wrapper/start.sh /usr/local/bin/railway-start.sh

# Serve the guarded app (self-registration closed unless ALLOW_SIGNUP=true).
# Fail the build if upstream changes the entrypoint line this relies on.
RUN grep -q 'cognee.api.client:app' /app/entrypoint.sh \
    && sed -i 's/cognee\.api\.client:app/railway_guard:app/g' /app/entrypoint.sh \
    && chmod 0755 /usr/local/bin/railway-start.sh \
    && chown cognee:cognee /app/railway_guard.py \
    && command -v setpriv

# Starts as root only to fix the ownership of the Railway volume, then drops to
# the image's own non-root user (uid 1000) and runs the upstream entrypoint.
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
