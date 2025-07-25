# ATAN - Agent Management System

ATAN is a comprehensive agent management system built on the Internet Computer Protocol (ICP) using Motoko. It provides a complete solution for creating, managing, and monitoring AI agents with a web-based dashboard interface.

## 🚀 Features

### Backend Capabilities
- **User Management**: Registration, authentication, and profile management
- **Agent Lifecycle**: Create, update, delete, and monitor agents
- **Agent Types**: Support for Conversational, Analytical, Creative, Assistant, and Specialized agents
- **Status Tracking**: Real-time agent status monitoring (Active, Inactive, Paused, Error, Training, Deployed)
- **Metrics & Analytics**: Track agent interactions, performance metrics, and system statistics
- **Role-Based Access**: Admin, Developer, and User roles with appropriate permissions
- **Activity Logging**: Comprehensive audit trail of all system activities

### Frontend Features
- **Dashboard**: Comprehensive overview of system metrics and user agents
- **Agent Management**: Visual interface for creating and managing agents
- **User Profile**: Profile management and account settings
- **Real-time Notifications**: System alerts and activity updates
- **Responsive Design**: Modern, mobile-friendly interface
- **Activity Feed**: Recent system activities and interactions

## 📁 Project Structure

```
ATAN/
├── src/
│   ├── atan_backend/
│   │   └── main.mo          # Backend canister with core business logic
│   └── atan_frontend/
│       └── main.mo          # Frontend canister with UI rendering
├── dfx.json                 # DFX configuration file
├── README.md               # Project documentation
└── .env                    # Environment variables (auto-generated)
```

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed:

1. **DFX (DFINITY SDK)**
   ```bash
   sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
   ```

2. **Node.js** (version 16 or higher)
   ```bash
   # Using nvm (recommended)
   nvm install 16
   nvm use 16
   ```

3. **Vessel** (Motoko package manager)
   ```bash
   # Install vessel
   wget https://github.com/dfinity/vessel/releases/latest/download/vessel-macos
   chmod +x vessel-macos
   sudo mv vessel-macos /usr/local/bin/vessel
   ```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd ATAN

# Start the local Internet Computer replica
dfx start --background
```

### 2. Deploy the Canisters

```bash
# Deploy both backend and frontend canisters
dfx deploy

# Or deploy individually
dfx deploy atan_backend
dfx deploy atan_frontend
```

### 3. Get Canister URLs

```bash
# Get the backend canister URL
echo "Backend: http://$(dfx canister id atan_backend).localhost:4943"

# Get the frontend canister URL
echo "Frontend: http://$(dfx canister id atan_frontend).localhost:4943"
```

## 📖 API Documentation

### Backend Canister (atan_backend)

#### User Management

- `registerUser(username: Text, email: Text)` - Register a new user
- `getUser()` - Get current user information
- `updateUserProfile(username: ?Text, email: ?Text)` - Update user profile

#### Agent Management

- `createAgent(request: CreateAgentRequest)` - Create a new agent
- `updateAgent(agentId: Text, request: UpdateAgentRequest)` - Update agent details
- `deleteAgent(agentId: Text)` - Delete an agent
- `getUserAgents()` - Get all agents for current user
- `updateAgentStatus(agentId: Text, status: AgentStatus)` - Update agent status

#### Metrics & Monitoring

- `getSystemMetrics()` - Get system-wide metrics
- `getAgentMetrics(agentId: Text)` - Get metrics for specific agent
- `recordAgentInteraction(agentId: Text, successful: Bool, responseTime: Nat)` - Record agent interaction

#### Query Functions

- `getAllAgents()` - Get all agents in the system
- `getAgent(agentId: Text)` - Get specific agent details
- `getAgentsByType(agentType: AgentType)` - Filter agents by type
- `getAgentsByStatus(status: AgentStatus)` - Filter agents by status
- `healthCheck()` - System health status

### Frontend Canister (atan_frontend)

#### Page Rendering

- `renderPage(pageName: Text)` - Render specific pages (dashboard, agents, profile, settings)
- `getDashboardData()` - Get comprehensive dashboard data

#### UI Interactions

- `createAgent(request: CreateAgentRequest)` - Create agent with UI feedback
- `updateAgentStatus(agentId: Text, status: AgentStatus)` - Update status with notifications
- `deleteAgent(agentId: Text)` - Delete agent with confirmation

#### Activity & Notifications

- `getNotifications()` - Get user notifications
- `getActivityLog(limit: ?Nat)` - Get system activity log

## 🔧 Development

### Local Development

```bash
# Start local replica in the background
dfx start --background

# Deploy canisters in development mode
dfx deploy --mode development

# View logs
dfx logs
```

### Testing

```bash
# Test backend functions
dfx canister call atan_backend healthCheck

# Register a test user
dfx canister call atan_backend registerUser '("testuser", "test@example.com")'

# Create a test agent
dfx canister call atan_backend createAgent '(record {
  name = "Test Agent";
  description = "A test conversational agent";
  agentType = variant { Conversational };
  capabilities = vec { "chat"; "qa" };
  configuration = vec { ("model", "gpt-3.5"); ("temperature", "0.7") }
})'
```

### Debugging

```bash
# Check canister status
dfx canister status atan_backend
dfx canister status atan_frontend

# View canister logs
dfx logs atan_backend
dfx logs atan_frontend

# Stop and restart
dfx stop
dfx start --clean --background
dfx deploy
```

## 🌐 Deployment to IC Mainnet

### 1. Create Identity

```bash
# Create a new identity for mainnet
dfx identity new mainnet
dfx identity use mainnet

# Get your principal ID
dfx identity get-principal
```

### 2. Add Cycles

```bash
# Convert ICP to cycles (requires ICP tokens)
dfx ledger account-id
dfx ledger transfer --amount 1.0 --memo 0 <CYCLES_WALLET_PRINCIPAL>
```

### 3. Deploy to Mainnet

```bash
# Deploy to IC mainnet
dfx deploy --network ic

# Get mainnet URLs
echo "Backend: https://$(dfx canister id atan_backend --network ic).ic0.app"
echo "Frontend: https://$(dfx canister id atan_frontend --network ic).ic0.app"
```

## 🔐 Security Considerations

- **Authentication**: All user actions require proper authentication
- **Authorization**: Role-based access control for admin functions
- **Data Validation**: Input validation on all user-provided data
- **Principal Verification**: Caller verification for all sensitive operations
- **Anonymous Prevention**: Anonymous users cannot perform write operations

## 📊 Monitoring & Analytics

### System Metrics
- Total agents and active agents
- User registration and activity
- Agent interactions and success rates
- System uptime and performance

### Agent Metrics
- Interaction counts and success rates
- Average response times
- Last activity timestamps
- Version tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the [DFINITY Developer Forum](https://forum.dfinity.org/)
- Review the [Motoko Documentation](https://internetcomputer.org/docs/current/motoko/intro/)

## 🔄 Changelog

### Version 1.0.0
- Initial release with core agent management functionality
- User registration and authentication
- Agent lifecycle management
- Web-based dashboard interface
- Metrics and monitoring capabilities
- Role-based access control

---

**Built with ❤️ on the Internet Computer**
