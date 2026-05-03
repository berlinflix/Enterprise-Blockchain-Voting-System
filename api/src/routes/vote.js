const express = require('express');
const crypto = require('crypto');
const router = express.Router();

router.post('/cast', (req, res) => {
  const { voterHash, candidateId } = req.body;
  const app = req.app;

  if (!voterHash || !candidateId) {
    return res.status(400).json({ error: 'voterHash and candidateId are required' });
  }

  const voter = app.locals.registeredVoters.get(voterHash);
  if (!voter) {
    return res.status(401).json({ error: 'Unauthorized: Voter hash not registered' });
  }

  if (voter.hasVoted) {
    return res.status(409).json({ error: 'Double voting detected: Vote already cast' });
  }

  const candidate = app.locals.election.candidates.find(c => c.id === candidateId);
  if (!candidate) {
    return res.status(400).json({ error: 'Invalid candidate ID' });
  }

  const encryptedChoice = crypto.publicEncrypt(
    app.locals.publicKey,
    Buffer.from(JSON.stringify({ candidateId, candidateName: candidate.name }))
  ).toString('base64');

  voter.hasVoted = true;
  voter.votedAt = new Date().toISOString();
  app.locals.election.totalVotesCast += 1;

  const vote = {
    voteId: `VOTE_${voterHash.substring(0, 16)}_${Date.now()}`,
    voterHash,
    encryptedChoice,
    timestamp: new Date().toISOString(),
  };
  app.locals.votes.push(vote);

  const block = app.locals.mintBlock({
    type: 'VOTE_CAST',
    voteId: vote.voteId,
    voterHash,
    encryptedChoiceHash: crypto.createHash('sha256').update(encryptedChoice).digest('hex'),
  });

  res.json({
    success: true,
    txId: vote.voteId,
    blockIndex: block.index,
    blockHash: block.hash,
    message: 'Vote cast successfully and immutably recorded',
  });
});

router.get('/tally', (req, res) => {
  const app = req.app;
  try {
    const tally = {};
    app.locals.election.candidates.forEach(c => { tally[c.id] = 0; });

    app.locals.votes.forEach(vote => {
      try {
        const decrypted = crypto.privateDecrypt(
          app.locals.privateKey,
          Buffer.from(vote.encryptedChoice, 'base64')
        );
        const choice = JSON.parse(decrypted.toString());
        if (tally[choice.candidateId] !== undefined) {
          tally[choice.candidateId]++;
        }
      } catch (err) {
        // skip invalid votes
      }
    });

    const results = app.locals.election.candidates.map(c => ({
      ...c,
      votes: tally[c.id] || 0,
    }));

    res.json({ success: true, results, totalVotes: app.locals.election.totalVotesCast });
  } catch (err) {
    res.status(500).json({ error: 'Tally failed', details: err.message });
  }
});

router.get('/all', (req, res) => {
  const votes = req.app.locals.votes.map(v => ({
    voteId: v.voteId,
    voterHash: v.voterHash.substring(0, 16) + '...',
    timestamp: v.timestamp,
  }));
  res.json({ votes });
});

module.exports = router;
