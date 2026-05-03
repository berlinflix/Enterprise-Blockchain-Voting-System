const express = require('express');
const router = express.Router();

router.post('/setup', (req, res) => {
  const app = req.app;
  app.locals.election.status = 'ACTIVE';
  app.locals.election.totalVotesCast = 0;
  app.locals.election.registeredVoters = 0;
  app.locals.votes = [];
  app.locals.registeredVoters.clear();
  app.locals.election.blocks = [];

  const genesisBlock = app.locals.mintBlock({
    type: 'GENESIS',
    election: app.locals.election.name,
  });

  res.json({
    success: true,
    message: 'Election initialized successfully',
    election: app.locals.election,
    genesisBlock,
  });
});

router.get('/public-key', (req, res) => {
  res.json({ publicKey: req.app.locals.publicKey });
});

router.get('/status', (req, res) => {
  const { name, status, candidates, registeredVoters, totalVotesCast, blocks } = req.app.locals.election;
  res.json({ name, status, candidates, registeredVoters, totalVotesCast, blockCount: blocks.length });
});

module.exports = router;
