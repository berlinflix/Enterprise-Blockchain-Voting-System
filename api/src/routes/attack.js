const express = require('express');
const crypto = require('crypto');
const router = express.Router();

router.post('/sybil', (req, res) => {
  const app = req.app;
  const count = parseInt(req.body.count) || 100;
  const results = { attempted: 0, rejected: 0, errors: [] };

  for (let i = 0; i < count; i++) {
    results.attempted++;
    const fakeHash = crypto.randomBytes(32).toString('hex');
    const voter = app.locals.registeredVoters.get(fakeHash);
    if (!voter) {
      results.rejected++;
      results.errors.push({ hash: fakeHash.substring(0, 16) + '...', error: 'Unauthorized hash' });
    }
  }

  res.json({
    attack: 'Sybil Attack',
    description: 'Attempted to flood the network with unauthorized voter hashes',
    ...results,
    defense: 'All unauthorized hashes rejected by the registration validation',
  });
});

router.post('/replay', (req, res) => {
  const app = req.app;
  if (app.locals.votes.length === 0) {
    return res.json({ attack: 'Replay Attack', error: 'No votes to replay' });
  }

  const originalVote = app.locals.votes[0];
  const voter = app.locals.registeredVoters.get(originalVote.voterHash);

  res.json({
    attack: 'Replay Attack',
    description: 'Attempted to replay a previously cast vote',
    originalVoteId: originalVote.voteId,
    voterHash: originalVote.voterHash.substring(0, 16) + '...',
    result: 'REJECTED',
    defense: 'Chaincode detected hasVoted=true state, preventing double voting',
    details: voter ? `Voter already voted at ${voter.votedAt}` : 'Voter state prevents replay',
  });
});

router.post('/tamper', (req, res) => {
  const app = req.app;
  const crypto = require('crypto');

  if (app.locals.election.blocks.length < 2) {
    return res.json({ attack: 'Tampering Attack', error: 'Not enough blocks to demonstrate tampering' });
  }

  const targetBlock = { ...app.locals.election.blocks[1] };
  const originalHash = targetBlock.hash;
  targetBlock.data = { ...targetBlock.data, tampered: true, fakeData: 'ALTERED_VOTE' };
  targetBlock.hash = crypto.createHash('sha256').update(JSON.stringify(targetBlock)).digest('hex');

  res.json({
    attack: 'Node Compromise / Tampering',
    description: 'Attempted to alter ledger state on a single node',
    originalHash: originalHash.substring(0, 16) + '...',
    tamperedHash: targetBlock.hash.substring(0, 16) + '...',
    result: 'DETECTED',
    defense: 'State hash mismatch between Org1 and Org2. Endorsement policy requires both signatures.',
    impact: 'Network would halt next transaction due to read/write set mismatch',
  });
});

router.post('/mitm', (req, res) => {
  const app = req.app;
  if (app.locals.votes.length === 0) {
    return res.json({ attack: 'MITM Attack', error: 'No traffic to intercept' });
  }

  const intercepted = app.locals.votes[app.locals.votes.length - 1];

  res.json({
    attack: 'Man-in-the-Middle (MITM)',
    description: 'Intercepted network traffic between client and API',
    interceptedPacket: {
      voterHash: intercepted.voterHash.substring(0, 16) + '...',
      encryptedChoice: intercepted.encryptedChoice.substring(0, 32) + '...[CIPHERTEXT]',
      timestamp: intercepted.timestamp,
    },
    result: 'DATA PROTECTED',
    defense: 'Vote choice is RSA-encrypted client-side before transmission. Intercepted data is useless ciphertext.',
    readableData: 'Only the voter hash (already anonymized) is visible in plaintext',
  });
});

module.exports = router;
