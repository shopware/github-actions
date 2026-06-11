#!/usr/bin/env node
'use strict';

const fs = require('fs');
const { ACTION_RE, findYamlFiles, isThirdParty } = require('../lib/action-utils');

const SHA_RE = /^[0-9a-f]{40}$/;

function main() {
    const yamlFiles = findYamlFiles();
    const violations = [];

    for (const file of yamlFiles) {
        const content = fs.readFileSync(file, 'utf8');
        const lines = content.split('\n');

        for (let i = 0; i < lines.length; i++) {
            for (const [, action, ref] of lines[i].matchAll(ACTION_RE)) {
                if (!isThirdParty(action)) continue;

                if (!SHA_RE.test(ref)) {
                    violations.push({ file, line: i + 1, action, ref });
                }
            }
        }
    }

    if (violations.length === 0) {
        console.log('All third-party actions are pinned to a commit SHA.');
        return;
    }

    console.error(`\nFound ${violations.length} unpinned action(s):\n`);
    for (const { file, line, action, ref } of violations) {
        console.error(`  ${file}:${line}  ${action}@${ref}`);
    }
    console.error('\nPin each action to a full commit SHA, e.g.:');
    console.error('  uses: actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3\n');
    process.exit(1);
}

main();
