## Project

Gigoo is a trusted, agent-native freelancer marketplace built with Ruby on Rails.

The product supports both clients and freelancers in the same user account. Trust and reputation are mutual: clients evaluate freelancers, and freelancers evaluate clients.

## Stack

* Ruby on Rails 8
* PostgreSQL
* Hotwire
* Stimulus
* Tailwind CSS
* Rails built-in authentication
* Pundit
* RSpec
* FactoryBot
* WebMCP
* OpenAI API where useful for review analysis

## Development Style

Follow conventional Rails patterns.

Prefer:

* simple models
* thin controllers
* RESTful routes
* small Pundit policies
* server-rendered Rails views
* Hotwire before custom JavaScript
* database constraints for important invariants
* focused RSpec coverage

Avoid unnecessary:

* service objects
* concerns
* form objects
* decorators
* presenters
* state machine gems
* command/query layers
* JavaScript frameworks
* premature abstractions

Introduce abstractions only when duplication or complexity clearly justifies them.

## Feature Development

Work by vertical feature slice.

A feature should normally include everything it needs:

* model/domain changes
* policy
* routes
* controller actions
* views
* tests

Do not build all controllers, policies, or views upfront.

Finish one usable feature before moving to the next.

## User Model

`User.role` is only for system-level privileges:

* `member`
* `support`
* `admin`

Do not add `client` or `freelancer` roles.

Marketplace capabilities come from profile presence:

```ruby
user.client_profile.present?
user.freelancer_profile.present?
```

A user may have:

* only a ClientProfile
* only a FreelancerProfile
* both profiles

## Marketplace Rules

Important domain rules should be enforced at the model and database level where practical.

Examples:

* users cannot propose to their own jobs
* users cannot shortlist themselves
* client and freelancer on a contract must be different users
* reviews must come from a completed contract
* reviews can only be exchanged between the two contract parties
* only one proposal per freelancer per job
* only one review per reviewer per contract

Do not rely only on controller checks for important invariants.

## Authorization

Use Pundit.

Do not infer marketplace capability from `User.role`.

Use:

* profile presence for client/freelancer capability
* ownership for marketplace records
* `support` and `admin` only for explicit platform-level permissions

Do not give support/admin implicit ownership of marketplace records.

## Money

Store monetary values as integer cents.

Example:

```ruby
budget_cents
amount_cents
hourly_rate_cents
```

Gigoo MVP currently assumes USD.

Do not introduce multi-currency support unless explicitly requested.

## JavaScript

Prefer Hotwire and Stimulus.

Use Importmap.

Do not add React, Vue, or another frontend framework.

Keep JavaScript small and progressive.

WebMCP code may use:

```javascript
document.modelContext.registerTool(...)
```

Do not implement WebMCP tools until the underlying product action already works normally through the Rails application.

## Testing

Use RSpec.

Prefer:

* model specs for domain rules
* policy specs for meaningful authorization rules
* request specs for feature behavior

Avoid testing Rails internals or trivial implementation details.

Before finishing work, run:

```bash
bin/rspec
```

Fix failures caused by the change.

## Code Quality

Keep code concise, readable, and idiomatic.

Prefer explicit code over clever abstractions.

Match existing naming and structure.

Do not refactor unrelated code while implementing a feature.

Do not introduce new gems unless clearly necessary.

## Database

Use PostgreSQL features where they simplify the implementation.

Existing examples include string arrays for skills.

Use:

* foreign keys
* unique indexes
* non-null constraints
* sensible defaults

when they protect real domain invariants.

## Workflow

Before making changes:

1. Inspect the existing implementation.
2. Understand the current feature and domain rules.
3. Make the smallest coherent change.
4. Add or update focused tests.
5. Run `bin/rspec`.
6. Summarize what changed.

Do not commit changes unless explicitly asked.
