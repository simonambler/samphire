#!/usr/bin/env node

const crypto = require('crypto');

function createUserXmlFragment(username, password, permission = 'admin') {
  // Generate digest hash (MD5)
  const digestHash = crypto.createHash('md5').update(password).digest('hex');
  
  // Generate salted-sha256 hash
  const salt = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER).toString();
  const saltedHash = crypto
    .createHash('sha256')
    .update(salt + password)
    .digest('hex');
  
  const xmlFragment = `    <user name="${username}" permission="${permission}">
        <password algorithm="digest">
        <hash>${digestHash}</hash>
        </password>
        <password algorithm="salted-sha256">
        <salt>${salt}</salt>
        <hash>${saltedHash}</hash>
        </password>
    </user>`;
  
  return xmlFragment;
}

// Get arguments from command line
const username = process.argv[2];
const password = process.argv[3];
const permission = process.argv[4] || 'admin';

if (!username || !password) {
  console.error('Usage: node create-user.js <username> <password> [permission]');
  process.exit(1);
}

console.log(`<users>\n${createUserXmlFragment(username, password, permission)}\n</users>`);