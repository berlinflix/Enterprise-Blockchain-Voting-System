const grpc = require('@grpc/grpc-js');
const { connect, signers } = require('@hyperledger/fabric-gateway');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const mspId = 'ElectionCommissionMSP';
const cryptoPath = path.resolve(__dirname, '..', '..', 'fabric-network', 'config', 'crypto-config', 'peerOrganizations', 'electioncommission.example.com');
const keyPath = path.join(cryptoPath, 'users', 'User1@electioncommission.example.com', 'msp', 'keystore');
const certPath = path.join(cryptoPath, 'users', 'User1@electioncommission.example.com', 'msp', 'signcerts');
const tlsCertPath = path.join(cryptoPath, 'peers', 'peer0.electioncommission.example.com', 'tls', 'ca.crt');
const peerEndpoint = 'localhost:7051';
const peerHostAlias = 'peer0.electioncommission.example.com';
const channelName = 'votechannel';
const chaincodeName = 'votecontract';

async function newGrpcConnection() {
    const tlsRootCert = await fs.promises.readFile(tlsCertPath);
    const tlsCredentials = grpc.credentials.createSsl(tlsRootCert);
    return new grpc.Client(peerEndpoint, tlsCredentials, {
        'grpc.ssl_target_name_override': peerHostAlias,
    });
}

async function newIdentity() {
    const certFiles = await fs.promises.readdir(certPath);
    const certFile = certFiles.find(f => f.endsWith('.pem'));
    const credentials = await fs.promises.readFile(path.join(certPath, certFile));
    return { mspId, credentials };
}

async function newSigner() {
    const keyFiles = await fs.promises.readdir(keyPath);
    const keyFile = keyFiles.find(f => f.endsWith('_sk'));
    const privateKeyPem = await fs.promises.readFile(path.join(keyPath, keyFile));
    const privateKey = crypto.createPrivateKey(privateKeyPem);
    return signers.newPrivateKeySigner(privateKey);
}

class FabricConnection {
    constructor() {
        this.client = null;
        this.gateway = null;
        this.network = null;
        this.contract = null;
        this.isConnected = false;
        this.useMock = false;
    }

    async connect() {
        try {
            // Check if crypto material exists
            if (!fs.existsSync(cryptoPath)) {
                console.warn('⚠️ Crypto material not found. Using MOCK Fabric mode. Please run setup.ps1 first.');
                this.useMock = true;
                return;
            }

            this.client = await newGrpcConnection();
            this.gateway = connect({
                client: this.client,
                identity: await newIdentity(),
                signer: await newSigner(),
                evaluateOptions: () => { return { deadline: Date.now() + 5000 }; },
                endorseOptions: () => { return { deadline: Date.now() + 15000 }; },
                submitOptions: () => { return { deadline: Date.now() + 5000 }; },
                commitStatusOptions: () => { return { deadline: Date.now() + 60000 }; },
            });

            this.network = this.gateway.getNetwork(channelName);
            this.contract = this.network.getContract(chaincodeName);
            this.isConnected = true;
            console.log('✅ Connected to Hyperledger Fabric Gateway');
        } catch (error) {
            console.error('❌ Error connecting to Fabric:', error.message);
            console.warn('⚠️ Falling back to MOCK Fabric mode.');
            this.useMock = true;
        }
    }

    async submitTransaction(name, ...args) {
        if (this.useMock) {
            console.log(`[MOCK] submitTransaction: ${name}(${args.join(', ')})`);
            return this._handleMockTransaction(name, args);
        }
        
        try {
            const resultBytes = await this.contract.submitTransaction(name, ...args);
            return Buffer.from(resultBytes).toString('utf8');
        } catch (error) {
            console.error(`Submit transaction ${name} failed:`, error);
            throw error;
        }
    }

    async evaluateTransaction(name, ...args) {
        if (this.useMock) {
            console.log(`[MOCK] evaluateTransaction: ${name}(${args.join(', ')})`);
            return this._handleMockQuery(name, args);
        }

        try {
            const resultBytes = await this.contract.evaluateTransaction(name, ...args);
            return Buffer.from(resultBytes).toString('utf8');
        } catch (error) {
            console.error(`Evaluate transaction ${name} failed:`, error);
            throw error;
        }
    }

    // --- MOCK LOGIC TO KEEP UI FUNCTIONAL WITHOUT DOCKER ---
    _mockState = {
        election: { status: 'ACTIVE', registeredVoters: 0, totalVotesCast: 0, candidates: [{ id: 'CAND-1', name: 'Alice Nakamoto', party: 'Decentralist Party', votes: 0 }, { id: 'CAND-2', name: 'Bob Buterin', party: 'Smart Contract Alliance', votes: 0 }] },
        tally: { 'CAND-1': 0, 'CAND-2': 0 },
        voters: {},
        blocks: [],
        txCount: 0
    };

    _handleMockTransaction(name, args) {
        this._mockState.txCount++;
        const txId = crypto.randomBytes(32).toString('hex');
        
        if (name === 'RegisterVoter') {
            const hash = args[0];
            if (this._mockState.voters[hash]) throw new Error('Voter already registered');
            this._mockState.voters[hash] = { hash, hasVoted: false };
            this._mockState.election.registeredVoters++;
            this._mockBlock('voter_registration', { hash });
            return JSON.stringify({ hash });
        }
        if (name === 'CastVote') {
            const hash = args[0];
            const choice = args[1];
            if (!this._mockState.voters[hash]) throw new Error('Unauthorized hash');
            if (this._mockState.voters[hash].hasVoted) throw new Error('Double voting detected');
            this._mockState.voters[hash].hasVoted = true;
            this._mockState.election.totalVotesCast++;
            // MOCK decryption for tally
            if (choice.includes('CAND-1')) this._mockState.tally['CAND-1']++;
            else if (choice.includes('CAND-2')) this._mockState.tally['CAND-2']++;
            this._mockBlock('vote_cast', { hash, txId });
            return JSON.stringify({ success: true, txId });
        }
        if (name === 'SimulateTampering') {
            return JSON.stringify({ success: true, message: 'Tampering simulated. Mismatch detected.' });
        }
        return JSON.stringify({ success: true, txId });
    }

    _handleMockQuery(name, args) {
        if (name === 'GetElection') return JSON.stringify(this._mockState.election);
        if (name === 'GetElectionTally') return JSON.stringify(this._mockState.tally);
        return JSON.stringify({});
    }

    _mockBlock(type, data) {
        const index = this._mockState.blocks.length + 1;
        this._mockState.blocks.push({
            index,
            timestamp: new Date().toISOString(),
            hash: crypto.randomBytes(32).toString('hex'),
            previousHash: index > 1 ? this._mockState.blocks[index - 2].hash : '0'.repeat(64),
            data: { type, ...data }
        });
    }

    getMockBlocks() {
        return this._mockState.blocks;
    }

    disconnect() {
        if (this.gateway) this.gateway.close();
        if (this.client) this.client.close();
        console.log('Gateway disconnected.');
    }
}

module.exports = new FabricConnection();
