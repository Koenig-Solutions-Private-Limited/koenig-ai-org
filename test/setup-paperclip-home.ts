import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const paperclipHome =
  process.env.PAPERCLIP_HOME?.trim() ||
  path.join(os.tmpdir(), `paperclip-vitest-home-${process.pid}`);

process.env.PAPERCLIP_HOME = paperclipHome;

const instanceRoot = path.join(paperclipHome, "instances", "default");
for (const segment of ["logs", "workspaces", "db", "data/storage", "secrets"]) {
  fs.mkdirSync(path.join(instanceRoot, segment), { recursive: true });
}
