const express = require('express');
const router = express.Router();

router.get('/blocks', (req, res) => {
  const blocks = req.app.locals.election.blocks;
  res.json({ blocks, totalBlocks: blocks.length });
});

router.get('/blocks/:index', (req, res) => {
  const index = parseInt(req.params.index);
  const blocks = req.app.locals.election.blocks;
  if (index < 0 || index >= blocks.length) {
    return res.status(404).json({ error: 'Block not found' });
  }
  res.json(blocks[index]);
});

router.get('/verify', (req, res) => {
  const crypto = require('crypto');
  const blocks = req.app.locals.election.blocks;
  const issues = [];

  for (let i = 1; i < blocks.length; i++) {
    if (blocks[i].previousHash !== blocks[i - 1].hash) {
      issues.push({ block: i, issue: 'Previous hash mismatch' });
    }
    const { hash, ...blockData } = blocks[i];
    const computedHash = crypto.createHash('sha256').update(JSON.stringify(blockData)).digest('hex');
    if (hash !== computedHash) {
      issues.push({ block: i, issue: 'Block hash mismatch (possible tampering)' });
    }
  }

  res.json({
    valid: issues.length === 0,
    totalBlocks: blocks.length,
    issues,
    message: issues.length === 0 ? 'Blockchain integrity verified' : `Found ${issues.length} integrity issue(s)`,
  });
});

module.exports = router;
