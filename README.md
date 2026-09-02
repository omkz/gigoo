# Gigoo

Gigoo is a trusted, agent-native freelancer marketplace where clients and freelancers use grounded marketplace history — contracts, ratings, reviews, and work history — to make better decisions.

AI/browser agents may search, evaluate, and prepare marketplace actions, but they must not invent trust evidence or bypass marketplace permissions.

A single Gigoo account is not limited to one side of the marketplace: the same user can hire as a client, work as a freelancer, or do both.

## The trust problem

Freelance marketplaces depend on trust in both directions. Clients need evidence that freelancers are reliable and capable; freelancers need evidence that clients communicate clearly, pay responsibly, and behave fairly.

Gigoo's reputation model is grounded in real marketplace activity:

- Completed contracts
- Star ratings
- Written reviews
- Work/hiring history
- Payment verification (for clients)

AI may summarize or analyze these signals — it must not fabricate ratings, reviews, transactions, or historical claims. Every number an agent sees comes straight from the database.

## Current functionality

### Client

- Create, edit, publish, and close jobs (`draft` → `open` → `closed`)
- Browse and search freelancer profiles
- Shortlist freelancers for a job
- View proposals received on a job
- Accept a proposal (creates a contract, closes the job, rejects competing pending proposals)
- View and complete the resulting contract
- Leave a review after completion
- View historical proposal and contract information, including for closed jobs

### Freelancer

- Browse and search open jobs
- Create a proposal draft for an open job
- Review and edit a draft before sending it
- Manually submit a proposal (draft → pending)
- Track everything in a dedicated **My Work** workspace: pending/draft proposals, active contracts, completed contracts
- View active and completed contracts
- Leave a review after a contract is completed

### Account, profiles, and workspace

- `User.role` is a system privilege only (`member` / `support` / `admin`) — it has nothing to do with marketplace capability
- Marketplace capability comes from profile presence: a `ClientProfile` and/or `FreelancerProfile` attached to the account
- Account name is editable from Profile; email is shown read-only (no email-change flow yet)
- Freelancer and client profile details (bio, rate, company, location, skills, etc.) are independently editable
- Users with **both** profiles get a lightweight workspace switcher (Freelancer / Client) that changes which marketplace navigation is shown — it is a UI/session concern only and never affects authorization

## WebMCP

Gigoo exposes structured marketplace capabilities through the browser's experimental [`document.modelContext`](https://github.com/webmachinelearning/webmcp) API (see `app/javascript/webmcp.js`), so a browser-based AI agent can act inside the marketplace using the signed-in user's own session — not a scraped or hallucinated view of it.

### The 8 exposed tools

**Read-only:**

1. `search_jobs` — search open jobs by text, skill, and max budget
2. `get_job` — full detail on one open job, including client trust context
3. `search_freelancers` — search freelancer profiles by skill, location, and max hourly rate, with grounded trust evidence
4. `get_freelancer` — one freelancer's profile, completed-work evidence, and recent reviews
5. `get_client` — one client's profile, hiring history, payment verification, and recent reviews

**Mutations:**

6. `add_to_shortlist` — add a freelancer to the authenticated client's shortlist for one of their open jobs
7. `remove_from_shortlist` — remove a freelancer from that shortlist
8. `create_proposal_draft` — create an unsent proposal draft for an open job as the authenticated freelancer

**There is no `submit_proposal` WebMCP tool, and none is planned.** An agent may prepare a draft proposal on a freelancer's behalf, but submitting it is always an explicit human action taken in the Gigoo UI. This is intentional human-in-the-loop design: the highest-stakes step in a hiring relationship — actually applying for paid work — stays under direct human control.

### WebMCP does not bypass Gigoo authorization

Every WebMCP call runs through the exact same protections as the rest of the app:

- The logged-in user's existing Rails session (no separate agent credential)
- Normal Rails authentication
- Pundit authorization policies
- Marketplace ownership/domain rules (a client can only shortlist/manage their own jobs; a freelancer can only draft proposals as themselves)
- Normal CSRF and session security

The browser agent never gets raw database or admin access — it only receives the structured, read-only or narrowly-scoped-mutation capabilities the application intentionally registers.

## Demo

The seed data (`db/seeds.rb`) produces a deterministic dataset built around two demo accounts and one reserved job, so the same walkthrough works every time.

**Client:** `emily@gigoo.test` / `password`
**Freelancer:** `kurnia@gigoo.test` / `password`
**Reserved demo job:** *Build Rails Marketplace Features* — $4,000, owned by Emily, always seeded `open` with no contract, no shortlist entries, and no proposal from Kurnia.

Reset to that starting state at any time with:

```bash
bin/rails db:reset
```

### Client WebMCP workflow

> "Find Rails freelancers under $60/hour with strong reviews and shortlist the best two for my Rails marketplace job."

```
search_freelancers → get_freelancer → add_to_shortlist
```

`remove_from_shortlist` is also available if the client changes their mind.

### Freelancer WebMCP workflow

> "Find Rails jobs above $3,000 from trustworthy clients and create a proposal draft for Build Rails Marketplace Features with a proposed amount of $3,200."

```
search_jobs → get_job → get_client → create_proposal_draft
```

From there, the human takes over: Kurnia reviews and edits the draft in the UI, then manually submits the proposal. Emily then sees it as a pending proposal on her job, and the normal marketplace contract workflow continues from there — accept, contract created, complete, review.

## Account model

```ruby
user.client_profile.present?
user.freelancer_profile.present?
```

`User.role` (`member` / `support` / `admin`) is a system privilege only and never implies marketplace ownership. A user may have only a `ClientProfile`, only a `FreelancerProfile`, or both.

## Technology

- Ruby 4.0.3, Rails ~> 8.1
- PostgreSQL
- Hotwire (Turbo) and Stimulus
- Tailwind CSS
- Importmap
- Rails built-in authentication
- Pundit
- RSpec
- FactoryBot

## Local setup

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Run the test suite:

```bash
bin/rspec
```

For a deterministic local/demo starting state (not a production operation):

```bash
bin/rails db:reset
```

## License

BSD 3-Clause License — see [LICENSE](LICENSE).
