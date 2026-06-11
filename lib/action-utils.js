'use strict';

const fs = require('fs');
const path = require('path');

// Matches: uses: owner/repo@ref  (with optional trailing # tag comment)
const ACTION_RE = /uses:\s+([a-zA-Z0-9_.-]+\/[a-zA-Z0-9_.-]+)@([a-zA-Z0-9._/-]+)(?:\s*#\s*(\S+))?/g;

function findYamlFiles(root = '.') {
    const files = [];
    function walk(dir) {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
            if (entry.name === '.git') continue;
            const full = path.join(dir, entry.name);
            if (entry.isDirectory()) {
                walk(full);
            } else if (entry.name.endsWith('.yml') || entry.name.endsWith('.yaml')) {
                files.push(full);
            }
        }
    }
    walk(root);
    return files.sort();
}

function isThirdParty(action) {
    const owner = action.split('/')[0];
    return owner !== 'shopware' && !owner.startsWith('.');
}

module.exports = { ACTION_RE, findYamlFiles, isThirdParty };
