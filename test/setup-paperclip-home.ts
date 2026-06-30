import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const paperclipHome =
  process.env.PAPERCLIP_HOME?.trim() ||
  path.join(os.tmpdir(), `paperclip-vitest-home-${process.pid}`);

process.env.PAPERCLIP_HOME = paperclipHome;

const instanceRoot = path.join(paperclipHome, "instances", "default");
for (const segment of ["logs", "workspaces", "db", "data/storage", "secrets"]) {
  fs.mkdirSync(path.join(instanceRoot, segment), { recursive: true });
}

// Agent runtimes inject DATABASE_URL for the live server. Vitest precedence tests
// must start without it unless they set DATABASE_URL explicitly.
delete process.env.DATABASE_URL;

const hermesServerEntry = path.join(
  repoRoot,
  "packages/adapters/hermes-local/dist/server/index.js",
);
if (!fs.existsSync(hermesServerEntry)) {
  execSync("pnpm --filter @paperclipai/adapter-hermes-local build", {
    cwd: repoRoot,
    stdio: "pipe",
  });
}
