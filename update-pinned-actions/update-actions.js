#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');
const { ACTION_RE, findYamlFiles, isThirdParty } = require('../lib/action-utils');

function ghApi(endpoint) {
    try {
        const output = execSync(`gh api "${endpoint}"`, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
        return JSON.parse(output);
    } catch {
        return null;
    }
}

function latestRelease(owner, repo) {
    const data = ghApi(`repos/${owner}/${repo}/releases/latest`);
    if (!data) return null;
    return { tag: data.tag_name, body: data.body ?? '', url: data.html_url };
}

function tagCommitSha(owner, repo, tag) {
    const data = ghApi(`repos/${owner}/${repo}/git/ref/tags/${tag}`);
    if (!data) return null;

    const { type, sha } = data.object;
    if (type === 'tag') {
        // Annotated tag — dereference to the underlying commit
        const tagData = ghApi(`repos/${owner}/${repo}/git/tags/${sha}`);
        return tagData?.object?.sha ?? null;
    }
    return sha;
}

function collectActions(yamlFiles) {
    const actions = {};
    for (const file of yamlFiles) {
        const content = fs.readFileSync(file, 'utf8');
        for (const [, action, ref, commentTag] of content.matchAll(ACTION_RE)) {
            if (!isThirdParty(action)) continue;
            if (!actions[action]) {
                actions[action] = { ref, currentTag: commentTag ?? null };
            }
        }
    }
    return actions;
}

function applyUpdates(yamlFiles, updates) {
    for (const file of yamlFiles) {
        let content = fs.readFileSync(file, 'utf8');
        let modified = false;
        for (const [action, { sha, tag }] of Object.entries(updates)) {
            const escaped = action.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            const re = new RegExp(
                `(uses:\\s+${escaped}@)[a-zA-Z0-9._/-]+( *#[^\\n]*)?`,
                'g',
            );
            const updated = content.replace(re, `$1${sha} # ${tag}`);
            if (updated !== content) {
                content = updated;
                modified = true;
            }
        }
        if (modified) {
            fs.writeFileSync(file, content);
        }
    }
}

function majorVersion(tag) {
    const m = tag?.match(/^v?(\d+)/);
    return m ? parseInt(m[1], 10) : null;
}

function detectBreaking(currentTag, newTag, releaseBody) {
    const reasons = [];
    const oldMajor = majorVersion(currentTag);
    const newMajor = majorVersion(newTag);
    if (oldMajor !== null && newMajor !== null && newMajor > oldMajor) {
        reasons.push(`major version bump (${currentTag ?? '?'} → ${newTag})`);
    }
    if (/breaking.change|BREAKING.CHANGE|\bbreaking:/i.test(releaseBody)) {
        reasons.push('breaking changes mentioned in release notes');
    }
    return reasons;
}

function truncate(text, max = 400) {
    const trimmed = text.trim();
    return trimmed.length <= max ? trimmed : trimmed.slice(0, max).trimEnd() + '…';
}

function writeOutput(key, value) {
    const outputFile = process.env.GITHUB_OUTPUT;
    if (outputFile) {
        fs.appendFileSync(outputFile, `${key}=${value}\n`);
    }
}

function main() {
    const yamlFiles = findYamlFiles();
    const actions = collectActions(yamlFiles);

    const updates = {};
    const rows = [];
    const breakingNotes = [];

    for (const action of Object.keys(actions).sort()) {
        const { ref: currentRef, currentTag } = actions[action];
        const [owner, repo] = action.split('/', 2);

        process.stdout.write(`Checking ${action} ...\n`);

        const release = latestRelease(owner, repo);
        if (!release) {
            console.log('  No releases found, skipping');
            continue;
        }

        const sha = tagCommitSha(owner, repo, release.tag);
        if (!sha) {
            console.log(`  Could not resolve commit SHA for ${release.tag}, skipping`);
            continue;
        }

        if (currentRef === sha) {
            console.log(`  Up to date (${release.tag})`);
            continue;
        }

        const breaking = detectBreaking(currentTag, release.tag, release.body);
        const flag = breaking.length > 0 ? ' ⚠️' : '';
        console.log(`  ${currentRef} -> ${sha} (${release.tag})${flag}`);

        updates[action] = { sha, tag: release.tag };
        rows.push(
            `| \`${action}\` | \`${currentRef.slice(0, 12)}\`${currentTag ? ` (${currentTag})` : ''} | \`${sha.slice(0, 12)}\` (${release.tag})${flag} |`,
        );

        if (breaking.length > 0) {
            breakingNotes.push({ action, tag: release.tag, url: release.url, body: release.body, reasons: breaking });
        }
    }

    if (Object.keys(updates).length === 0) {
        console.log('All actions are up to date.');
        writeOutput('changed', 'false');
        return;
    }

    applyUpdates(yamlFiles, updates);
    writeOutput('changed', 'true');

    const sections = [
        'Automated update of pinned GitHub Action versions to their latest releases.\n',
        '| Action | From | To |',
        '|--------|------|----|',
        ...rows,
    ];

    if (breakingNotes.length > 0) {
        sections.push('\n---\n\n## ⚠️ Potential breaking changes\n');
        for (const { action, tag, url, body, reasons } of breakingNotes) {
            sections.push(`### \`${action}\` — [${tag}](${url})`);
            sections.push(reasons.map(r => `- ${r}`).join('\n'));
            if (body.trim()) {
                sections.push('\n**Release notes:**\n```\n' + truncate(body) + '\n```');
            }
            sections.push('');
        }
    }

    const prBodyPath = path.join(process.env.RUNNER_TEMP ?? os.tmpdir(), 'pr_body.md');
    fs.writeFileSync(prBodyPath, sections.join('\n'));
    writeOutput('pr_body_path', prBodyPath);

    console.log(`\nUpdated ${Object.keys(updates).length} action(s), ${breakingNotes.length} with potential breaking changes.`);
}

main();
