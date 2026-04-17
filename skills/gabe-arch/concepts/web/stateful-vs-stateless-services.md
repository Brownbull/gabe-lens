---
id: stateful-vs-stateless-services
name: Stateful vs Stateless Services
tier: foundational
specialization: [web]
tags: [state, scaling, session, horizontal-scale]
prerequisites: []
related: [request-response-lifecycle]
one_liner: "Stateless servers scale horizontally; stateful servers scale operationally."
---

## Analogy

Stateless = a drive-through window: every car gets a fresh order, no one remembers you. Easy to add more windows. Stateful = your regular barber who knows exactly how you like it. Impossible to clone — you need that specific person.

## When it applies

- Any HTTP service you want to scale by adding instances behind a load balancer
- Serverless deployment models (Lambda, Cloud Run) which force statelessness
- Horizontal scaling scenarios where identical instances must handle any request
- Multi-region deployments where session affinity is a liability

## When it doesn't

- WebSocket / long-lived connection servers (inherently stateful per connection)
- Stream-processing or session-local computation where state colocation beats the network cost
- When you've measured that "stateful and scaled vertically" is cheaper than "stateless + external cache"

## Primary force

State is the enemy of horizontal scale. If instance A knows something instance B doesn't, the load balancer can't freely route requests — you need sticky sessions, state sync, or complex coordination. Moving state out of instances (to DB, Redis, signed client tokens) makes every instance interchangeable, which turns capacity from an operational puzzle into a dial. Stateful services aren't wrong; they're just a tradeoff that should be made consciously.

## Common mistakes

- Holding user session in instance memory because it's "fast" (it is; until you scale and it disappears)
- Pushing all state to the DB without caching (correct but slow)
- Using sticky sessions as a long-term crutch instead of a migration step
- Mistaking in-memory caches for state (they're fine if they're non-authoritative and repopulate from source)

## Evidence a topic touches this

- Keywords: stateless, session, in-memory, horizontal scale, load balancer, sticky session
- Files: `**/session*`, `**/auth*`, `**/server.py`, `**/main.py`
- Commit verbs: "make stateless", "move to Redis", "remove sticky", "externalize state"

## Deeper reading

- "Designing Data-Intensive Applications" (Kleppmann) ch. 1
- The Twelve-Factor App (Factor VI: Processes)
