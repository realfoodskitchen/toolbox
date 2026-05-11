You are an expert cloud platform architect and UX-oriented technical systems designer.

I have an existing 2400-line Markdown strategic plan for building and governing an Azure tenant environment. The current document is too linear and difficult to operationalize.

Your task is NOT to rewrite the Markdown.

Your task is to transform the strategy into an interactive operational workspace that is easier for humans and AI agents to navigate, understand, and continue working from.

Generate a self-contained output using HTML, CSS, and JavaScript where appropriate. Favor single-file portability when possible.

The resulting artifact should function like a lightweight operational portal for the Azure tenant strategy.

Core requirements:

1. Create a visual Azure platform architecture explorer

* Show:
    * management groups
    * subscriptions
    * hub/spoke networking
    * identity/security boundaries
    * logging and monitoring flows
    * platform shared services
* Use diagrams, cards, SVGs, or interactive sections
* Allow collapsing/expanding sections

2. Convert deployment phases into an operational planning board

* Create Kanban-style sections:
    * Now
    * Next
    * Later
    * Blocked
* Each work item should support:
    * description
    * dependencies
    * risks
    * owners
    * Terraform/OpenTofu modules
    * rollback considerations
    * status

3. Build an Azure Policy and Governance Explorer

* Organize:
    * policy initiatives
    * individual policies
    * inheritance scope
    * exemptions
    * compliance goals
* Include filtering/search capabilities
* Visually distinguish:
    * required controls
    * recommended controls
    * optional controls

4. Create an RBAC and Identity Model Viewer

* Visualize:
    * platform admin roles
    * application team permissions
    * PIM eligible roles
    * managed identities
    * break-glass accounts
    * service principals
* Include privilege inheritance and scope relationships

5. Build an Infrastructure-as-Code dependency explorer

* Show:
    * Terraform/OpenTofu module relationships
    * deployment order
    * shared modules
    * environment separation
    * state boundaries
* Prefer graph visualization over prose

6. Add operational dashboards and summaries
    Include:

* risk summary
* deployment readiness indicators
* governance maturity tracking
* security posture checklist
* logging/monitoring status
* compliance coverage overview

7. Prioritize usability over documentation
    The goal is NOT to create a prettier document.

The goal is to create:

* an operational interface
* a planning workspace
* a system humans and AI agents can continue working from

8. Design requirements

* Responsive layout
* Dark mode preferred
* Use clean professional styling
* Avoid framework bloat unless necessary
* Prefer lightweight vanilla JS where possible
* Use cards, diagrams, timelines, graphs, tabs, filters, and expandable panels
* Minimize long-form prose

9. Preserve strategic intent
    Do not lose:

* governance rationale
* security principles
* architectural decisions
* deployment sequencing
* operational constraints

10. Output requirements

* Produce a working prototype, not pseudocode
* Generate complete runnable files
* Include comments explaining architecture decisions
* Make the interface extensible for future AI-generated updates

11. Important design philosophy
    Treat the original Markdown as raw knowledge input.

The final deliverable should behave like:

* a lightweight Azure platform operations console
* a cloud architecture workspace
* a governance control center

NOT like a document.

Where possible:

* replace paragraphs with visualizations
* replace static tables with interactive filtering
* replace sequential text with navigable structures
* replace explanations with operational affordances

Assume the primary users are:

* cloud platform engineers
* security architects
* governance teams
* future AI agents continuing the work