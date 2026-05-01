#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);

function readArg(name, fallback = undefined) {
  const prefix = `${name}=`;
  const inline = args.find((arg) => arg.startsWith(prefix));
  if (inline) return inline.slice(prefix.length);
  const index = args.indexOf(name);
  if (index >= 0 && args[index + 1] && !args[index + 1].startsWith("--")) {
    return args[index + 1];
  }
  return fallback;
}

function readRepeatedArg(name) {
  const prefix = `${name}=`;
  const values = [];
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg.startsWith(prefix)) values.push(arg.slice(prefix.length));
    if (arg === name && args[index + 1] && !args[index + 1].startsWith("--")) {
      values.push(args[index + 1]);
      index += 1;
    }
  }
  return values;
}

const strict = args.includes("--strict");
const cwd = process.cwd();
const explicitWebDir = readArg("--web-dir");
const webDir = path.resolve(explicitWebDir ?? (fs.existsSync(path.join(cwd, "apps/web/package.json")) ? path.join(cwd, "apps/web") : cwd));
const srcDir = path.join(webDir, "src");
const indexPath = path.resolve(readArg("--index", path.join(webDir, "storybook-static/index.json")));
const forbiddenTitlePatterns = readRepeatedArg("--forbid-title-pattern").map((pattern) => new RegExp(pattern, "i"));
const findings = [];
const notes = [];

function addFinding(kind, message, detail) {
  findings.push({ kind, message, detail });
}

function normalizeImportPath(filePath) {
  return filePath.split(path.sep).join("/").replace(/^\.\//, "");
}

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  return entries.flatMap((entry) => {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) return walk(fullPath);
    return [fullPath];
  });
}

function loadStorybookEntries() {
  if (!fs.existsSync(indexPath)) {
    addFinding(
      "missing-index",
      "Missing Storybook static index.",
      `Expected ${indexPath}. Run npm run build-storybook before the correspondence check.`,
    );
    return [];
  }

  try {
    const index = JSON.parse(fs.readFileSync(indexPath, "utf8"));
    return Object.values(index.entries ?? {});
  } catch (error) {
    addFinding("invalid-index", "Could not parse Storybook static index.", `${indexPath}: ${error.message}`);
    return [];
  }
}

function classifyStory(relPath) {
  const normalized = normalizeImportPath(relPath);
  const parts = normalized.split("/");
  const fromSrc = normalized.startsWith("src/");
  if (!fromSrc) return null;

  if (parts[1] === "design-system") {
    const layer = parts[2];
    if (["atoms", "molecules", "organisms"].includes(layer)) {
      const titleLayer = layer[0].toUpperCase() + layer.slice(1);
      return { area: "design-system", titleIncludes: `Design System/${titleLayer}`, layer };
    }
    return { area: "design-system", titleIncludes: "Design System/", layer: "unknown" };
  }

  if (parts[1] === "features") {
    const layer = parts[3];
    const titleLayer = {
      components: "Components",
      screens: "Screens",
      spikes: "Spikes",
    }[layer];

    if (titleLayer) {
      return { area: "features", titleIncludes: `/` + titleLayer, layer };
    }

    return { area: "features", titleIncludes: "Features/", layer: layer ?? "unknown" };
  }

  return null;
}

const entries = loadStorybookEntries();
const sourceStoryFiles = walk(srcDir)
  .filter((filePath) => /\.stories\.(ts|tsx|js|jsx)$/.test(filePath))
  .map((filePath) => normalizeImportPath(path.relative(webDir, filePath)));

const indexedByImportPath = new Map();
for (const entry of entries) {
  if (!entry.importPath) continue;
  const importPath = normalizeImportPath(entry.importPath);
  indexedByImportPath.set(importPath, entry);
}

for (const storyPath of sourceStoryFiles) {
  const entry = indexedByImportPath.get(storyPath);
  const classification = classifyStory(storyPath);

  if (!entry) {
    addFinding("missing-story-index-entry", "Source story file is absent from Storybook index.", storyPath);
    continue;
  }

  if (classification && !String(entry.title ?? "").includes(classification.titleIncludes)) {
    addFinding(
      "title-path-mismatch",
      "Story title does not match the source taxonomy layer.",
      `${storyPath} -> "${entry.title}" should include "${classification.titleIncludes}"`,
    );
  }
}

for (const entry of entries) {
  if (!entry.importPath) continue;
  const importPath = normalizeImportPath(entry.importPath);
  if (!importPath.startsWith("src/design-system/") && !importPath.startsWith("src/features/")) continue;

  const absoluteImportPath = path.join(webDir, importPath);
  if (!fs.existsSync(absoluteImportPath)) {
    addFinding("stale-index-entry", "Storybook index points at a missing source file.", `${entry.title}: ${importPath}`);
  }

  const classification = classifyStory(importPath);
  if (classification && !String(entry.title ?? "").includes(classification.titleIncludes)) {
    addFinding(
      "indexed-title-path-mismatch",
      "Indexed story title does not match the source taxonomy layer.",
      `${importPath} -> "${entry.title}" should include "${classification.titleIncludes}"`,
    );
  }

  for (const pattern of forbiddenTitlePatterns) {
    if (pattern.test(String(entry.title ?? ""))) {
      addFinding("forbidden-title", "Storybook index contains a forbidden title pattern.", `${entry.title} matches ${pattern}`);
    }
  }
}

if (fs.existsSync(path.resolve(webDir, "../../docs/rebuild/ux/STORYBOOK-STRUCTURE.md"))) {
  notes.push("Found docs/rebuild/ux/STORYBOOK-STRUCTURE.md and checked source/story taxonomy correspondence against it.");
} else {
  notes.push("No STORYBOOK-STRUCTURE.md found near apps/web; checked generic design-system/features taxonomy only.");
}

console.log("Storybook correspondence report");
console.log(`webDir: ${webDir}`);
console.log(`index: ${indexPath}`);
console.log(`source stories: ${sourceStoryFiles.length}`);
console.log(`indexed entries: ${entries.length}`);
for (const note of notes) console.log(`note: ${note}`);

if (!findings.length) {
  console.log("status: PASS");
  console.log("No correspondence findings.");
  process.exit(0);
}

console.log("status: REVIEW");
console.log(`findings: ${findings.length}`);
findings.forEach((finding, index) => {
  console.log(`${index + 1}. [${finding.kind}] ${finding.message}`);
  console.log(`   ${finding.detail}`);
});
console.log("");
console.log("Operator options:");
console.log("1. Fix source/story taxonomy titles or move stories to the matching folder.");
console.log("2. Re-run npm run build-storybook, then re-run this report.");
console.log("3. Accept the finding for this batch and document why in the handoff or PR.");
console.log("4. Re-run with --strict if this project wants findings to fail automation.");

process.exit(strict ? 1 : 0);
