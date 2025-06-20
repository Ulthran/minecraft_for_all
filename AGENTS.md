# Dear agents,

This is a SaaS for providing a simple, pay-for-usage Minecraft server hosting option. The primary languages/frameworks used are Terraform, AWS, Python, and Vue.js.

## Project Structure

- README.md: Overview of project
- dev_server.py: Standup mock endpoints and deploy website locally for testing
- .github/workflows/: Basic CI
- docs/: Some docs
- saas/: Infrastructure for the SaaS itself, things like the website, authentication set up, tenant creation capabilities
- saas_web/: The SaaS landing page and user console
- terraform/: The per-tenant infrastructure like the server and start/status/stop triggers

## Testing

Before making your final contributions, make sure to perform thorough linting and testing of any changed components. For any subdirectory of root that there are changes for, make sure to at least do what the corresponding GitHub Actions workflow would do and verify the outcomes are passing.

Testing is very lightweight for now as we don't actually have anything in production yet.