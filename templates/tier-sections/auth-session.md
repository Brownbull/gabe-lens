# Section: Auth/Session

**Trigger tags:** `auth`, `session`

**Purpose:** Authentication lifecycle, session management, CSRF defense. Applies to any phase touching user login, logout, token refresh, or session validation.

## Dimensions (5)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Token refresh        | manual relogin       | L      | auto refresh         | M      | + rotation + revoke |
| Session invalidate   | server expiry        | L      | logout broadcast     | M      | + device mgmt       |
| CSRF                 | none                 | XL     | token per-form       | S      | + SameSite + origin |
| Refresh token        | long-lived           | XL     | rotating             | M      | + per-device bind   |
| Multi-tab sync       | per-tab              | M      | storage event        | S      | + BC + shared wrk   |

## Notes

- **Token refresh:** MVP = user logs in again when token expires. Enterprise = silent auto-refresh using refresh token. Scale = + refresh-token rotation on each use + revocation list.
- **Session invalidate:** MVP = rely on server-side expiry (client unaware). Enterprise = explicit logout broadcast (invalidate token, clear client state). Scale = per-device session list + remote invalidation.
- **CSRF:** XL skip MVP→Ent. State-changing endpoints without CSRF defense are exploitable. Enterprise = CSRF token per form/mutation. Scale = + `SameSite=Lax/Strict` cookies + origin validation.
- **Refresh token:** XL skip MVP→Ent. Long-lived non-rotating refresh tokens = credential replay window measured in months. Enterprise = rotation on every use. Scale = per-device binding (refresh token + device fingerprint).
- **Multi-tab sync:** MVP = each tab holds its own session state (logout in one tab, other tabs still "logged in"). Enterprise = `storage` event signals logout across tabs. Scale = BroadcastChannel + shared worker for coordinated state.

## Tier-cap enforcement

- **MVP phase:** CSRF middleware, refresh-token-rotation code, multi-tab logout sync trigger escalation.
- **Enterprise phase:** device management UX, per-device refresh binding trigger Scale escalation.

## Known drift signals

| Pattern                                       | Tier floor | Finding severity  |
|-----------------------------------------------|------------|-------------------|
| CSRF middleware (`fastapi-csrf`, `django-csrf`)| Enterprise| TIER_DRIFT-HIGH   |
| Refresh token rotation endpoint               | Enterprise | TIER_DRIFT-MED    |
| Per-device session table + device fingerprint | Scale      | TIER_DRIFT-HIGH   |
| `SameSite=Strict` cookie + origin header check| Scale      | TIER_DRIFT-MED    |
| Multi-tab logout listener (`storage` + `BroadcastChannel`) | Enterprise | TIER_DRIFT-LOW |
| Revocation list / token deny-list             | Scale      | TIER_DRIFT-MED    |

## Red-line items

- **CSRF on state-changing endpoints.** Any phase that adds a mutating endpoint (`POST/PUT/DELETE/PATCH`) MUST declare CSRF posture. `none` acceptable only for API-only services with bearer-token auth (no cookies). `/gabe-plan` should BLOCK MVP phase with cookie-based session + mutation endpoint + CSRF = `none`.
- **Refresh token rotation.** Long-lived refresh tokens are a compliance red flag (SOC2, ISO 27001). Even MVP should use short TTL + rotation if real users exist. Prototype-tagged phase only.
