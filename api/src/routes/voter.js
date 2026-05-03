const express = require('express');
const crypto = require('crypto');
const router = express.Router();

router.post('/register', (req, res) => {
  const { voterName } = req.body;
  if (!voterName) {
    return res.status(400).json({ error: 'voterName is required' });
  }

  const voterHash = crypto.createHash('sha256').update(voterName.trim().toLowerCase()).digest('hex');
  const app = req.app;

  if (app.locals.registeredVoters.has(voterHash)) {
    return res.status(409).json({ error: 'Voter hash already registered', voterHash });
  }

  const voter = {
    voterHash,
    voterName: voterName.trim(),
    registeredAt: new Date().toISOString(),
    hasVoted: false,
  };
  app.locals.registeredVoters.set(voterHash, voter);
  app.locals.election.registeredVoters += 1;

  app.locals.mintBlock({
    type: 'VOTER_REGISTRATION',
    voterHash,
    timestamp: voter.registeredAt,
  });

  res.json({
    success: true,
    voterHash,
    message: `Voter registered. Hash: ${voterHash.substring(0, 16)}...`,
  });
});

router.get('/check/:hash', (req, res) => {
  const { hash } = req.params;
  const voter = req.app.locals.registeredVoters.get(hash);
  if (!voter) {
    return res.status(404).json({ registered: false });
  }
  res.json({ registered: true, hasVoted: voter.hasVoted });
});

module.exports = router;
