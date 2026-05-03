const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const electionRoutes = require('./routes/election');
const voterRoutes = require('./routes/voter');
const voteRoutes = require('./routes/vote');
const ledgerRoutes = require('./routes/ledger');
const attackRoutes = require('./routes/attack');
const fabricConnection = require('./fabricConnection');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

app.locals.publicKey = publicKey;
app.locals.privateKey = privateKey;
app.locals.votes = [];
app.locals.registeredVoters = new Map();
app.locals.election = {
  name: 'Blockchain Presidential Election 2026',
  status: 'INITIALIZED',
  candidates: [
    { id: 'CAND-1', name: 'Alice Nakamoto', party: 'Decentralist Party' },
    { id: 'CAND-2', name: 'Bob Buterin', party: 'Smart Contract Alliance' },
    { id: 'CAND-3', name: 'Carol Szabo', party: 'Digital Freedom Front' },
  ],
  registeredVoters: 0,
  totalVotesCast: 0,
  blocks: [],
};

let blockCounter = 0;
function mintBlock(data) {
  blockCounter++;
  const previousHash = app.locals.election.blocks.length > 0
    ? app.locals.election.blocks[app.locals.election.blocks.length - 1].hash
    : '0'.repeat(64);
  const block = {
    index: blockCounter,
    timestamp: new Date().toISOString(),
    data,
    previousHash,
    nonce: Math.floor(Math.random() * 1000000),
  };
  block.hash = crypto.createHash('sha256').update(JSON.stringify(block)).digest('hex');
  app.locals.election.blocks.push(block);
  return block;
}
app.locals.mintBlock = mintBlock;

app.use('/api/election', electionRoutes);
app.use('/api/voter', voterRoutes);
app.use('/api/vote', voteRoutes);
app.use('/api/ledger', ledgerRoutes);
app.use('/api/attack', attackRoutes);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, async () => {
  console.log(`Blockchain Voting API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
  await fabricConnection.connect();
});

module.exports = app;
