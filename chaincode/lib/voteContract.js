const { Contract } = require('fabric-contract-api');
const crypto = require('crypto');

class VoteContract extends Contract {
  constructor() {
    super('VoteContract');
  }

  async InitLedger(ctx) {
    const election = {
      docType: 'election',
      name: 'Blockchain Presidential Election 2026',
      status: 'INITIALIZED',
      candidates: [
        { id: 'CAND-1', name: 'Alice Nakamoto', party: 'Decentralist Party' },
        { id: 'CAND-2', name: 'Bob Buterin', party: 'Smart Contract Alliance' },
        { id: 'CAND-3', name: 'Carol Szabo', party: 'Digital Freedom Front' },
      ],
      registeredVoters: 0,
      totalVotesCast: 0,
      createdAt: new Date().toISOString(),
    };
    await ctx.stub.putState('ELECTION', Buffer.from(JSON.stringify(election)));

    const tally = {
      docType: 'tally',
      'CAND-1': 0,
      'CAND-2': 0,
      'CAND-3': 0,
    };
    await ctx.stub.putState('TALLY', Buffer.from(JSON.stringify(tally)));

    return JSON.stringify(election);
  }

  async GetElection(ctx) {
    const data = await ctx.stub.getState('ELECTION');
    if (!data || data.length === 0) {
      throw new Error('Election not initialized');
    }
    return data.toString();
  }

  async RegisterVoter(ctx, voterHash) {
    if (!voterHash || voterHash.length !== 64) {
      throw new Error('Invalid voter hash. Must be a 64-character SHA-256 hex string.');
    }

    const voterKey = `VOTER_${voterHash}`;
    const existing = await ctx.stub.getState(voterKey);
    if (existing && existing.length > 0) {
      throw new Error('Voter hash already registered.');
    }

    const voter = {
      docType: 'voter',
      voterHash,
      registeredAt: new Date().toISOString(),
      hasVoted: false,
    };
    await ctx.stub.putState(voterKey, Buffer.from(JSON.stringify(voter)));

    const election = JSON.parse(await this.GetElection(ctx));
    election.registeredVoters += 1;
    await ctx.stub.putState('ELECTION', Buffer.from(JSON.stringify(election)));

    return JSON.stringify(voter);
  }

  async CastVote(ctx, voterHash, encryptedChoice) {
    if (!voterHash || voterHash.length !== 64) {
      throw new Error('Invalid voter hash.');
    }
    if (!encryptedChoice) {
      throw new Error('Encrypted choice is required.');
    }

    const voterKey = `VOTER_${voterHash}`;
    const voterData = await ctx.stub.getState(voterKey);
    if (!voterData || voterData.length === 0) {
      throw new Error('Unauthorized: Voter hash not registered.');
    }

    const voter = JSON.parse(voterData.toString());
    if (voter.hasVoted) {
      throw new Error('Double voting detected: This voter has already cast a vote.');
    }

    const voteId = `VOTE_${voterHash}`;
    const vote = {
      docType: 'vote',
      voteId,
      voterHash,
      encryptedChoice,
      timestamp: new Date().toISOString(),
      blockNumber: ctx.stub.getTxID(),
    };
    await ctx.stub.putState(voteId, Buffer.from(JSON.stringify(vote)));

    voter.hasVoted = true;
    voter.votedAt = new Date().toISOString();
    await ctx.stub.putState(voterKey, Buffer.from(JSON.stringify(voter)));

    const election = JSON.parse(await this.GetElection(ctx));
    election.totalVotesCast += 1;
    await ctx.stub.putState('ELECTION', Buffer.from(JSON.stringify(election)));

    await ctx.stub.setEvent('VoteCast', Buffer.from(JSON.stringify({ voterHash, txId: ctx.stub.getTxID() })));

    return JSON.stringify({ success: true, txId: ctx.stub.getTxID() });
  }

  async QueryVote(ctx, voterHash) {
    const voteId = `VOTE_${voterHash}`;
    const data = await ctx.stub.getState(voteId);
    if (!data || data.length === 0) {
      return JSON.stringify({ found: false });
    }
    return data.toString();
  }

  async GetElectionTally(ctx) {
    const tallyData = await ctx.stub.getState('TALLY');
    if (!tallyData || tallyData.length === 0) {
      throw new Error('Tally not found.');
    }
    return tallyData.toString();
  }

  async UpdateTally(ctx, candidateId) {
    const tallyData = await ctx.stub.getState('TALLY');
    if (!tallyData || tallyData.length === 0) {
      throw new Error('Tally not found.');
    }
    const tally = JSON.parse(tallyData.toString());
    if (!(candidateId in tally)) {
      throw new Error(`Invalid candidate ID: ${candidateId}`);
    }
    tally[candidateId] += 1;
    await ctx.stub.putState('TALLY', Buffer.from(JSON.stringify(tally)));
    return JSON.stringify(tally);
  }

  async GetAllVotes(ctx) {
    const iterator = await ctx.stub.getStateByRange('', '');
    const results = [];
    let result = await iterator.next();
    while (!result.done) {
      const strValue = result.value.value.toString('utf8');
      try {
        const record = JSON.parse(strValue);
        if (record.docType === 'vote') {
          results.push(record);
        }
      } catch (err) {
        // skip non-JSON
      }
      result = await iterator.next();
    }
    await iterator.close();
    return JSON.stringify(results);
  }

  async GetBlockHistory(ctx, voteId) {
    const iterator = await ctx.stub.getHistoryForKey(voteId);
    const history = [];
    let result = await iterator.next();
    while (!result.done) {
      const record = {
        txId: result.value.txId,
        timestamp: result.value.timestamp,
        isDelete: result.value.isDelete,
      };
      if (!result.value.isDelete) {
        record.value = JSON.parse(result.value.value.toString('utf8'));
      }
      history.push(record);
      result = await iterator.next();
    }
    await iterator.close();
    return JSON.stringify(history);
  }

  async SimulateTampering(ctx, voterHash, fakeChoice) {
    const voteId = `VOTE_${voterHash}`;
    const data = await ctx.stub.getState(voteId);
    if (!data || data.length === 0) {
      throw new Error('Vote not found for tampering simulation.');
    }
    const tamperedVote = JSON.parse(data.toString());
    tamperedVote.encryptedChoice = fakeChoice;
    tamperedVote.tampered = true;
    tamperedVote.tamperedAt = new Date().toISOString();
    await ctx.stub.putState(voteId, Buffer.from(JSON.stringify(tamperedVote)));
    return JSON.stringify({ success: true, message: 'Tampering simulated. State hash mismatch will be detected.' });
  }
}

module.exports = VoteContract;
