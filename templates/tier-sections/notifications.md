# Section: Notifications

**Trigger tags:** `email`, `push`, `sms`

**Purpose:** Multi-channel notification posture. Applies to phases sending email, push, SMS, or in-app notifications.

## Dimensions (5)

| Dimension            | MVP                  | Δ(M→E) | Enterprise           | Δ(E→S) | Scale               |
|----------------------|----------------------|--------|----------------------|--------|---------------------|
| Delivery             | fire-and-forget      | L      | provider + retry     | M      | + multi-provider FB |
| Preferences          | all or none          | L      | per-channel opt      | M      | + per-event gran.   |
| Unsubscribe          | link only            | L      | one-click + track    | S      | + preference center |
| Templating           | hardcoded            | M      | template engine      | S      | + i18n + A/B test   |
| Tracking             | none                 | M      | delivered event      | M      | + open/click hooks  |

## Notes

- **Delivery:** MVP = call provider API, hope it sent. Enterprise = provider with retry + delivery status check. Scale = + multi-provider fallback (SendGrid primary → SES fallback).
- **Preferences:** MVP = user gets all notifications or none. Enterprise = per-channel opt (can disable email but keep push). Scale = + per-event granularity (opt out of marketing but keep transactional).
- **Unsubscribe:** MVP = unsubscribe link at email footer, no tracking. Enterprise = one-click unsubscribe (RFC 8058 `List-Unsubscribe-Post`) + completion tracking. Scale = + self-service preference center.
- **Templating:** MVP = f-string / string concat in code. Enterprise = template engine (Mustache, Handlebars, MJML for email). Scale = + i18n + A/B test variants.
- **Tracking:** MVP = no visibility. Enterprise = delivered-event webhook from provider. Scale = + open/click tracking with first-party proxy.

## Tier-cap enforcement

- **MVP phase:** multi-provider fallback middleware, preference-center UI scaffolding, i18n template files, open-tracking proxy trigger escalation.
- **Enterprise phase:** A/B test controller, granular per-event preferences, tracking aggregation pipeline trigger Scale escalation.

## Known drift signals

| Pattern                                       | Tier floor | Finding severity |
|-----------------------------------------------|------------|------------------|
| Retry + delivery-status polling on send       | Enterprise | TIER_DRIFT-MED   |
| Multi-provider client abstraction (provider interface + N impls) | Scale | TIER_DRIFT-MED |
| One-click unsubscribe header + POST endpoint  | Enterprise | TIER_DRIFT-LOW   |
| Preference center UI (grid of event × channel toggles) | Scale | TIER_DRIFT-MED |
| MJML / Handlebars template compiler           | Enterprise | TIER_DRIFT-LOW   |
| i18n template variants + locale selection     | Scale      | TIER_DRIFT-MED   |
| Open-tracking pixel proxy / click-tracking redirect | Scale | TIER_DRIFT-MED |

## Red-line items

- **Unsubscribe compliance.** Any phase sending marketing email MUST have one-click unsubscribe (RFC 8058) at Enterprise minimum. MVP "link only" fails CAN-SPAM / CASL / GDPR requirements. Transactional-only phases can stay MVP.
- **Preferences granularity.** Any phase sending > 1 type of notification (marketing + transactional) MUST support per-channel opt at Enterprise minimum. "all or none" violates user expectations.
