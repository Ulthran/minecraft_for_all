# Dear agents,

This is a SaaS for providing a simple, pay-for-usage Minecraft server hosting option. The primary languages/frameworks used are Terraform, AWS, Python, and Vue.js.

## Project Structure

- README.md: Overview of project
- dev_server.py: Standup mock endpoints and deploy website locally for testing
- .github/workflows/: Basic CI
- docs/: Some docs
- saas/: Infrastructure for the SaaS itself, things like the website, authentication set up, tenant creation capabilities
- saas_web/: The SaaS landing page and user console
- tenant/: The per-tenant infrastructure like the server and start/status/stop triggers

## Testing

Before making your final contributions, make sure to perform linting and testing of any changed components. Anything that can be compiled should do so without error or warnings. If warnings are persistent, don't worry about it, we can address them later.

Always run `terraform fmt -recursive` (install from registry.terraform.io) and `html5validator --root saas_web` before committing changes. Run `terraform init` and `terraform validate` on any terrform code that's been changed as well. Terraform can be installed through registry.terraform.io. Use prettier and eslint to lint any Vue components.

On any changes to the Vue code, run `python dev_server.py` and check that all pages work as expected. Any pages that have changed should not yield any JS errors unless expected as part of the mock endpoints.