import { Turbo } from "@hotwired/turbo-rails"

if (document.modelContext && !window.__gigooWebMcpRegistrationAttempted) {
  window.__gigooWebMcpRegistrationAttempted = true

  const fetchJson = async (url, options = {}) => {
    const response = await fetch(url, {
      ...options,
      headers: { Accept: "application/json", ...options.headers },
      credentials: "same-origin"
    })

    if (!response.ok) {
      const result = await response.json().catch(() => ({}))
      throw new Error(result.error || `Gigoo request failed with status ${response.status}`)
    }

    return response.json()
  }

  const searchUrl = (path, input) => {
    const parameters = new URLSearchParams()

    Object.entries(input || {}).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== "") parameters.set(key, value)
    })

    const query = parameters.toString()
    return query ? `${path}?${query}` : path
  }

  const postJson = (url, body) => fetchJson(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
    },
    body: JSON.stringify(body)
  })

  const addToShortlist = async (input) => {
    const result = await postJson("/webmcp/shortlists", input)

    setTimeout(() => Turbo.visit(window.location.href, { action: "replace" }), 0)
    return result
  }

  try {
    document.modelContext.registerTool({
      name: "search_jobs",
      description: "Search currently open freelance jobs on Gigoo by text, skill, and maximum budget.",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Text to match against the job title or description." },
          skill: { type: "string", description: "Required marketplace skill such as Rails or PostgreSQL." },
          max_budget_usd: { type: "number", minimum: 0, description: "Maximum total job budget in US dollars." },
          limit: { type: "integer", minimum: 1, maximum: 20, description: "Maximum number of jobs to return." }
        },
        additionalProperties: false
      },
      annotations: { readOnlyHint: true },
      execute: (input) => fetchJson(searchUrl("/webmcp/jobs", input))
    })

    document.modelContext.registerTool({
      name: "get_job",
      description: "Get detailed public information about one currently open Gigoo job.",
      inputSchema: {
        type: "object",
        properties: {
          job_id: { type: "integer", description: "Gigoo job ID." }
        },
        required: ["job_id"],
        additionalProperties: false
      },
      annotations: { readOnlyHint: true },
      execute: ({ job_id }) => fetchJson(`/webmcp/jobs/${encodeURIComponent(job_id)}`)
    })

    document.modelContext.registerTool({
      name: "search_freelancers",
      description: "Search Gigoo freelancer profiles by expertise, location, and hourly rate, with grounded trust evidence.",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Text to match against professional title, bio, or location." },
          skill: { type: "string", description: "Required skill such as Rails, PostgreSQL, AWS, or Hotwire." },
          location: { type: "string", description: "Optional location text." },
          max_hourly_rate_usd: { type: "number", minimum: 0, description: "Maximum freelancer hourly rate in US dollars." },
          limit: { type: "integer", minimum: 1, maximum: 20, description: "Maximum number of freelancers to return." }
        },
        additionalProperties: false
      },
      annotations: { readOnlyHint: true },
      execute: (input) => fetchJson(searchUrl("/webmcp/freelancers", input))
    })

    document.modelContext.registerTool({
      name: "get_freelancer",
      description: "Get one freelancer's public profile, completed-work evidence, and recent client reviews.",
      inputSchema: {
        type: "object",
        properties: {
          freelancer_id: { type: "integer", description: "Gigoo freelancer profile ID." }
        },
        required: ["freelancer_id"],
        additionalProperties: false
      },
      annotations: { readOnlyHint: true },
      execute: ({ freelancer_id }) => fetchJson(`/webmcp/freelancers/${encodeURIComponent(freelancer_id)}`)
    })

    document.modelContext.registerTool({
      name: "get_client",
      description: "Get one client's public Gigoo profile, completed hiring history, payment verification, and recent freelancer reviews.",
      inputSchema: {
        type: "object",
        properties: {
          client_id: { type: "integer", description: "Gigoo client profile ID." }
        },
        required: ["client_id"],
        additionalProperties: false
      },
      annotations: { readOnlyHint: true },
      execute: ({ client_id }) => fetchJson(`/webmcp/clients/${encodeURIComponent(client_id)}`)
    })

    document.modelContext.registerTool({
      name: "add_to_shortlist",
      description: "Add a freelancer to the authenticated client's shortlist for one of their open Gigoo jobs.",
      inputSchema: {
        type: "object",
        properties: {
          job_id: { type: "integer", minimum: 1, description: "Gigoo job ID owned by the authenticated client." },
          freelancer_id: { type: "integer", minimum: 1, description: "Gigoo freelancer profile ID." }
        },
        required: ["job_id", "freelancer_id"],
        additionalProperties: false
      },
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: true
      },
      execute: addToShortlist
    })

    window.__gigooWebMcpRegistered = true
  } catch (error) {
    console.warn("Gigoo WebMCP tools could not be registered.", error)
  }
}
