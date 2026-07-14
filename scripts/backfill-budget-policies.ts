import { agents, budgetPolicies, companies, createDb } from "../packages/db/src/index.js";
import { budgetService } from "../server/src/services/budgets.js";

function hasFlag(name: string): boolean {
  return process.argv.includes(name);
}

function parseFlag(name: string): string | null {
  const index = process.argv.indexOf(name);
  if (index < 0) return null;
  const value = process.argv[index + 1];
  return value && !value.startsWith("--") ? value : null;
}

async function main() {
  const dryRun = hasFlag("--dry-run");
  const targetCompanyId = parseFlag("--company");

  const dbUrl =
    process.env.DATABASE_URL?.trim()
    || "postgres://paperclip:paperclip@127.0.0.1:5432/paperclip";

  const db = createDb(dbUrl);
  const budgets = budgetService(db);

  if (dryRun) {
    console.log("[DRY RUN] No writes will be made.");
  }

  // Fetch everything and filter in JS — avoids importing drizzle-orm operators
  const [allCompanies, allAgents, allPolicies] = await Promise.all([
    db.select({ id: companies.id }).from(companies),
    db.select({
      id: agents.id,
      companyId: agents.companyId,
      name: agents.name,
      budgetMonthlyCents: agents.budgetMonthlyCents,
      status: agents.status,
      pauseReason: agents.pauseReason,
    }).from(agents),
    db.select({
      id: budgetPolicies.id,
      companyId: budgetPolicies.companyId,
      scopeType: budgetPolicies.scopeType,
      scopeId: budgetPolicies.scopeId,
      metric: budgetPolicies.metric,
      windowKind: budgetPolicies.windowKind,
    }).from(budgetPolicies),
  ]);

  const targetCompanies = targetCompanyId
    ? allCompanies.filter((c) => c.id === targetCompanyId)
    : allCompanies;

  if (targetCompanies.length === 0) {
    console.log("No matching companies found; nothing to backfill.");
    return;
  }

  // Build a set of (companyId, agentId) pairs that already have a monthly policy
  const existingPolicyKey = new Set(
    allPolicies
      .filter(
        (p) =>
          p.scopeType === "agent" &&
          p.metric === "billed_cents" &&
          p.windowKind === "calendar_month_utc",
      )
      .map((p) => `${p.companyId}:${p.scopeId}`),
  );

  let inserted = 0;
  let alreadyExists = 0;
  let dryRunPending = 0;

  for (const company of targetCompanies) {
    const cappedAgents = allAgents.filter(
      (a) =>
        a.companyId === company.id &&
        a.budgetMonthlyCents > 0 &&
        a.name !== "Watchdog Bot",
    );

    if (cappedAgents.length === 0) continue;

    for (const agent of cappedAgents) {
      const hasPolicy = existingPolicyKey.has(`${company.id}:${agent.id}`);

      if (hasPolicy) {
        console.log(
          `  [already-exists] ${agent.name} (cap $${(agent.budgetMonthlyCents / 100).toFixed(2)})`,
        );
        alreadyExists++;
        continue;
      }

      console.log(
        `  [${dryRun ? "dry-run" : "inserting"}] ${agent.name} — cap $${(agent.budgetMonthlyCents / 100).toFixed(2)}, status=${agent.status}${agent.pauseReason ? `(${agent.pauseReason})` : ""}`,
      );

      if (dryRun) {
        dryRunPending++;
        continue;
      }

      await budgets.upsertPolicy(
        company.id,
        {
          scopeType: "agent",
          scopeId: agent.id,
          amount: agent.budgetMonthlyCents,
          metric: "billed_cents",
          windowKind: "calendar_month_utc",
          hardStopEnabled: true,
          notifyEnabled: true,
        },
        null,
      );
      inserted++;
    }
  }

  if (dryRun) {
    console.log(
      `\nDry-run complete. Would insert: ${dryRunPending}, already exist: ${alreadyExists}.`,
    );
  } else {
    console.log(
      `\nBackfill complete. Inserted: ${inserted}, already existed: ${alreadyExists}.`,
    );
  }
}

void main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Budget policy backfill failed: ${message}`);
  process.exitCode = 1;
});
