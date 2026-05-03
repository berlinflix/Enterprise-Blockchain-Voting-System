# Blockchain Voting System - Fabric Network Setup Script
# Uses containerized fabric-tools to avoid Windows/Linux pathing issues

$ErrorActionPreference = "Stop"

$CONFIG_DIR = Join-Path $PSScriptRoot "..\config"
$NETWORK_DIR = Join-Path $PSScriptRoot ".."
$FABRIC_VERSION = "2.5"
$FABRIC_TOOLS_IMAGE = "hyperledger/fabric-tools:$FABRIC_VERSION"

Write-Host "=== Blockchain Voting System - Network Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Generate Crypto Material
Write-Host "[1/4] Generating crypto material..." -ForegroundColor Yellow

docker run --rm `
  -v "${CONFIG_DIR}:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto" `
  -w "/opt/gopath/src/github.com/hyperledger/fabric/peer" `
  $FABRIC_TOOLS_IMAGE `
  cryptogen generate --config=./crypto/crypto-config.yaml --output=./crypto/crypto-config

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to generate crypto material!" -ForegroundColor Red
    exit 1
}
Write-Host "  Crypto material generated successfully." -ForegroundColor Green

# Step 2: Generate Genesis Block
Write-Host "[2/4] Generating genesis block..." -ForegroundColor Yellow

docker run --rm `
  -v "${CONFIG_DIR}:/opt/gopath/src/github.com/hyperledger/fabric/peer/config" `
  -w "/opt/gopath/src/github.com/hyperledger/fabric/peer" `
  -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/config `
  $FABRIC_TOOLS_IMAGE `
  configtxgen -profile VoteOrdererGenesis -outputBlock ./config/genesis.block -channelID system-channel

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to generate genesis block!" -ForegroundColor Red
    exit 1
}
Write-Host "  Genesis block generated successfully." -ForegroundColor Green

# Step 3: Generate Channel Transaction
Write-Host "[3/4] Generating channel transaction..." -ForegroundColor Yellow

docker run --rm `
  -v "${CONFIG_DIR}:/opt/gopath/src/github.com/hyperledger/fabric/peer/config" `
  -w "/opt/gopath/src/github.com/hyperledger/fabric/peer" `
  -e FABRIC_CFG_PATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/config `
  $FABRIC_TOOLS_IMAGE `
  configtxgen -profile VoteChannel -outputCreateChannelTx ./config/votechannel.tx -channelID votechannel

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to generate channel transaction!" -ForegroundColor Red
    exit 1
}
Write-Host "  Channel transaction generated successfully." -ForegroundColor Green

# Step 4: Start Docker Compose
Write-Host "[4/4] Starting Docker containers..." -ForegroundColor Yellow

docker-compose -f (Join-Path $NETWORK_DIR "docker-compose.yaml") up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Docker containers!" -ForegroundColor Red
    exit 1
}
Write-Host "  Docker containers started successfully." -ForegroundColor Green

Write-Host ""
Write-Host "=== Network Setup Complete ===" -ForegroundColor Cyan
Write-Host "Orderer:  localhost:7050" -ForegroundColor White
Write-Host "EC Peer:  localhost:7051" -ForegroundColor White
Write-Host "Auditor:  localhost:9051" -ForegroundColor White
Write-Host "CouchDB:  localhost:5984 / localhost:6984" -ForegroundColor White
