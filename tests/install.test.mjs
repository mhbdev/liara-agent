import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmdirSync, symlinkSync, unlinkSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const cli = join(root, 'bin/install.mjs');

function removeFixture(path) {
  for (const entry of readdirSync(path, { withFileTypes: true })) {
    const child = join(path, entry.name);
    if (entry.isDirectory() && !entry.isSymbolicLink()) removeFixture(child);
    else unlinkSync(child);
  }
  rmdirSync(path);
}

function fixture(t) {
  const path = mkdtempSync(join(tmpdir(), 'liara installer test '));
  t.after(() => removeFixture(path));
  return path;
}

function put(project, name, content) {
  const path = join(project, name);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content);
}

function run(project, args = []) {
  return spawnSync(process.execPath, [cli, ...args], { cwd: project, encoding: 'utf8' });
}

function snapshot(project, prefix = '') {
  const files = {};
  for (const entry of readdirSync(join(project, prefix), { withFileTypes: true })) {
    const name = join(prefix, entry.name);
    if (entry.isSymbolicLink()) files[name] = 'symlink';
    else if (entry.isDirectory()) Object.assign(files, snapshot(project, name));
    else files[name] = createHash('sha256').update(readFileSync(join(project, name))).digest('hex');
  }
  return files;
}

test('installs all clients into a project with spaces without replacing application files', t => {
  const project = fixture(t);
  put(project, 'README.md', 'My website\n');
  put(project, 'package.json', '{"name":"my-website","private":true}\n');
  put(project, 'scripts/build.js', '// Existing build\n');
  put(project, 'docs/architecture.md', 'Existing docs\n');
  const before = snapshot(project);
  const result = run(project);
  assert.equal(result.status, 0, result.stderr);
  const after = snapshot(project);
  for (const [name, hash] of Object.entries(before)) assert.equal(after[name], hash, name);
  for (const name of ['AGENTS.md', 'CLAUDE.md', '.claude/settings.json', '.codex/config.toml', '.agents/skills/liara-ops/SKILL.md', '.cursor/rules/liara.mdc', '.windsurf/rules/liara.md', 'GEMINI.md', '.aider.conf.yml', 'scripts/lib/common.sh', 'docs/en/00-installation.md', 'docs/fa/00-installation.md']) {
    assert.ok(existsSync(join(project, name)), name);
  }
  assert.equal(readdirSync(join(project, '.claude/agents')).length, 6);
  assert.equal(readdirSync(join(project, '.claude/commands')).length, 7);
  for (const name of ['scripts/guard.sh', 'scripts/approve.sh', 'scripts/preflight.sh']) {
    assert.deepEqual(readFileSync(join(project, name)), readFileSync(join(root, name)), name);
  }
  for (const name of ['.liara', '.env', 'state', 'liara.json', 'node_modules', 'package-lock.json']) {
    assert.equal(existsSync(join(project, name)), false, name);
  }
  if (process.platform !== 'win32') assert.ok(lstatSync(join(project, 'scripts/creds.sh')).mode & 0o111);
});

test('merges existing instructions, permissions and hooks and preserves provider settings', t => {
  const project = fixture(t);
  put(project, 'AGENTS.md', 'Keep our application conventions.');
  put(project, 'CLAUDE.md', 'Keep our Claude instructions.');
  put(project, 'GEMINI.md', 'Keep our Gemini instructions.');
  put(project, '.gitignore', 'custom-build/');
  const settings = {
    model: 'keep-my-model',
    permissions: { allow: ['Bash(npm test)'], deny: ['Read(private/**)'], ask: ['Bash(git push:*)'] },
    hooks: { PreToolUse: [{ matcher: 'Bash', hooks: [{ type: 'command', command: 'echo existing-hook' }] }], Stop: [] },
  };
  put(project, '.claude/settings.json', JSON.stringify(settings));
  put(project, '.codex/config.toml', '# Keep existing Codex settings\n');
  put(project, '.aider.conf.yml', 'read: [project-rules.md]\n');
  const result = run(project);
  assert.equal(result.status, 0, result.stderr);
  const merged = JSON.parse(readFileSync(join(project, '.claude/settings.json'), 'utf8'));
  assert.equal(merged.model, settings.model);
  assert.ok(merged.permissions.allow.includes('Bash(npm test)'));
  assert.ok(merged.permissions.deny.includes('Read(private/**)'));
  assert.ok(merged.permissions.deny.includes('Read(.liara/**)'));
  assert.deepEqual(merged.permissions.ask, settings.permissions.ask);
  assert.deepEqual(merged.hooks.PreToolUse[0], settings.hooks.PreToolUse[0]);
  assert.equal(merged.hooks.PreToolUse.length, 2);
  assert.ok(merged.hooks.PreToolUse[1].hooks[0].command.includes('scripts/guard.sh'));
  assert.deepEqual(merged.hooks.Stop, []);
  for (const name of ['AGENTS.md', 'CLAUDE.md', 'GEMINI.md']) {
    assert.ok(readFileSync(join(project, name), 'utf8').startsWith('Keep our'));
  }
  assert.ok(readFileSync(join(project, '.gitignore'), 'utf8').startsWith('custom-build/\n'));
  assert.equal(readFileSync(join(project, '.codex/config.toml'), 'utf8'), '# Keep existing Codex settings\n');
  assert.equal(readFileSync(join(project, '.aider.conf.yml'), 'utf8'), 'read: [project-rules.md]\n');
  assert.match(result.stdout, /Existing Aider settings kept/);
});

