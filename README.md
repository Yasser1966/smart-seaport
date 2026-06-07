# Smart Seaport Project Documentation

## Current Status
- **Authentication:** Handshake with Keycloak is successful.
- **Frontend:** Next.js application is running, but experiencing 404 errors on specific routes (e.g., `/gates`).
- **Infrastructure:** The project directory `C:\smart-seaport` appears to be missing essential deployment configuration files (empty `configs/` and `scripts/` directories).

## Troubleshooting Checklist
1. **Infrastructure Recovery:** - The empty `docker-compose.yml` and empty subdirectories indicate a missing deployment structure.
    - If this was a Git clone, run `git submodule update --init --recursive` to pull submodules.
    - If manual setup is required, a base `docker-compose.yml` must be created to define the Proxy, Keycloak, and Frontend services.

2. **Routing (404 Fixes):**
    - Ensure `app/gates/page.tsx` exists.
    - Verify that the Proxy (Nginx) is configured to route traffic to the Next.js port (default 3000).
    - Clear browser cache and `.next` build files.

3. **Development Commands:**
    - Build: `npm run build`
    - Start Development: `npm run dev`

## Next Steps
1. Locate the correct `docker-compose.yml` or define a new one to orchestrate the services.
2. Once the environment is running, verify the Proxy `location /` configuration to ensure traffic flows correctly from the proxy to the Next.js frontend.
3. Once routing is fixed, finalize the `Gate Lane Stream` module in `LaneMonitor.tsx`.
