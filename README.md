# Metabridge Engine - Production-Grade Multi-Chain Bridge Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Go Version](https://img.shields.io/badge/Go-1.21+-blue.svg)](https://golang.org)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-orange.svg)](https://soliditylang.org)

**Metabridge** is a production-ready, enterprise-grade cross-chain messaging and asset bridge protocol written in Golang that supports **heterogeneous blockchain architectures** across both **testnet and mainnet** environments.

## 🌟 Key Features

### Multi-Chain Support
- **6 Blockchain Networks** with full testnet and mainnet configurations
- **EVM Chains**: Polygon, BNB Smart Chain, Avalanche, Ethereum
- **Non-EVM Chains**: Solana, NEAR Protocol

### Cross-Platform Capabilities
- ✅ Different signature schemes (ECDSA for EVM, Ed25519 for Solana/NEAR)
- ✅ Varied finality models (probabilistic vs deterministic)
- ✅ Transaction model abstraction (account-based and UTXO-like)
- ✅ Cross-platform token standards (ERC-20/721, SPL, NEP-141/171)
- ✅ Environment-aware security (2-of-3 testnet, 3-of-5 mainnet)

### Production Features
- 🔐 Multi-signature validation
- 🚨 Emergency pause mechanism
- 📊 Comprehensive monitoring and metrics
- 🔄 Automatic failover and retry logic
- ⚡ High-availability architecture
- 🛡️ Rate limiting and fraud detection
- 📈 Real-time statistics and analytics

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [Self-Hosted Relayer System](#self-hosted-relayer-system)
- [Supported Networks](#supported-networks)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Testnet Deployment](#testnet-deployment)
- [Mainnet Deployment](#mainnet-deployment)
- [Configuration](#configuration)
- [API Documentation](#api-documentation)
- [Monitoring](#monitoring)
- [Security](#security)
- [Testing](#testing)

---

## 🏗️ Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Polygon   │         │   Solana    │         │    NEAR     │
│  (EVM)      │         │ (Non-EVM)   │         │  (Non-EVM)  │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                        │
       │                       │                        │
       └───────────────────────┼────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Event Listeners   │
                    │  (Multi-Chain)      │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Message Queue     │
                    │   (NATS JetStream)  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   Relayer Service   │
                    │  (Multi-Sig)        │
                    └──────────┬──────────┘
                               │
       ┌───────────────────────┼────────────────────────┐
       │                       │                        │
┌──────▼──────┐         ┌──────▼──────┐         ┌──────▼──────┐
│    BNB      │         │  Avalanche  │         │  Ethereum   │
│   (EVM)     │         │   (EVM)     │         │   (EVM)     │
└─────────────┘         └─────────────┘         └─────────────┘
```

### Components

1. **Blockchain Clients**: Universal interface supporting EVM, Solana, and NEAR
2. **Event Listeners**: Monitor and decode events from all supported chains
3. **Message Queue**: NATS JetStream for reliable message delivery
4. **Relayer**: Processes cross-chain messages with multi-sig validation
5. **API Server**: RESTful API for bridge operations and status queries
6. **Database**: PostgreSQL for persistent state and audit logs
7. **Cache**: Redis for performance optimization
8. **Monitoring**: Prometheus + Grafana for observability

---

## 🔄 Self-Hosted Relayer System

Metabridge includes a **production-ready, self-hosted relayer** that eliminates dependency on third-party relayer networks. You control the entire message relay infrastructure.

### Relayer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Blockchain Networks                       │
│  EVM (Polygon, BNB, Avalanche, ETH) | Solana | NEAR         │
└────────────────────┬────────────────────────────────────────┘
                     │ Lock/Burn Events
          ┌──────────▼──────────────┐
          │    Event Listeners      │
          │  - EVM Listener         │
          │  - Solana Listener      │
          │  - NEAR Listener        │
          └──────────┬──────────────┘
                     │ Parse Events
          ┌──────────▼──────────────┐
          │    NATS Queue           │
          │  (Message Persistence)  │
          └──────────┬──────────────┘
                     │ Dequeue
          ┌──────────▼──────────────┐
          │   Relayer Workers       │
          │  (Configurable Pool)    │
          └──────────┬──────────────┘
                     │
          ┌──────────▼──────────────┐
          │    Message Processor    │
          │  - Validate signatures  │
          │  - Check security rules │
          │  - Build transactions   │
          └──────────┬──────────────┘
                     │ Sign & Broadcast
          ┌──────────▼──────────────┐
          │  Destination Chains     │
          │  Unlock/Mint Assets     │
          └─────────────────────────┘
```

### Key Features

✅ **Multi-Chain Support**: EVM, Solana, and NEAR processing
✅ **Worker Pool**: Configurable concurrent message processing
✅ **Fault Tolerance**: Automatic retry with exponential backoff
✅ **Health Monitoring**: Per-chain health checks every 30 seconds
✅ **Queue Persistence**: Messages survive relayer restarts
✅ **Multi-Signature Verification**: Validates validator signatures before relay
✅ **Transaction Confirmation**: Waits for blockchain confirmations
✅ **Metrics & Monitoring**: Prometheus metrics for all operations

### Relayer Components

#### 1. Event Listeners

**EVM Listener** (`internal/listener/evm/listener.go`):
- Polls EVM chains for bridge contract events
- Handles block confirmations (128-256 blocks)
- Decodes `TokenLocked` and `NFTLocked` events
- Batch processing (100 blocks at a time)

**Solana Listener** (`internal/listener/solana/listener.go`):
- Monitors Solana program accounts for lock events
- Handles slot confirmations (32 slots)
- Parses account data for bridge events
- Supports SPL token and Metaplex NFT standards

**NEAR Listener** (`internal/listener/near/listener.go`):
- Queries NEAR contract events via RPC
- Handles block confirmations (3 blocks)
- Parses NEP-141 (token) and NEP-171 (NFT) events
- Compatible with NEAR Indexer integration

#### 2. Message Processor

**Security Validation**:
```go
// Validates before processing
- Multi-signature verification (2-of-3 testnet, 3-of-5 mainnet)
- Transaction limit checks
- Daily volume limits
- Rate limiting per sender
- Duplicate message detection
```

**EVM Transaction Building**:
```solidity
// Calls bridge contract unlock function
unlockToken(
    bytes32 messageId,
    address recipient,
    address token,
    uint256 amount,
    bytes[] signatures
)
```

**Solana Transaction Building**:
```rust
// Builds Solana instruction
- Program ID: Bridge program
- Accounts: [relayer, vault_pda, recipient_ata, token_mint, token_program]
- Data: [discriminator, message_id, amount, signatures]
- Uses Associated Token Accounts (ATA) for recipients
```

**NEAR Transaction Building**:
```rust
// Builds NEAR function call
{
  "method_name": "unlock_token",
  "args": {
    "message_id": "...",
    "recipient": "user.near",
    "token": "token.near",
    "amount": "1000000",
    "signatures": ["sig1", "sig2", "sig3"]
  },
  "gas": 100000000000000,
  "deposit": "0"
}
```

### Running the Relayer

#### Development Mode

```bash
# Start relayer with testnet config
./relayer --config config/config.testnet.yaml
```

#### Production Mode (Systemd)

```bash
# Create systemd service
sudo cat > /etc/systemd/system/metabridge-relayer.service <<EOF
[Unit]
Description=Metabridge Relayer Service
After=network.target postgresql.service nats.service

[Service]
Type=simple
User=bridge
WorkingDirectory=/opt/metabridge
ExecStart=/opt/metabridge/relayer --config /opt/metabridge/config/config.mainnet.yaml
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="BRIDGE_ENVIRONMENT=mainnet"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable metabridge-relayer
sudo systemctl start metabridge-relayer

# Check status
sudo systemctl status metabridge-relayer
sudo journalctl -u metabridge-relayer -f
```

#### Docker Deployment

```bash
# Build relayer image
docker build -t metabridge-relayer:latest -f Dockerfile.relayer .

# Run relayer container
docker run -d \
  --name metabridge-relayer \
  --network metabridge-network \
  -v /opt/metabridge/config:/config:ro \
  -v /opt/metabridge/keys:/keys:ro \
  -e BRIDGE_ENVIRONMENT=mainnet \
  metabridge-relayer:latest \
  --config /config/config.mainnet.yaml
```

### Relayer Configuration

```yaml
# config/config.mainnet.yaml
relayer:
  workers: 10                    # Number of concurrent workers
  message_batch_size: 50         # Messages to process per batch
  retry_attempts: 3              # Retry failed messages
  retry_delay: "30s"             # Delay between retries
  confirmation_timeout: "5m"     # Wait time for confirmations
  health_check_interval: "30s"   # Health check frequency

security:
  required_signatures: 3         # Multi-sig threshold
  max_transaction_value: 1000000 # Max value in USD
  daily_volume_limit: 10000000   # Daily limit in USD
  rate_limit_per_minute: 20      # Rate limit per sender
```

### Monitoring Relayer Health

**Prometheus Metrics**:
```prometheus
# Messages processed
bridge_relayer_messages_processed_total{source, destination}

# Processing duration
bridge_relayer_message_processing_duration_seconds{source, destination}

# Failed messages
bridge_relayer_messages_failed_total{source, destination, reason}

# Queue depth
bridge_queue_size
bridge_queue_consumers

# Chain health
bridge_chain_health{chain} # 1 = healthy, 0 = unhealthy
bridge_chain_block_number{chain}
```

**Grafana Alerts**:
- Alert when chain health = 0 for > 5 minutes
- Alert when failed messages > 10 in 10 minutes
- Alert when processing duration > 60 seconds
- Alert when queue depth > 1000 messages

### Scaling the Relayer

**Horizontal Scaling**:
```bash
# Run multiple relayer instances
# Each worker pool processes from shared NATS queue
# Messages are load-balanced automatically

# Instance 1
./relayer --config config.yaml --workers 10

# Instance 2
./relayer --config config.yaml --workers 10

# Instance 3
./relayer --config config.yaml --workers 10
```

**Vertical Scaling**:
```yaml
# Increase workers per instance
relayer:
  workers: 50  # Adjust based on CPU cores
```

### Transaction Signing

**Development (Private Keys)**:
```go
// Load from environment/config
signer, _ := evmCrypto.NewECDSASigner(privateKeyHex)
```

**Production (AWS KMS)**:
```go
// Use AWS KMS for secure key management
signer, _ := kms.NewKMSSigner(kmsKeyID)
```

**Production (Hardware Security Module)**:
```go
// Use HSM for maximum security
signer, _ := hsm.NewHSMSigner(hsmConfig)
```

### Troubleshooting

**Relayer not processing messages**:
1. Check NATS connection: `nats stream info BRIDGE_MESSAGES`
2. Check database connection: `psql -U bridge_user -d metabridge`
3. Check RPC endpoints: View health metrics
4. Check logs: `journalctl -u metabridge-relayer -f`

**Transactions failing on destination**:
1. Verify signer has sufficient gas funds
2. Check destination chain RPC is responsive
3. Verify bridge contract addresses are correct
4. Check transaction nonce management

**High processing latency**:
1. Increase worker count
2. Optimize RPC endpoint selection
3. Check database query performance
4. Review gas price settings

---

## 🌐 Supported Networks

### Testnet Configurations

| Chain | Network | Chain ID | RPC Endpoint | Confirmations |
|-------|---------|----------|--------------|---------------|
| **Polygon** | Amoy | 80002 | https://rpc-amoy.polygon.technology/ | 128 |
| **BNB** | Testnet | 97 | https://data-seed-prebsc-1-s1.binance.org:8545/ | 15 |
| **Avalanche** | Fuji | 43113 | https://api.avax-test.network/ext/bc/C/rpc | 10 |
| **Ethereum** | Sepolia | 11155111 | https://sepolia.infura.io/v3/YOUR-KEY | 32 |
| **Solana** | Devnet | - | https://api.devnet.solana.com | 32 slots |
| **NEAR** | Testnet | - | https://rpc.testnet.near.org | 3 blocks |

### Mainnet Configurations

| Chain | Network | Chain ID | RPC Endpoint | Confirmations |
|-------|---------|----------|--------------|---------------|
| **Polygon** | Mainnet | 137 | https://polygon-rpc.com/ | 256 |
| **BNB** | Mainnet | 56 | https://bsc-dataseed.binance.org/ | 30 |
| **Avalanche** | C-Chain | 43114 | https://api.avax.network/ext/bc/C/rpc | 20 |
| **Ethereum** | Mainnet | 1 | https://mainnet.infura.io/v3/YOUR-KEY | 64 |
| **Solana** | Mainnet-Beta | - | https://api.mainnet-beta.solana.com | 32 slots |
| **NEAR** | Mainnet | - | https://rpc.mainnet.near.org | 3 blocks |

---

## 📦 Prerequisites

### Software Requirements

- **Go**: 1.21 or higher
- **Node.js**: 18.x or higher (for smart contract deployment)
- **Docker**: 20.10 or higher
- **Docker Compose**: 2.0 or higher
- **PostgreSQL**: 15.x
- **Redis**: 7.x
- **NATS**: 2.10 or higher

### For Smart Contract Deployment

- **Hardhat**: For EVM contracts
- **Anchor**: For Solana programs
- **Rust**: For NEAR contracts

### API Keys Required

- Alchemy API Key (for EVM chains)
- Infura API Key (for Ethereum)
- Helius API Key (for Solana)

---

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/EmekaIwuagwu/metabridge-hub.git
cd metabridge-hub
```

### 2. Install Dependencies

```bash
# Install Go dependencies
go mod download

# Install smart contract dependencies (EVM)
cd contracts/evm
npm install
cd ../..
```

### 3. Set Environment Variables

```bash
# Create .env file
cat > .env.testnet <<EOF
# RPC API Keys
ALCHEMY_API_KEY=your_alchemy_key
INFURA_API_KEY=your_infura_key
HELIUS_API_KEY=your_helius_key

# Database
DB_PASSWORD=bridge_password

# Keystore
TESTNET_KEYSTORE_PASSWORD=your_keystore_password

# Contract Addresses (will be filled after deployment)
POLYGON_AMOY_BRIDGE_CONTRACT=
BNB_TESTNET_BRIDGE_CONTRACT=
AVALANCHE_FUJI_BRIDGE_CONTRACT=
ETHEREUM_SEPOLIA_BRIDGE_CONTRACT=
SOLANA_DEVNET_BRIDGE_PROGRAM=
NEAR_TESTNET_BRIDGE_CONTRACT=
EOF
```

### 4. Start Infrastructure (Testnet)

```bash
# Start PostgreSQL, NATS, and Redis
docker-compose -f docker-compose.testnet.yaml up -d postgres nats redis

# Wait for services to be healthy
docker-compose -f docker-compose.testnet.yaml ps
```

### 5. Run Database Migrations

```bash
# Apply database schema
psql -h localhost -U bridge_user -d metabridge_testnet -f internal/database/schema.sql

# Or use Docker
docker exec -i metabridge-postgres-testnet psql -U bridge_user -d metabridge_testnet < internal/database/schema.sql
```

---

## 🧪 Testnet Deployment

### Step 1: Deploy Smart Contracts

#### EVM Contracts (Polygon, BNB, Avalanche, Ethereum)

```bash
cd contracts/evm

# Deploy to Polygon Amoy Testnet
npx hardhat deploy --network polygon-amoy --tags Bridge
export POLYGON_AMOY_BRIDGE_CONTRACT=$(cat deployments/polygon-amoy/Bridge.json | jq -r '.address')

# Deploy to BNB Testnet
npx hardhat deploy --network bnb-testnet --tags Bridge
export BNB_TESTNET_BRIDGE_CONTRACT=$(cat deployments/bnb-testnet/Bridge.json | jq -r '.address')

# Deploy to Avalanche Fuji
npx hardhat deploy --network avalanche-fuji --tags Bridge
export AVALANCHE_FUJI_BRIDGE_CONTRACT=$(cat deployments/avalanche-fuji/Bridge.json | jq -r '.address')

# Deploy to Ethereum Sepolia
npx hardhat deploy --network ethereum-sepolia --tags Bridge
export ETHEREUM_SEPOLIA_BRIDGE_CONTRACT=$(cat deployments/ethereum-sepolia/Bridge.json | jq -r '.address')

# Verify contracts
npx hardhat verify --network polygon-amoy $POLYGON_AMOY_BRIDGE_CONTRACT
```

#### Solana Program (Devnet)

```bash
cd contracts/solana

# Build program
anchor build

# Set Solana to devnet
solana config set --url devnet

# Deploy
anchor deploy --provider.cluster devnet
export SOLANA_DEVNET_BRIDGE_PROGRAM=$(solana address -k target/deploy/bridge-keypair.json)

# Initialize
anchor run initialize --provider.cluster devnet
```

#### NEAR Contract (Testnet)

```bash
cd contracts/near

# Build contract
./build.sh

# Create testnet account
near create-account bridge.testnet --masterAccount your-account.testnet

# Deploy
near deploy --accountId bridge.testnet --wasmFile res/bridge.wasm
export NEAR_TESTNET_BRIDGE_CONTRACT="bridge.testnet"

# Initialize
near call bridge.testnet new '{"owner":"validator.testnet","required_signatures":2}' --accountId bridge.testnet
```

### Step 2: Update Configuration

Update `.env.testnet` with deployed contract addresses:

```bash
# Update environment variables
echo "POLYGON_AMOY_BRIDGE_CONTRACT=$POLYGON_AMOY_BRIDGE_CONTRACT" >> .env.testnet
echo "BNB_TESTNET_BRIDGE_CONTRACT=$BNB_TESTNET_BRIDGE_CONTRACT" >> .env.testnet
# ... etc
```

### Step 3: Start Backend Services

```bash
# Set environment
export BRIDGE_ENVIRONMENT=testnet

# Load environment variables
source .env.testnet

# Start all services
docker-compose -f docker-compose.testnet.yaml up -d

# Check logs
docker-compose -f docker-compose.testnet.yaml logs -f
```

### Step 4: Verify Deployment

```bash
# Check API health
curl http://localhost:8080/health

# Check chain status
curl http://localhost:8080/v1/chains/status

# Check bridge stats
curl http://localhost:8080/v1/stats
```

---

## 🏭 Mainnet Deployment

### ⚠️ Pre-Deployment Checklist

Before deploying to mainnet, ensure:

- [ ] All smart contracts audited by reputable security firm
- [ ] Bug bounty program established
- [ ] Multi-signature wallets configured (3-of-5 minimum)
- [ ] Emergency pause mechanism tested
- [ ] Rate limiting configured
- [ ] Monitoring and alerting configured
- [ ] Incident response plan documented
- [ ] Insurance coverage secured
- [ ] Testnet stress testing completed

### Step 1: Deploy Smart Contracts to Mainnet

```bash
# ⚠️ CAUTION: Deploying to mainnet with real funds

# EVM Contracts
cd contracts/evm

npx hardhat deploy --network polygon-mainnet --tags Bridge
npx hardhat deploy --network bnb-mainnet --tags Bridge
npx hardhat deploy --network avalanche-mainnet --tags Bridge
npx hardhat deploy --network ethereum-mainnet --tags Bridge

# Verify all contracts
npx hardhat verify --network polygon-mainnet $POLYGON_MAINNET_BRIDGE_CONTRACT

# Transfer ownership to multi-sig
npx hardhat run scripts/transfer-ownership.js --network polygon-mainnet
```

### Step 2: Deploy Solana and NEAR Contracts

```bash
# Solana Mainnet
cd contracts/solana
solana config set --url mainnet-beta
anchor deploy --provider.cluster mainnet-beta

# NEAR Mainnet
cd contracts/near
near deploy --accountId bridge.near --wasmFile res/bridge_release.wasm
```

### Step 3: Production Infrastructure

```bash
# Use Kubernetes for production
kubectl create namespace metabridge-mainnet

# Create secrets
kubectl create secret generic bridge-secrets \
  --from-env-file=.env.mainnet \
  -n metabridge-mainnet

# Deploy services
kubectl apply -f deployments/kubernetes/mainnet/
```

### Step 4: Gradual Rollout

Start with conservative limits and gradually increase:

**Week 1**: $1,000 max per transaction
**Week 2**: $10,000 max per transaction
**Week 3**: $50,000 max per transaction
**Week 4+**: $100,000+ with monitoring

---

## ⚙️ Configuration

### Environment Variables

```bash
# Environment Selection
BRIDGE_ENVIRONMENT=testnet  # or mainnet

# Database
DB_HOST=localhost
DB_PASSWORD=secure_password

# RPC Keys
ALCHEMY_API_KEY=your_key
INFURA_API_KEY=your_key
HELIUS_API_KEY=your_key

# Security
TESTNET_KEYSTORE_PASSWORD=password
MAINNET_KEYSTORE_PASSWORD=secure_password

# AWS KMS (mainnet only)
AWS_KMS_EVM_KEY_ID=your_kms_key
```

### Chain Configuration

See `config/config.testnet.yaml` and `config/config.mainnet.yaml` for complete chain configurations.

---

## 📊 Monitoring

### Prometheus Metrics

Access Prometheus at: `http://localhost:9090`

Key metrics:
- `bridge_messages_total` - Total messages processed
- `bridge_messages_by_status` - Messages by status
- `bridge_transaction_value_usd` - Transaction volumes
- `bridge_gas_price_gwei` - Gas prices per chain
- `bridge_processing_time_seconds` - Processing latency

### Grafana Dashboards

Access Grafana at: `http://localhost:3000`

Default credentials: `admin/admin`

Pre-built dashboards:
1. **Bridge Overview**: High-level metrics
2. **Chain Status**: Per-chain health
3. **Transaction Monitoring**: Real-time transactions
4. **Security Dashboard**: Anomaly detection

---

## 🔐 Security

### Testnet Security (2-of-3 Multi-Sig)

- Transaction limit: $10,000
- Daily volume: $100,000
- Rate limit: 100 tx/hour

### Mainnet Security (3-of-5 Multi-Sig)

- Transaction limit: $1,000,000
- Daily volume: $10,000,000
- Rate limit: 20 tx/hour
- Mandatory emergency pause
- Fraud detection enabled
- 24/7 monitoring

### Emergency Procedures

```bash
# Emergency pause (requires multi-sig)
npx hardhat run scripts/emergency-pause.js --network polygon-mainnet

# Stop relayer services
kubectl scale deployment relayer --replicas=0 -n metabridge-mainnet
```

---

## 🧪 Testing

```bash
# Unit tests
go test ./... -v

# Integration tests
go test ./tests/integration/... -v

# E2E tests (requires deployed contracts)
go test ./tests/e2e/... -v -run TestPolygonToBNB
```

---

## 📚 API Documentation

### Health Check

```bash
GET /health
```

### Get Chain Status

```bash
GET /v1/chains/status
```

### Bridge Token

```bash
POST /v1/bridge/token
{
  "source_chain": "polygon-amoy",
  "dest_chain": "bnb-testnet",
  "token_address": "0x...",
  "amount": "1000000000000000000",
  "recipient": "0x..."
}
```

### Get Message Status

```bash
GET /v1/messages/{messageId}
```

---

## 📝 License

MIT License

---

## ⚖️ Disclaimer

This software is provided "as is" without warranty. Use at your own risk. Always conduct thorough security audits before handling real user funds.

---

**Built with ❤️ for the decentralized future**
