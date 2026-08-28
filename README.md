# Gigoo

Gigoo is a trusted, agent-native freelancer marketplace for clients and freelancers. It is designed around mutual reputation: both sides should be able to understand who they are working with, make informed decisions, and eventually use AI agents to navigate marketplace workflows through structured WebMCP tools.

A Gigoo account is not limited to one side of the marketplace. The same user can hire as a client, work as a freelancer, or do both.

## The trust problem

Freelance marketplaces depend on trust in both directions. Clients need evidence that freelancers are reliable and capable; freelancers need evidence that clients communicate clearly, pay responsibly, and behave fairly.

Gigoo's reputation model is intended to be grounded in real marketplace activity: completed contracts, ratings, written reviews, transaction behavior, and work history. AI may help summarize or analyze those signals, but it must not invent ratings, reviews, transactions, or historical claims.

## Current functionality

The implemented product surface currently includes authenticated job management for clients:

- View only your own posted jobs.
- Create jobs as drafts.
- Edit jobs you own.
- Publish a draft job, moving it to `open`.
- Close an open job, moving it to `closed`.
- Enter budgets as normal currency amounts while storing them as integer cents.
- Enter skills as comma-separated text while storing them as a PostgreSQL string array.
- Gate client actions through `ClientProfile` presence and job ownership through Pundit.

The repository also contains tested domain foundations for freelancer profiles, proposals, shortlists, contracts, and bilateral contract reviews. Their user-facing workflows are not implemented yet.

## Account model

`User.role` represents system privileges only:

- `member`
- `support`
- `admin`

Marketplace capabilities come from profile presence:

```ruby
user.client_profile.present?
user.freelancer_profile.present?
```

A user may have only a `ClientProfile`, only a `FreelancerProfile`, or both. Support and admin roles do not automatically grant ownership of marketplace records.

## Technology

- Ruby on Rails 8
- PostgreSQL
- Hotwire and Stimulus
- Tailwind CSS
- Importmap
- Rails built-in authentication
- Pundit
- RSpec
- FactoryBot

## Local setup

Requirements include Ruby 4.0.3 and PostgreSQL.

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Run the test suite with:

```bash
bin/rspec
```

## Agent-native direction

Gigoo is being designed so AI agents can eventually interact with marketplace workflows through structured WebMCP tools. Planned capabilities include:

- Search jobs and freelancers.
- Inspect client and freelancer reputation.
- Compare candidates using grounded marketplace evidence.
- Create shortlists.
- Prepare or submit proposals with user authorization.

These WebMCP capabilities are planned or in development; the repository does not currently expose WebMCP tools.

## Development

[AGENTS.md](AGENTS.md) contains the project conventions and development guidance for coding agents and contributors. Changes should follow conventional Rails patterns, preserve marketplace invariants, and include focused RSpec coverage.
