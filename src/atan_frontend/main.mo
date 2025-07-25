import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Option "mo:base/Option";

// Import backend canister interface
import Backend "canister:atan_backend";

actor ATANFrontend {
    // Frontend-specific types
    public type PageData = {
        title: Text;
        content: Text;
        timestamp: Int;
    };

    public type DashboardData = {
        userInfo: ?Backend.User;
        agents: [Backend.Agent];
        systemMetrics: Backend.SystemMetrics;
        recentActivity: [ActivityItem];
    };

    public type ActivityItem = {
        id: Text;
        action: Text;
        agentId: ?Text;
        timestamp: Int;
        status: Text;
    };

    public type UIComponent = {
        #Header: HeaderComponent;
        #Sidebar: SidebarComponent;
        #Dashboard: DashboardComponent;
        #AgentCard: AgentCardComponent;
        #Modal: ModalComponent;
    };

    public type HeaderComponent = {
        title: Text;
        user: ?Backend.User;
        notifications: [NotificationItem];
    };

    public type SidebarComponent = {
        menuItems: [MenuItem];
        isCollapsed: Bool;
        activeItem: Text;
    };

    public type DashboardComponent = {
        stats: DashboardStats;
        charts: [ChartData];
        quickActions: [QuickAction];
    };

    public type AgentCardComponent = {
        agent: Backend.Agent;
        metrics: ?Backend.AgentMetrics;
        actions: [CardAction];
    };

    public type ModalComponent = {
        id: Text;
        title: Text;
        content: Text;
        actions: [ModalAction];
        isVisible: Bool;
    };

    public type MenuItem = {
        id: Text;
        label: Text;
        icon: Text;
        url: Text;
        isActive: Bool;
    };

    public type NotificationItem = {
        id: Text;
        message: Text;
        type_: Text; // info, warning, error, success
        timestamp: Int;
        isRead: Bool;
    };

    public type DashboardStats = {
        totalAgents: Nat;
        activeAgents: Nat;
        totalInteractions: Nat;
        systemUptime: Int;
    };

    public type ChartData = {
        id: Text;
        title: Text;
        type_: Text; // line, bar, pie, doughnut
        data: [(Text, Nat)];
        labels: [Text];
    };

    public type QuickAction = {
        id: Text;
        label: Text;
        icon: Text;
        action: Text;
        isEnabled: Bool;
    };

    public type CardAction = {
        id: Text;
        label: Text;
        action: Text;
        style: Text; // primary, secondary, danger
    };

    public type ModalAction = {
        id: Text;
        label: Text;
        action: Text;
        style: Text;
    };

    // State management
    private var activityLog = HashMap.HashMap<Text, ActivityItem>(100, Text.equal, Text.hash);
    private var notifications = HashMap.HashMap<Text, NotificationItem>(50, Text.equal, Text.hash);
    private stable var nextActivityId: Nat = 1;
    private stable var nextNotificationId: Nat = 1;

    // Frontend API functions
    public shared(msg) func getDashboardData() : async Result.Result<DashboardData, Text> {
        let caller = msg.caller;
        
        try {
            // Get user info from backend
            let userResult = await Backend.getUser();
            let userInfo = switch (userResult) {
                case (#ok(user)) { ?user };
                case (#err(_)) { null };
            };

            // Get user's agents
            let agentsResult = await Backend.getUserAgents();
            let agents = switch (agentsResult) {
                case (#ok(agentList)) { agentList };
                case (#err(_)) { [] };
            };

            // Get system metrics
            let systemMetrics = await Backend.getSystemMetrics();

            // Get recent activity
            let recentActivity = getRecentActivity(10);

            let dashboardData: DashboardData = {
                userInfo = userInfo;
                agents = agents;
                systemMetrics = systemMetrics;
                recentActivity = recentActivity;
            };

            #ok(dashboardData)
        } catch (error) {
            #err("Failed to load dashboard data")
        }
    };

    public shared(msg) func renderPage(pageName: Text) : async Result.Result<Text, Text> {
        switch (pageName) {
            case ("dashboard") { renderDashboard(msg.caller) };
            case ("agents") { renderAgentsPage(msg.caller) };
            case ("profile") { renderProfilePage(msg.caller) };
            case ("settings") { renderSettingsPage(msg.caller) };
            case (_) { #err("Page not found") };
        }
    };

    public shared(msg) func createAgent(request: Backend.CreateAgentRequest) : async Result.Result<Backend.Agent, Text> {
        let result = await Backend.createAgent(request);
        
        // Log activity
        switch (result) {
            case (#ok(agent)) {
                logActivity("create_agent", ?agent.id, "Agent created successfully");
                addNotification("Agent '" # agent.name # "' created successfully", "success");
            };
            case (#err(error)) {
                logActivity("create_agent_failed", null, "Failed to create agent: " # error);
                addNotification("Failed to create agent: " # error, "error");
            };
        };
        
        result
    };

    public shared(msg) func updateAgentStatus(agentId: Text, status: Backend.AgentStatus) : async Result.Result<Backend.Agent, Text> {
        let result = await Backend.updateAgentStatus(agentId, status);
        
        // Log activity
        switch (result) {
            case (#ok(agent)) {
                let statusText = agentStatusToText(status);
                logActivity("update_agent_status", ?agentId, "Agent status updated to " # statusText);
                addNotification("Agent status updated to " # statusText, "info");
            };
            case (#err(error)) {
                logActivity("update_agent_status_failed", ?agentId, "Failed to update agent status: " # error);
                addNotification("Failed to update agent status: " # error, "error");
            };
        };
        
        result
    };

    public shared(msg) func deleteAgent(agentId: Text) : async Result.Result<Text, Text> {
        let result = await Backend.deleteAgent(agentId);
        
        // Log activity
        switch (result) {
            case (#ok(message)) {
                logActivity("delete_agent", ?agentId, "Agent deleted successfully");
                addNotification("Agent deleted successfully", "success");
            };
            case (#err(error)) {
                logActivity("delete_agent_failed", ?agentId, "Failed to delete agent: " # error);
                addNotification("Failed to delete agent: " # error, "error");
            };
        };
        
        result
    };

    // UI Component rendering functions
    private func renderDashboard(caller: Principal) : async Result.Result<Text, Text> {
        try {
            let dashboardResult = await getDashboardData();
            
            switch (dashboardResult) {
                case (#ok(data)) {
                    let html = generateDashboardHTML(data);
                    #ok(html)
                };
                case (#err(error)) {
                    #err(error)
                };
            }
        } catch (error) {
            #err("Failed to render dashboard")
        }
    };

    private func renderAgentsPage(caller: Principal) : async Result.Result<Text, Text> {
        try {
            let agentsResult = await Backend.getUserAgents();
            
            switch (agentsResult) {
                case (#ok(agents)) {
                    let html = generateAgentsPageHTML(agents);
                    #ok(html)
                };
                case (#err(error)) {
                    #err(error)
                };
            }
        } catch (error) {
            #err("Failed to render agents page")
        }
    };

    private func renderProfilePage(caller: Principal) : async Result.Result<Text, Text> {
        try {
            let userResult = await Backend.getUser();
            
            switch (userResult) {
                case (#ok(user)) {
                    let html = generateProfilePageHTML(user);
                    #ok(html)
                };
                case (#err(error)) {
                    #err(error)
                };
            }
        } catch (error) {
            #err("Failed to render profile page")
        }
    };

    private func renderSettingsPage(caller: Principal) : async Result.Result<Text, Text> {
        let html = generateSettingsPageHTML();
        #ok(html)
    };

    // HTML generation functions
    private func generateDashboardHTML(data: DashboardData) : Text {
        let userSection = switch (data.userInfo) {
            case (?user) {
                "<div class='user-info'>" #
                "<h2>Welcome, " # user.username # "!</h2>" #
                "<p>Email: " # user.email # "</p>" #
                "<p>Agents: " # Nat.toText(user.agentCount) # "</p>" #
                "</div>"
            };
            case null {
                "<div class='user-info'><p>Please log in to view your dashboard.</p></div>"
            };
        };

        let statsSection = 
            "<div class='stats-grid'>" #
            "<div class='stat-card'>" #
            "<h3>Total Agents</h3>" #
            "<p class='stat-number'>" # Nat.toText(data.systemMetrics.totalAgents) # "</p>" #
            "</div>" #
            "<div class='stat-card'>" #
            "<h3>Active Agents</h3>" #
            "<p class='stat-number'>" # Nat.toText(data.systemMetrics.activeAgents) # "</p>" #
            "</div>" #
            "<div class='stat-card'>" #
            "<h3>Total Users</h3>" #
            "<p class='stat-number'>" # Nat.toText(data.systemMetrics.totalUsers) # "</p>" #
            "</div>" #
            "<div class='stat-card'>" #
            "<h3>Interactions</h3>" #
            "<p class='stat-number'>" # Nat.toText(data.systemMetrics.totalInteractions) # "</p>" #
            "</div>" #
            "</div>";

        let agentsSection = generateAgentsListHTML(data.agents);
        let activitySection = generateActivityHTML(data.recentActivity);

        "<!DOCTYPE html>" #
        "<html><head><title>ATAN Dashboard</title>" #
        generateCSS() #
        "</head><body>" #
        generateHeader() #
        "<main class='dashboard'>" #
        userSection #
        statsSection #
        agentsSection #
        activitySection #
        "</main>" #
        generateFooter() #
        generateJavaScript() #
        "</body></html>"
    };

    private func generateAgentsPageHTML(agents: [Backend.Agent]) : Text {
        let agentsGrid = generateAgentsGridHTML(agents);
        
        "<!DOCTYPE html>" #
        "<html><head><title>ATAN - My Agents</title>" #
        generateCSS() #
        "</head><body>" #
        generateHeader() #
        "<main class='agents-page'>" #
        "<div class='page-header'>" #
        "<h1>My Agents</h1>" #
        "<button class='btn btn-primary' onclick='openCreateAgentModal()'>Create New Agent</button>" #
        "</div>" #
        agentsGrid #
        "</main>" #
        generateCreateAgentModal() #
        generateFooter() #
        generateJavaScript() #
        "</body></html>"
    };

    private func generateProfilePageHTML(user: Backend.User) : Text {
        let roleText = userRoleToText(user.role);
        
        "<!DOCTYPE html>" #
        "<html><head><title>ATAN - Profile</title>" #
        generateCSS() #
        "</head><body>" #
        generateHeader() #
        "<main class='profile-page'>" #
        "<div class='profile-card'>" #
        "<h1>User Profile</h1>" #
        "<div class='profile-info'>" #
        "<p><strong>Username:</strong> " # user.username # "</p>" #
        "<p><strong>Email:</strong> " # user.email # "</p>" #
        "<p><strong>Role:</strong> " # roleText # "</p>" #
        "<p><strong>Agent Count:</strong> " # Nat.toText(user.agentCount) # "</p>" #
        "<p><strong>Member Since:</strong> " # Int.toText(user.createdAt) # "</p>" #
        "</div>" #
        "<div class='profile-actions'>" #
        "<button class='btn btn-primary' onclick='editProfile()'>Edit Profile</button>" #
        "</div>" #
        "</div>" #
        "</main>" #
        generateFooter() #
        generateJavaScript() #
        "</body></html>"
    };

    private func generateSettingsPageHTML() : Text {
        "<!DOCTYPE html>" #
        "<html><head><title>ATAN - Settings</title>" #
        generateCSS() #
        "</head><body>" #
        generateHeader() #
        "<main class='settings-page'>" #
        "<h1>Settings</h1>" #
        "<div class='settings-section'>" #
        "<h2>Account Settings</h2>" #
        "<p>Manage your account preferences and security settings.</p>" #
        "</div>" #
        "<div class='settings-section'>" #
        "<h2>Agent Settings</h2>" #
        "<p>Configure default settings for your agents.</p>" #
        "</div>" #
        "<div class='settings-section'>" #
        "<h2>Notification Settings</h2>" #
        "<p>Manage your notification preferences.</p>" #
        "</div>" #
        "</main>" #
        generateFooter() #
        generateJavaScript() #
        "</body></html>"
    };

    // Helper HTML generation functions
    private func generateHeader() : Text {
        "<header class='main-header'>" #
        "<div class='header-content'>" #
        "<h1 class='logo'>ATAN</h1>" #
        "<nav class='main-nav'>" #
        "<a href='/dashboard' class='nav-link'>Dashboard</a>" #
        "<a href='/agents' class='nav-link'>Agents</a>" #
        "<a href='/profile' class='nav-link'>Profile</a>" #
        "<a href='/settings' class='nav-link'>Settings</a>" #
        "</nav>" #
        "<div class='header-actions'>" #
        "<button class='btn btn-secondary' onclick='logout()'>Logout</button>" #
        "</div>" #
        "</div>" #
        "</header>"
    };

    private func generateFooter() : Text {
        "<footer class='main-footer'>" #
        "<p>&copy; 2024 ATAN - Agent Management System</p>" #
        "</footer>"
    };

    private func generateCSS() : Text {
        "<style>" #
        "* { margin: 0; padding: 0; box-sizing: border-box; }" #
        "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; }" #
        ".main-header { background: #2563eb; color: white; padding: 1rem 0; }" #
        ".header-content { max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; padding: 0 2rem; }" #
        ".logo { font-size: 1.5rem; font-weight: bold; }" #
        ".main-nav { display: flex; gap: 2rem; }" #
        ".nav-link { color: white; text-decoration: none; padding: 0.5rem 1rem; border-radius: 4px; transition: background 0.2s; }" #
        ".nav-link:hover { background: rgba(255,255,255,0.1); }" #
        ".btn { padding: 0.5rem 1rem; border: none; border-radius: 4px; cursor: pointer; font-size: 0.9rem; transition: all 0.2s; }" #
        ".btn-primary { background: #2563eb; color: white; }" #
        ".btn-primary:hover { background: #1d4ed8; }" #
        ".btn-secondary { background: #6b7280; color: white; }" #
        ".btn-secondary:hover { background: #4b5563; }" #
        ".dashboard { max-width: 1200px; margin: 2rem auto; padding: 0 2rem; }" #
        ".stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem; margin: 2rem 0; }" #
        ".stat-card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }" #
        ".stat-card h3 { color: #6b7280; font-size: 0.9rem; margin-bottom: 0.5rem; }" #
        ".stat-number { font-size: 2rem; font-weight: bold; color: #2563eb; }" #
        ".agents-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1rem; margin: 2rem 0; }" #
        ".agent-card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }" #
        ".agent-card h3 { margin-bottom: 0.5rem; color: #1f2937; }" #
        ".agent-status { display: inline-block; padding: 0.25rem 0.5rem; border-radius: 4px; font-size: 0.8rem; font-weight: bold; }" #
        ".status-active { background: #dcfce7; color: #166534; }" #
        ".status-inactive { background: #f3f4f6; color: #6b7280; }" #
        ".main-footer { background: #1f2937; color: white; text-align: center; padding: 2rem 0; margin-top: 4rem; }" #
        "</style>"
    };

    private func generateJavaScript() : Text {
        "<script>" #
        "function openCreateAgentModal() { alert('Create Agent Modal - To be implemented'); }" #
        "function editProfile() { alert('Edit Profile - To be implemented'); }" #
        "function logout() { alert('Logout - To be implemented'); }" #
        "function updateAgentStatus(agentId, status) { alert('Update Agent Status - To be implemented'); }" #
        "function deleteAgent(agentId) { if(confirm('Are you sure?')) { alert('Delete Agent - To be implemented'); } }" #
        "</script>"
    };

    private func generateCreateAgentModal() : Text {
        "<div id='createAgentModal' class='modal' style='display: none;'>" #
        "<div class='modal-content'>" #
        "<h2>Create New Agent</h2>" #
        "<form id='createAgentForm'>" #
        "<input type='text' placeholder='Agent Name' required>" #
        "<textarea placeholder='Description' required></textarea>" #
        "<select required><option value=''>Select Type</option><option value='Conversational'>Conversational</option></select>" #
        "<button type='submit' class='btn btn-primary'>Create Agent</button>" #
        "</form>" #
        "</div>" #
        "</div>"
    };

    private func generateAgentsListHTML(agents: [Backend.Agent]) : Text {
        if (agents.size() == 0) {
            "<div class='agents-section'><h2>Your Agents</h2><p>No agents found. Create your first agent to get started!</p></div>"
        } else {
            let agentCards = Array.foldLeft<Backend.Agent, Text>(agents, "", func(acc, agent) {
                acc # generateAgentCardHTML(agent)
            });
            "<div class='agents-section'><h2>Your Agents</h2><div class='agents-grid'>" # agentCards # "</div></div>"
        }
    };

    private func generateAgentsGridHTML(agents: [Backend.Agent]) : Text {
        if (agents.size() == 0) {
            "<div class='empty-state'><p>No agents found. Create your first agent to get started!</p></div>"
        } else {
            let agentCards = Array.foldLeft<Backend.Agent, Text>(agents, "", func(acc, agent) {
                acc # generateAgentCardHTML(agent)
            });
            "<div class='agents-grid'>" # agentCards # "</div>"
        }
    };

    private func generateAgentCardHTML(agent: Backend.Agent) : Text {
        let statusClass = agentStatusToClass(agent.status);
        let statusText = agentStatusToText(agent.status);
        let typeText = agentTypeToText(agent.agentType);
        
        "<div class='agent-card'>" #
        "<h3>" # agent.name # "</h3>" #
        "<p class='agent-description'>" # agent.description # "</p>" #
        "<p class='agent-type'>Type: " # typeText # "</p>" #
        "<span class='agent-status " # statusClass # "'>" # statusText # "</span>" #
        "<div class='agent-actions'>" #
        "<button class='btn btn-primary' onclick='updateAgentStatus(\"" # agent.id # "\", \"Active\")'>"
        # (if (agent.status == #Active) "Pause" else "Start") # "</button>" #
        "<button class='btn btn-secondary' onclick='editAgent(\"" # agent.id # "\")'>"
        # "Edit</button>" #
        "<button class='btn btn-danger' onclick='deleteAgent(\"" # agent.id # "\")'>"
        # "Delete</button>" #
        "</div>" #
        "</div>"
    };

    private func generateActivityHTML(activities: [ActivityItem]) : Text {
        if (activities.size() == 0) {
            "<div class='activity-section'><h2>Recent Activity</h2><p>No recent activity.</p></div>"
        } else {
            let activityItems = Array.foldLeft<ActivityItem, Text>(activities, "", func(acc, activity) {
                acc # "<div class='activity-item'>" #
                "<p>" # activity.action # "</p>" #
                "<span class='activity-time'>" # Int.toText(activity.timestamp) # "</span>" #
                "</div>"
            });
            "<div class='activity-section'><h2>Recent Activity</h2><div class='activity-list'>" # activityItems # "</div></div>"
        }
    };

    // Utility functions
    private func logActivity(action: Text, agentId: ?Text, description: Text) {
        let activityId = "activity_" # Nat.toText(nextActivityId);
        nextActivityId += 1;
        
        let activity: ActivityItem = {
            id = activityId;
            action = description;
            agentId = agentId;
            timestamp = Time.now();
            status = "completed";
        };
        
        activityLog.put(activityId, activity);
    };

    private func addNotification(message: Text, type_: Text) {
        let notificationId = "notification_" # Nat.toText(nextNotificationId);
        nextNotificationId += 1;
        
        let notification: NotificationItem = {
            id = notificationId;
            message = message;
            type_ = type_;
            timestamp = Time.now();
            isRead = false;
        };
        
        notifications.put(notificationId, notification);
    };

    private func getRecentActivity(limit: Nat) : [ActivityItem] {
        let activities = Iter.toArray(activityLog.vals());
        // Sort by timestamp (most recent first) and take limit
        Array.take(activities, limit)
    };

    private func agentStatusToText(status: Backend.AgentStatus) : Text {
        switch (status) {
            case (#Active) { "Active" };
            case (#Inactive) { "Inactive" };
            case (#Paused) { "Paused" };
            case (#Error) { "Error" };
            case (#Training) { "Training" };
            case (#Deployed) { "Deployed" };
        }
    };

    private func agentStatusToClass(status: Backend.AgentStatus) : Text {
        switch (status) {
            case (#Active) { "status-active" };
            case (#Inactive) { "status-inactive" };
            case (#Paused) { "status-paused" };
            case (#Error) { "status-error" };
            case (#Training) { "status-training" };
            case (#Deployed) { "status-deployed" };
        }
    };

    private func agentTypeToText(agentType: Backend.AgentType) : Text {
        switch (agentType) {
            case (#Conversational) { "Conversational" };
            case (#Analytical) { "Analytical" };
            case (#Creative) { "Creative" };
            case (#Assistant) { "Assistant" };
            case (#Specialized) { "Specialized" };
        }
    };

    private func userRoleToText(role: Backend.UserRole) : Text {
        switch (role) {
            case (#Admin) { "Administrator" };
            case (#Developer) { "Developer" };
            case (#User) { "User" };
        }
    };

    // Public query functions
    public query func getNotifications() : async [NotificationItem] {
        Iter.toArray(notifications.vals())
    };

    public query func getActivityLog(limit: ?Nat) : async [ActivityItem] {
        let activities = Iter.toArray(activityLog.vals());
        switch (limit) {
            case (?l) { Array.take(activities, l) };
            case null { activities };
        }
    };

    public query func healthCheck() : async { status: Text; timestamp: Int } {
        {
            status = "healthy";
            timestamp = Time.now();
        }
    };
}