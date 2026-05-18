# AGL Bluetooth Integration - GSoC 2026

Welcome to the Automotive Grade Linux (AGL) Bluetooth Integration repository for GSoC 2026.

## Repository Structure

- **/docs**: The official Jaspr-based technical documentation and progress tracking site for the GSoC project.
- **/** (Root): Reserved for the core GSoC integration code and implementation work.

---

## Technical Documentation (`/docs`)

The documentation site is built using the [Jaspr](https://github.com/schultek/jaspr) web framework.

### Getting Started with Docs

1. Navigate to the `docs` directory:
   ```bash
   cd docs
   ```

2. Run the development server:
   ```bash
   jaspr serve
   ```
   The site will be live at `http://localhost:8080`.

3. Build the static site:
   ```bash
   jaspr build
   ```
   The production build output will be located in the `docs/build/jaspr/` directory.