test('rerunning the installer is an exact no-op', t => {
  const project = fixture(t);
  assert.equal(run(project).status, 0);
  const before = snapshot(project);
  const second = run(project);
  assert.equal(second.status, 0, second.stderr);
  assert.match(second.stdout, /0 file\(s\) added or updated/);
  assert.deepEqual(snapshot(project), before);
});

test('dry run previews installation and writes nothing', t => {
  const project = fixture(t);
  put(project, 'README.md', 'Keep me\n');
  const before = snapshot(project);
  const result = run(project, ['--dry-run']);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stdout, /Preview:/);
  assert.deepEqual(snapshot(project), before);
});

test('Windows line endings in managed instructions remain unchanged on repeat installation', t => {
  const project = fixture(t);
  assert.equal(run(project).status, 0);
  for (const name of ['AGENTS.md', 'CLAUDE.md', 'GEMINI.md']) {
    const path = join(project, name);
    writeFileSync(path, readFileSync(path, 'utf8').replace(/\r?\n/g, '\r\n'));
  }
  const before = snapshot(project);
  const result = run(project);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(snapshot(project), before);
});

test('edits to a managed instruction block are preserved and stop the install', t => {
  const project = fixture(t);
  assert.equal(run(project).status, 0);
  const path = join(project, 'AGENTS.md');
  writeFileSync(path, readFileSync(path, 'utf8').replace('### Rule 3', '### Our custom Rule 3'));
  const before = snapshot(project);
  const result = run(project);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /section differs/);
  assert.deepEqual(snapshot(project), before);
});

for (const conflict of ['scripts/guard.sh', 'scripts/setup.sh', '.claude/agents/liara-deploy.md', '.agents/skills/liara-ops/SKILL.md', '.cursor/rules/liara.mdc', 'docs/en/00-installation.md']) {
  test(`conflict at ${conflict} stops before any writes`, t => {
    const project = fixture(t);
    put(project, conflict, 'Existing project content\n');
    const before = snapshot(project);
    const result = run(project);
    assert.equal(result.status, 1);
    assert.match(result.stderr, /no files were changed/);
    assert.ok(result.stderr.includes(conflict));
    assert.deepEqual(snapshot(project), before);
  });
}

for (const json of ['{ invalid JSON', '[]', '{"permissions":[]}', '{"hooks":{"PreToolUse":{}}}', '{"permissions":{"deny":"invalid"}}', '{"disableAllHooks":true}']) {
  test(`invalid or disabled Claude configuration stops before writes: ${json}`, t => {
    const project = fixture(t);
    put(project, '.claude/settings.json', json);
    const before = snapshot(project);
    const result = run(project);
    assert.equal(result.status, 1);
    assert.deepEqual(snapshot(project), before);
    assert.ok(!result.stderr.includes(json));
  });
}

test('does not follow linked destination directories', t => {
  const project = fixture(t);
  const external = fixture(t);
  symlinkSync(external, join(project, 'scripts'), process.platform === 'win32' ? 'junction' : 'dir');
  const result = run(project);
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Refusing linked/);
  assert.deepEqual(readdirSync(external), []);
  assert.deepEqual(readdirSync(project), ['scripts']);
});

test('supports an explicit project path and does not write to the caller folder', t => {
  const caller = fixture(t);
  const project = fixture(t);
  const result = run(caller, ['--project', project]);
  assert.equal(result.status, 0, result.stderr);
  assert.deepEqual(readdirSync(caller), []);
  assert.ok(existsSync(join(project, 'AGENTS.md')));
});

test('help and invalid options do not write files', t => {
  const project = fixture(t);
  assert.equal(run(project, ['--help']).status, 0);
  assert.equal(run(project, ['--project']).status, 1);
  assert.equal(run(project, ['--force']).status, 1);
  assert.deepEqual(readdirSync(project), []);
});
