"""ASGI wrapper around the Cognee API for public Railway deployments.

Cognee's API has an open self-registration route (POST /api/v1/auth/register)
with no switch to turn it off. On a public URL that lets anyone create an
account and spend the deployer's LLM key, so this wrapper answers 403 there
unless ALLOW_SIGNUP=true. Everything else, lifespan included, passes through.
"""

import json
import os

from cognee.api.client import app as cognee_app

ALLOW_SIGNUP = os.getenv("ALLOW_SIGNUP", "false").strip().lower() in ("1", "true", "yes", "on")
BLOCKED_PREFIX = "/api/v1/auth/register"


class SignupGuard:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        if (
            not ALLOW_SIGNUP
            and scope.get("type") == "http"
            and scope.get("path", "").rstrip("/").lower().startswith(BLOCKED_PREFIX)
        ):
            body = json.dumps(
                {
                    "detail": "Self-registration is disabled on this Cognee instance. "
                    "Set ALLOW_SIGNUP=true on the Cognee service to open it."
                }
            ).encode()
            await send(
                {
                    "type": "http.response.start",
                    "status": 403,
                    "headers": [
                        (b"content-type", b"application/json"),
                        (b"content-length", str(len(body)).encode()),
                    ],
                }
            )
            await send({"type": "http.response.body", "body": body})
            return
        await self.inner(scope, receive, send)


app = SignupGuard(cognee_app)
