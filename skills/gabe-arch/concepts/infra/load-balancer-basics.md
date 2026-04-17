---
id: load-balancer-basics
name: Load Balancer Basics
tier: foundational
specialization: [infra]
tags: [load-balancer, layer-4, layer-7, round-robin, sticky-session]
prerequisites: []
related: [stateful-vs-stateless-services, health-checks-liveness-readiness]
one_liner: "One address, many instances behind it — the front door that distributes traffic."
---

## Analogy

A maître d' at a busy restaurant: guests arrive at one door, the maître d' decides which table has open capacity and seats them there. Customers never see the tables; the maître d' never cooks. Separating the concerns is what lets the restaurant scale to many tables without chaos at the door.

## When it applies

- Any service running on more than one instance for scale or availability
- Multi-region deployments
- Blue/green or canary deployment strategies (LBs route traffic splits)
- Services behind a public address with private backends

## When it doesn't

- Single-instance deployments (LB adds overhead without benefit)
- Peer-to-peer systems (no central distribution point)
- Internal service-to-service communication already handled by service mesh

## Primary force

You want to scale by adding instances. Clients want one address. A load balancer resolves that tension — it holds the stable address and distributes incoming traffic across healthy backends. Two main layers: **L4 (TCP/UDP)** — fast, protocol-agnostic, dumb routing; **L7 (HTTP)** — smarter, can inspect paths/headers/cookies and route accordingly. Most web systems want L7; high-throughput non-HTTP traffic wants L4.

## Common mistakes

- Load balancer with no health checks (traffic routed to dead instances)
- Sticky sessions as a default instead of a migration step (ties you to stateful architecture)
- Rate limiting at the app instead of the LB (each instance applies its own limit; caller gets N× the intended rate)
- Single LB as a single point of failure (need a pair, DNS-level failover, or managed LB)
- SSL termination only at the LB with plaintext between LB and backends (fine for internal nets; not for zero-trust architectures)

## Evidence a topic touches this

- Keywords: load balancer, nginx, HAProxy, ALB, NLB, round-robin, least-connections
- Files: `**/nginx.conf`, `**/haproxy*`, `**/terraform/*`, `docker-compose.yml`
- Commit verbs: "add LB", "configure nginx", "route to backends", "weighted distribution"

## Deeper reading

- NGINX docs: upstream module
- AWS ALB vs NLB documentation
- "Site Reliability Engineering" (Google) ch. 19-20
