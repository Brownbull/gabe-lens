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

## The problem

You want to scale a service by running more instances. Clients want one stable address to call. Something has to sit in front and decide which instance each request goes to — and stop routing to instances that are broken.

## The idea

Put a dedicated router at a single public address; it health-checks a pool of backends and distributes incoming traffic across the healthy ones.

## Picture it

A maître d' at a busy restaurant. Guests arrive at one door. The maître d' glances at the room, sees which tables have capacity, and seats each party there. Guests never see the tables; the maître d' never cooks.

## How it maps

```
One restaurant door           →  the public VIP (virtual IP) / DNS name
The maître d'                 →  the load balancer process (nginx, HAProxy, ALB)
Tables with open capacity     →  healthy backend instances
Glancing around the room      →  active health checks against each backend
Seating strategy              →  algorithm: round-robin, least-connections, hash
Reading the reservation       →  L7 (layer 7) routing on path/header/cookie
  card to pick a table
Just pointing to any table    →  L4 (layer 4) routing on TCP — fast, dumb, agnostic
Crossing tables off           →  dropping an unhealthy backend from the pool
```

## Primary force

Scaling means adding instances; clients want one address. A load balancer resolves that tension — it owns the stable address and hides the pool behind it. L4 is fast and protocol-agnostic, good for raw throughput; L7 reads HTTP and can route on path, header, or cookie, which is what most web systems actually want. Without a load balancer, every client has to know every instance, and one dead backend becomes every client's problem.

## When to reach for it

- Any service running on more than one instance for scale or availability.
- Blue/green or canary deployments where traffic needs to shift between pools.
- Public endpoints that must hide a private backend fleet behind one address.

## When NOT to reach for it

- Single-instance deployment — the LB adds a hop and a failure point for no gain.
- No health checks configured — you've just built a faster way to hit dead instances.
- Sticky sessions used as a default instead of a migration step — locks you into stateful architecture.
- Single LB with no pair or DNS failover — the front door itself becomes the outage.

## Evidence a topic touches this

- Keywords: load balancer, nginx, HAProxy, ALB, NLB, round-robin, least-connections
- Files: `**/nginx.conf`, `**/haproxy*`, `**/terraform/*`, `docker-compose.yml`
- Commit verbs: "add LB", "configure nginx", "route to backends", "weighted distribution"

## Deeper reading

- NGINX docs: upstream module
- AWS ALB vs NLB documentation
- "Site Reliability Engineering" (Google) ch. 19-20
