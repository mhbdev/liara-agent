#!/usr/bin/env node
import { existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, realpathSync, writeFileSync } from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const source = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const normalize = text => text.replace(/\r\n/g, '\n').trimEnd();
const stable = value => JSON.stringify(value, (_, entry) =>
  entry && typeof entry === 'object' && !Array.isArray(entry)
    ? Object.fromEntries(Object.entries(entry).sort(([a], [b]) => a.localeCompare(b)))
    : entry);

function options() {
  let project = process.cwd();
  let dryRun = false;
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--help' || args[i] === '-h') {
      console.log('Usage: liara-agent [--project <website-folder>] [--dry-run]\n\nRun from your website folder. Existing project instructions and settings are preserved.\nNo tokens are read, no account is connected, and nothing is deployed.');
      return null;
    }
    if (args[i] === '--dry-run') dryRun = true;
    else if (args[i] === '--project' && args[i + 1] && !args[i + 1].startsWith('--')) project = args[++i];
    else throw new Error('Unknown or incomplete option. Use --help for usage.');
  }
  return { project: realpathSync(resolve(project)), dryRun };
}

function object(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} must be a JSON object. Repair the settings before installing.`);
  }
  return value;
}

function union(current = [], additions, label) {
  if (!Array.isArray(current)) throw new Error(`${label} must be a list. Repair the settings before installing.`);
  const result = [...current];
  for (const item of additions) {
    if (!result.some(existing => stable(existing) === stable(item))) result.push(item);
  }
  return result;
}

function mergeSettings(text) {
  let settings;
  try { settings = JSON.parse(text); }
  catch { throw new Error('Cannot parse .claude/settings.json. Repair its JSON before installing.'); }
  object(settings, '.claude/settings.json');
  if (settings.disableAllHooks === true) {
    throw new Error('Claude hooks are disabled in .claude/settings.json. Review that setting before installing.');
  }
  const supplied = JSON.parse(readFileSync(join(source, '.claude/settings.json'), 'utf8'));
  const permissions = object(settings.permissions ?? {}, 'permissions');
  const hooks = object(settings.hooks ?? {}, 'hooks');
  settings.permissions = { ...permissions };
  for (const key of ['allow', 'deny']) {
    settings.permissions[key] = union(permissions[key], supplied.permissions[key], `permissions.${key}`);
  }
  settings.hooks = {
    ...hooks,
    PreToolUse: union(hooks.PreToolUse, supplied.hooks.PreToolUse, 'hooks.PreToolUse'),
  };
  if (!settings.$schema) settings.$schema = supplied.$schema;
  return `${JSON.stringify(settings, null, 2)}\n`;
}

function appendSection(current, content, id) {
  const start = `<!-- liara-agent:${id} -->`;
  const end = `<!-- /liara-agent:${id} -->`;
  const block = `${start}\n${normalize(content)}\n${end}`;
  if (current.includes(start) || current.includes(end)) {
    if (normalize(current).includes(block)) return current;
    throw new Error(`The existing Liara ${id} section differs. Review it before updating; nothing was overwritten.`);
  }
  if (normalize(current) === normalize(content)) return current;
  return `${current}${current && !current.endsWith('\n') ? '\n' : ''}${current ? '\n' : ''}${block}\n`;
}

function install({ project, dryRun }) {
  if (project === realpathSync(source)) {
    throw new Error('This is the agent pack itself. Run the installer from your website folder, or use --project <website-folder>.');
  }
  const plan = [];
  const conflicts = [];
  const kept = [];

  // Inspect only declared installation destinations, never credential/state files.
  function destination(name) {
    const path = resolve(project, name);
    const rel = relative(project, path);
    if (rel.startsWith('..') || isAbsolute(rel)) throw new Error(`Invalid installation path: ${name}`);
    const segments = rel.split(/[\\/]/);
    let cursor = project;
    for (let i = 0; i < segments.length; i++) {
      cursor = join(cursor, segments[i]);
      let stat;
      try { stat = lstatSync(cursor); }
      catch (error) { if (error.code === 'ENOENT') continue; throw error; }
      if (stat.isSymbolicLink()) throw new Error(`Refusing linked installation path: ${name}. Review it before installing.`);
      if (i < segments.length - 1 && !stat.isDirectory()) throw new Error(`Installation path is not a folder: ${name}`);
      if (i === segments.length - 1 && !stat.isFile()) throw new Error(`Installation destination is not a file: ${name}`);
    }
    return path;
  }

  function add(name, content, mode = 'copy', id = name) {
    const path = destination(name);
    let desired = content;
    const exists = existsSync(path);
    if (exists) {
      if (mode === 'keep') { kept.push(name); return; }
      const current = readFileSync(path, 'utf8');
      if (mode === 'append') desired = appendSection(current, content, id);
      else if (mode === 'settings') desired = mergeSettings(current);
      else if (mode !== 'replace' && normalize(current) !== normalize(content)) { conflicts.push(name); return; }
      if (normalize(current) === normalize(desired)) return;
    } else if (mode === 'append') desired = appendSection('', content, id);
    plan.push({ name, path, content: desired, exists });
  }

  function copy(name, mode) {
    add(name, readFileSync(join(source, name), 'utf8'), mode);
  }

  function tree(folder, target = folder) {
    for (const entry of readdirSync(join(source, folder), { withFileTypes: true })) {
      const from = `${folder}/${entry.name}`;
      const to = `${target}/${entry.name}`;
      if (entry.isDirectory()) tree(from, to);
      else if (entry.isFile()) add(to, readFileSync(join(source, from), 'utf8'));
      else throw new Error(`Unexpected linked source asset: ${from}`);
    }
  }

  copy('AGENTS.md', 'append');
  copy('CLAUDE.md', 'append');
  tree('.claude/agents');
  tree('.claude/commands');
  tree('.claude/skills/liara-ops');
  tree('.claude/skills/liara-ops', '.agents/skills/liara-ops');
  copy('.claude/settings.json', 'settings');
  copy('.codex/config.toml', 'keep');
  tree('scripts');
  tree('docs/en');
  tree('docs/fa');
  for (const name of ['tests/guard-cases.txt', 'env.example', 'liara.json.example', 'OPERATIONS.template.md']) copy(name);

  const guidance = 'Before Liara tasks, read AGENTS.md and .claude/skills/liara-ops/SKILL.md.\nStart with .claude/agents/liara-connect.md, then liara-onboarding.md.\nDefault to staging. Token entry and approval grants belong to the human.\n';
  add('GEMINI.md', `@./AGENTS.md\n\n${guidance}`, 'append', 'gemini');
  add('.cursor/rules/liara.mdc', `---\ndescription: Liara operations\nalwaysApply: true\n---\n${guidance}`);
  add('.windsurf/rules/liara.md', `---\ntrigger: always_on\n---\n${guidance}`);
  add('.aider.conf.yml', 'read:\n  - AGENTS.md\n  - .claude/skills/liara-ops/SKILL.md\n  - .claude/agents/liara-connect.md\n', 'keep');
  // Append only the required ignore rules; preserve all existing project rules.
  const ignorePath = destination('.gitignore');
  const existingIgnore = existsSync(ignorePath) ? readFileSync(ignorePath, 'utf8') : '';
  const marker = '# Liara agent: credentials and local state';
  const ignoreBlock = `${marker}\n.liara/\n.env\n.env.*\n!.env.example\nstate/\n`;
  if (!normalize(existingIgnore).endsWith(normalize(ignoreBlock))) {
    add('.gitignore', `${existingIgnore}${existingIgnore && !existingIgnore.endsWith('\n') ? '\n' : ''}\n${ignoreBlock}`, 'replace');
  }

  if (conflicts.length) {
    throw new Error(`Existing pack files differ; no files were changed:\n${conflicts.map(name => `  ${name}`).join('\n')}\nCompare these files with the pack before retrying. There is no overwrite option.`);
  }
  if (dryRun) {
    console.log(`Preview: ${plan.length} file(s) would be added or updated in ${project}.`);
    for (const item of plan) console.log(`  ${item.exists ? 'merge' : 'add'} ${item.name}`);
    console.log('No files changed.');
    return;
  }
  // All conflicts, JSON and destination paths are checked before the first write.
  for (const item of plan) {
    mkdirSync(dirname(item.path), { recursive: true });
    writeFileSync(item.path, item.content, { encoding: 'utf8', flag: item.exists ? 'w' : 'wx', mode: item.name.endsWith('.sh') ? 0o755 : 0o644 });
  }
  console.log(`Liara agents installed in ${project} (${plan.length} file(s) added or updated).`);
  console.log('Claude Code, Codex, Cursor, Windsurf, Aider and Gemini project files are ready.');
  if (kept.includes('.aider.conf.yml')) console.log('Existing Aider settings kept. Start with: aider --read AGENTS.md --read .claude/agents/liara-connect.md --read .claude/skills/liara-ops/SKILL.md');
  console.log('\nNext: restart your coding agent in this folder and say:\n  "Help me connect Liara and configure this project for staging."');
  console.log('\nYour agent can guide prerequisite checks. Token entry stays in your own terminal.');
  console.log('This installs project files only; it does not connect an account or deploy.');
  console.log('Before deployment, run setup checks and the guard suite. Known guard failures: docs/en/07-security.md');
}

try {
  const config = options();
  if (config) install(config);
} catch (error) {
  console.error(`Installation stopped: ${error.code ? 'Cannot access an installation path. Check the project folder and file permissions.' : error.message}`);
  process.exitCode = 1;
}
