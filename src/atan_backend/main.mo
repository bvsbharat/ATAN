import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";

actor ATAN {
    
    // Enhanced data types for ATAN Agent Management System
    public type AgentStatus = {
        #Active;
        #Inactive;
        #Paused;
        #Error;
        #Training;
        #Deployed;
    };

    public type AgentType = {
        #Conversational;
        #Analytical;
        #Creative;
        #Assistant;
        #Specialized;
    };

    public type Agent = {
        id: Text;
        name: Text;
        description: Text;
        agentType: AgentType;
        owner: Principal;
        status: AgentStatus;
        capabilities: [Text];
        configuration: [(Text, Text)];
        createdAt: Int;
        updatedAt: Int;
        lastActiveAt: ?Int;
        version: Nat;
    };

    public type User = {
        id: Principal;
        username: Text;
        email: Text;
        role: UserRole;
        createdAt: Int;
        agentCount: Nat;
        lastLoginAt: ?Int;
        isActive: Bool;
    };

    public type UserRole = {
        #Admin;
        #Developer;
        #User;
    };

    public type CreateAgentRequest = {
        name: Text;
        description: Text;
        agentType: AgentType;
        capabilities: [Text];
        configuration: [(Text, Text)];
    };

    public type UpdateAgentRequest = {
        name: ?Text;
        description: ?Text;
        capabilities: ?[Text];
        configuration: ?[(Text, Text)];
    };

    public type AgentMetrics = {
        agentId: Text;
        totalInteractions: Nat;
        successfulInteractions: Nat;
        averageResponseTime: Nat;
        lastInteractionAt: ?Int;
    };

    public type SystemMetrics = {
        totalAgents: Nat;
        activeAgents: Nat;
        totalUsers: Nat;
        activeUsers: Nat;
        totalInteractions: Nat;
        systemUptime: Int;
    };

    public type ApiResponse<T> = Result.Result<T, Text>;

    public type HealthCheck = {
        status: Text;
        timestamp: Int;
        version: Text;
        uptime: Int;
    };
    
    // State variables
    private stable var nextAgentId: Nat = 1;
    private stable var systemStartTime: Int = Time.now();
    private stable var totalInteractions: Nat = 0;
    
    private var agents = HashMap.HashMap<Text, Agent>(50, Text.equal, Text.hash);
    private var users = HashMap.HashMap<Principal, User>(50, Principal.equal, Principal.hash);
    private var agentMetrics = HashMap.HashMap<Text, AgentMetrics>(50, Text.equal, Text.hash);

    // System initialization
    system func preupgrade() {
        // Preserve state during upgrades
    };

    system func postupgrade() {
        // Restore state after upgrades
    };
    
    // User management functions
    public shared(msg) func registerUser(username: Text, email: Text) : async ApiResponse<User> {
        let caller = msg.caller;
        
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot register");
        };
        
        switch (users.get(caller)) {
            case (?existingUser) {
                #err("User already registered")
            };
            case null {
                let newUser: User = {
                    id = caller;
                    username = username;
                    email = email;
                    role = #User;
                    createdAt = Time.now();
                    agentCount = 0;
                    lastLoginAt = ?Time.now();
                    isActive = true;
                };
                users.put(caller, newUser);
                #ok(newUser)
            };
        }
    };

    public shared(msg) func getUser() : async ApiResponse<User> {
        let caller = msg.caller;
        
        switch (users.get(caller)) {
            case (?user) { 
                // Update last login time
                let updatedUser: User = {
                    id = user.id;
                    username = user.username;
                    email = user.email;
                    role = user.role;
                    createdAt = user.createdAt;
                    agentCount = user.agentCount;
                    lastLoginAt = ?Time.now();
                    isActive = user.isActive;
                };
                users.put(caller, updatedUser);
                #ok(updatedUser)
            };
            case null { #err("User not found") };
        }
    };

    public shared(msg) func updateUserProfile(username: ?Text, email: ?Text) : async ApiResponse<User> {
        let caller = msg.caller;
        
        switch (users.get(caller)) {
            case null { #err("User not found") };
            case (?user) {
                let updatedUser: User = {
                    id = user.id;
                    username = Option.get(username, user.username);
                    email = Option.get(email, user.email);
                    role = user.role;
                    createdAt = user.createdAt;
                    agentCount = user.agentCount;
                    lastLoginAt = user.lastLoginAt;
                    isActive = user.isActive;
                };
                users.put(caller, updatedUser);
                #ok(updatedUser)
            };
        }
    };
    
    // Enhanced agent management functions
    public shared(msg) func createAgent(request: CreateAgentRequest) : async ApiResponse<Agent> {
        let caller = msg.caller;
        
        // Check if user exists and is active
        switch (users.get(caller)) {
            case null { #err("User not registered") };
            case (?user) {
                if (not user.isActive) {
                    return #err("User account is inactive");
                };
                
                let agentId = "agent_" # Nat.toText(nextAgentId);
                nextAgentId += 1;
                
                let newAgent: Agent = {
                    id = agentId;
                    name = request.name;
                    description = request.description;
                    agentType = request.agentType;
                    owner = caller;
                    status = #Inactive;
                    capabilities = request.capabilities;
                    configuration = request.configuration;
                    createdAt = Time.now();
                    updatedAt = Time.now();
                    lastActiveAt = null;
                    version = 1;
                };
                
                agents.put(agentId, newAgent);
                
                // Initialize agent metrics
                let metrics: AgentMetrics = {
                    agentId = agentId;
                    totalInteractions = 0;
                    successfulInteractions = 0;
                    averageResponseTime = 0;
                    lastInteractionAt = null;
                };
                agentMetrics.put(agentId, metrics);
                
                // Update user agent count
                let updatedUser: User = {
                    id = user.id;
                    username = user.username;
                    email = user.email;
                    role = user.role;
                    createdAt = user.createdAt;
                    agentCount = user.agentCount + 1;
                    lastLoginAt = user.lastLoginAt;
                    isActive = user.isActive;
                };
                users.put(caller, updatedUser);
                
                #ok(newAgent)
            };
        }
    };

    public shared(msg) func updateAgent(agentId: Text, request: UpdateAgentRequest) : async ApiResponse<Agent> {
        let caller = msg.caller;
        
        switch (agents.get(agentId)) {
            case null { #err("Agent not found") };
            case (?agent) {
                if (not Principal.equal(agent.owner, caller)) {
                    #err("Not authorized to update this agent")
                } else {
                    let updatedAgent: Agent = {
                        id = agent.id;
                        name = Option.get(request.name, agent.name);
                        description = Option.get(request.description, agent.description);
                        agentType = agent.agentType;
                        owner = agent.owner;
                        status = agent.status;
                        capabilities = Option.get(request.capabilities, agent.capabilities);
                        configuration = Option.get(request.configuration, agent.configuration);
                        createdAt = agent.createdAt;
                        updatedAt = Time.now();
                        lastActiveAt = agent.lastActiveAt;
                        version = agent.version + 1;
                    };
                    agents.put(agentId, updatedAgent);
                    #ok(updatedAgent)
                }
            };
        }
    };

    public shared(msg) func deleteAgent(agentId: Text) : async ApiResponse<Text> {
        let caller = msg.caller;
        
        switch (agents.get(agentId)) {
            case null { #err("Agent not found") };
            case (?agent) {
                if (not Principal.equal(agent.owner, caller)) {
                    #err("Not authorized to delete this agent")
                } else {
                    agents.delete(agentId);
                    agentMetrics.delete(agentId);
                    
                    // Update user agent count
                    switch (users.get(caller)) {
                        case (?user) {
                            let updatedUser: User = {
                                id = user.id;
                                username = user.username;
                                email = user.email;
                                role = user.role;
                                createdAt = user.createdAt;
                                agentCount = if (user.agentCount > 0) user.agentCount - 1 else 0;
                                lastLoginAt = user.lastLoginAt;
                                isActive = user.isActive;
                            };
                            users.put(caller, updatedUser);
                        };
                        case null {};
                    };
                    
                    #ok("Agent deleted successfully")
                }
            };
        }
    };
    
    public shared(msg) func getUserAgents() : async ApiResponse<[Agent]> {
        let caller = msg.caller;
        
        let userAgents = Array.filter<Agent>(
            Iter.toArray(agents.vals()),
            func(agent: Agent) : Bool {
                Principal.equal(agent.owner, caller)
            }
        );
        
        #ok(userAgents)
    };
    
    public shared(msg) func updateAgentStatus(agentId: Text, status: AgentStatus) : async ApiResponse<Agent> {
        let caller = msg.caller;
        
        switch (agents.get(agentId)) {
            case null { #err("Agent not found") };
            case (?agent) {
                if (not Principal.equal(agent.owner, caller)) {
                    #err("Not authorized to update this agent")
                } else {
                    let updatedAgent: Agent = {
                        id = agent.id;
                        name = agent.name;
                        description = agent.description;
                        agentType = agent.agentType;
                        owner = agent.owner;
                        status = status;
                        capabilities = agent.capabilities;
                        configuration = agent.configuration;
                        createdAt = agent.createdAt;
                        updatedAt = Time.now();
                        lastActiveAt = if (status == #Active) ?Time.now() else agent.lastActiveAt;
                        version = agent.version;
                    };
                    agents.put(agentId, updatedAgent);
                    #ok(updatedAgent)
                }
            };
        }
    };

    // Agent interaction and metrics
    public shared(msg) func recordAgentInteraction(agentId: Text, successful: Bool, responseTime: Nat) : async ApiResponse<Text> {
        let caller = msg.caller;
        
        switch (agents.get(agentId)) {
            case null { #err("Agent not found") };
            case (?agent) {
                if (not Principal.equal(agent.owner, caller)) {
                    #err("Not authorized to record interactions for this agent")
                } else {
                    switch (agentMetrics.get(agentId)) {
                        case (?metrics) {
                            let newTotal = metrics.totalInteractions + 1;
                            let newSuccessful = if (successful) metrics.successfulInteractions + 1 else metrics.successfulInteractions;
                            let newAverage = (metrics.averageResponseTime * metrics.totalInteractions + responseTime) / newTotal;
                            
                            let updatedMetrics: AgentMetrics = {
                                agentId = metrics.agentId;
                                totalInteractions = newTotal;
                                successfulInteractions = newSuccessful;
                                averageResponseTime = newAverage;
                                lastInteractionAt = ?Time.now();
                            };
                            agentMetrics.put(agentId, updatedMetrics);
                            totalInteractions += 1;
                            #ok("Interaction recorded successfully")
                        };
                        case null { #err("Agent metrics not found") };
                    }
                }
            };
        }
    };
    
    // Public query functions
    public query func getAllAgents() : async [Agent] {
        Iter.toArray(agents.vals())
    };

    public query func getAgent(agentId: Text) : async ApiResponse<Agent> {
        switch (agents.get(agentId)) {
            case (?agent) { #ok(agent) };
            case null { #err("Agent not found") };
        }
    };

    public query func getAgentMetrics(agentId: Text) : async ApiResponse<AgentMetrics> {
        switch (agentMetrics.get(agentId)) {
            case (?metrics) { #ok(metrics) };
            case null { #err("Agent metrics not found") };
        }
    };

    public query func getAgentsByType(agentType: AgentType) : async [Agent] {
        Array.filter<Agent>(
            Iter.toArray(agents.vals()),
            func(agent: Agent) : Bool {
                agent.agentType == agentType
            }
        )
    };

    public query func getAgentsByStatus(status: AgentStatus) : async [Agent] {
        Array.filter<Agent>(
            Iter.toArray(agents.vals()),
            func(agent: Agent) : Bool {
                agent.status == status
            }
        )
    };

    public query func getSystemMetrics() : async SystemMetrics {
        let activeAgents = Array.filter<Agent>(
            Iter.toArray(agents.vals()),
            func(agent: Agent) : Bool {
                agent.status == #Active
            }
        );
        
        let activeUsers = Array.filter<User>(
            Iter.toArray(users.vals()),
            func(user: User) : Bool {
                user.isActive
            }
        );
        
        {
            totalAgents = agents.size();
            activeAgents = activeAgents.size();
            totalUsers = users.size();
            activeUsers = activeUsers.size();
            totalInteractions = totalInteractions;
            systemUptime = Time.now() - systemStartTime;
        }
    };

    public query func healthCheck() : async HealthCheck {
        {
            status = "healthy";
            timestamp = Time.now();
            version = "1.0.0";
            uptime = Time.now() - systemStartTime;
        }
    };

    // Admin functions (restricted to admin users)
    public shared(msg) func promoteUser(userId: Principal, role: UserRole) : async ApiResponse<Text> {
        let caller = msg.caller;
        
        // Check if caller is admin
        switch (users.get(caller)) {
            case null { #err("Caller not found") };
            case (?callerUser) {
                if (callerUser.role != #Admin) {
                    #err("Only admins can promote users")
                } else {
                    switch (users.get(userId)) {
                        case null { #err("User not found") };
                        case (?user) {
                            let updatedUser: User = {
                                id = user.id;
                                username = user.username;
                                email = user.email;
                                role = role;
                                createdAt = user.createdAt;
                                agentCount = user.agentCount;
                                lastLoginAt = user.lastLoginAt;
                                isActive = user.isActive;
                            };
                            users.put(userId, updatedUser);
                            #ok("User role updated successfully")
                        };
                    }
                }
            };
        }
    };

    public shared(msg) func deactivateUser(userId: Principal) : async ApiResponse<Text> {
        let caller = msg.caller;
        
        // Check if caller is admin
        switch (users.get(caller)) {
            case null { #err("Caller not found") };
            case (?callerUser) {
                if (callerUser.role != #Admin) {
                    #err("Only admins can deactivate users")
                } else {
                    switch (users.get(userId)) {
                        case null { #err("User not found") };
                        case (?user) {
                            let updatedUser: User = {
                                id = user.id;
                                username = user.username;
                                email = user.email;
                                role = user.role;
                                createdAt = user.createdAt;
                                agentCount = user.agentCount;
                                lastLoginAt = user.lastLoginAt;
                                isActive = false;
                            };
                            users.put(userId, updatedUser);
                            #ok("User deactivated successfully")
                        };
                    }
                }
            };
        }
    };
}