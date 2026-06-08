# SRE Diagnostics Mode for Bob IDE

## Overview

The **SRE Diagnostics** mode is a specialized Bob IDE mode designed for Site Reliability Engineers to perform advanced diagnostics and troubleshooting using Instana observability platform integration. This mode leverages the Instana MCP (Model Context Protocol) server to provide real-time insights into application performance, infrastructure health, and incident analysis.

## Features

- **Real-time Monitoring**: Access live metrics and traces from your Instana-monitored applications
- **Incident Analysis**: Investigate and diagnose production issues with AI-assisted analysis
- **Performance Diagnostics**: Analyze application performance bottlenecks and resource utilization
- **Infrastructure Health**: Monitor and troubleshoot infrastructure components
- **Automated Insights**: Get AI-powered recommendations for resolving issues

## Prerequisites

Before using the SRE Diagnostics mode, ensure you have:

1. **Bob IDE** installed and configured
2. **Instana MCP Server** set up and running
3. **Instana Account** with appropriate access permissions
4. **API Credentials** for Instana integration

## Installation & Configuration

### 1. Install Instana MCP Server

Follow the official Instana MCP server setup guide:

**📚 [Instana MCP Server Configuration](https://github.com/instana/mcp-instana)**

The Instana MCP server provides the bridge between Bob IDE and your Instana observability platform, enabling seamless integration for diagnostics and monitoring.

### 2. Configure Bob IDE

1. Open Bob IDE settings
2. Navigate to **Modes** section
3. Enable **SRE Diagnostics** mode
4. Configure the Instana MCP server connection:
   - Server URL
   - API Token
   - Environment settings

### 3. Verify Connection

Test the connection to ensure Bob IDE can communicate with the Instana MCP server:

```bash
# Test MCP server connectivity
curl -X GET https://your-instana-mcp-server/health
```

## Usage

### Activating SRE Diagnostics Mode

1. Open Bob IDE
2. Click on the mode selector (usually in the bottom status bar or top toolbar)
3. Select **"SRE Diagnostics"** from the available modes
4. The mode will activate and connect to your Instana MCP server

### Common Use Cases

#### 1. Investigating Performance Issues

```
Ask Bob: "Analyze the performance of service X in the last hour"
```

Bob will query Instana metrics and provide insights on:
- Response times
- Error rates
- Resource utilization
- Dependency analysis

#### 2. Troubleshooting Incidents

```
Ask Bob: "What caused the spike in errors for application Y at 2:30 PM?"
```

Bob will:
- Retrieve relevant traces and logs
- Identify root causes
- Suggest remediation steps

#### 3. Infrastructure Health Checks

```
Ask Bob: "Check the health of our Kubernetes cluster"
```

Bob will provide:
- Node status
- Pod health
- Resource availability
- Recent events

#### 4. Dependency Analysis

```
Ask Bob: "Show me the service dependencies for microservice Z"
```

Bob will visualize:
- Upstream and downstream services
- Call patterns
- Latency between services

## Best Practices

1. **Context Matters**: Provide specific time ranges and service names for more accurate diagnostics
2. **Iterative Investigation**: Start broad and narrow down based on Bob's findings
3. **Combine with Logs**: Use Bob to correlate metrics with application logs
4. **Save Insights**: Document important findings for future reference
5. **Regular Health Checks**: Use the mode proactively to catch issues early

## Troubleshooting

### Connection Issues

If Bob cannot connect to Instana:

1. Verify MCP server is running
2. Check API credentials are valid
3. Ensure network connectivity
4. Review firewall rules

### Missing Data

If expected data is not available:

1. Confirm Instana agents are properly installed
2. Verify data retention policies
3. Check user permissions in Instana
4. Ensure the correct environment is selected

### Performance Issues

If queries are slow:

1. Narrow down time ranges
2. Be specific with service names
3. Check Instana API rate limits
4. Consider upgrading MCP server resources

## Support & Resources

- **Instana MCP Server**: [https://github.com/instana/mcp-instana](https://github.com/instana/mcp-instana)
- **Instana Documentation**: [https://www.ibm.com/docs/en/instana-observability](https://www.ibm.com/docs/en/instana-observability)
- **Bob IDE Documentation**: Check your Bob IDE help menu
- **Community Support**: Reach out to your SRE team or Instana support

## Sample Prompts & Examples

### Application Monitoring

#### Get Application KPIs
```
Can you get me the application KPIs for "americas-library-system"
```
Bob will retrieve and display key performance indicators including response times, throughput, error rates, and availability metrics.

#### List Services in Application
```
Show me services in application "americas-library-system"
```
Bob will list all microservices that are part of the application with their current status.

#### Check Service Health
```
What's the health of books-api and users-api service?
```
Bob will provide health status, current metrics, and any active alerts for the specified services.

### Error Analysis

#### Identify Error Sources
```
Which endpoint in books-api service is contributing most to errors?
```
Bob will analyze error distribution across endpoints and identify the top contributors.

#### View Failed Traces
```
Show failed traces for the books-api endpoints
```
Bob will retrieve and display recent failed request traces with detailed error information.

#### Monitor Error Rates
```
Show me error rates of the application "americas-library-system" over the last 10 minutes.
```
Bob will display time-series error rate data with trends and anomalies.

### Incident Management

#### List Open Issues
```
List open issues and incident of the application "americas-library-system"
```
Bob will show all active incidents, their severity, duration, and affected components.

#### Root Cause Analysis
```
Analyse the root cause of the issue checking pod logs
```
Bob will:
1. Retrieve relevant pod logs from Kubernetes
2. Correlate with Instana traces and metrics
3. Identify error patterns
4. Suggest probable root causes
5. Recommend remediation steps

### Additional Examples

#### Quick Health Check
```
User: "Give me a health summary of all production services"

Bob: [Queries Instana and provides]
- Service availability percentages
- Current error rates
- Top 5 slowest endpoints
- Recent alerts
```

#### Deep Dive Investigation
```
User: "The checkout service is slow. Help me find why."

Bob: [Performs analysis]
1. Retrieves recent traces for checkout service
2. Identifies database queries taking >2 seconds
3. Shows connection pool exhaustion
4. Recommends increasing pool size
5. Provides configuration examples
```

#### Capacity Planning
```
User: "What's our CPU utilization trend for the last week?"

Bob: [Analyzes metrics]
- Shows CPU usage graphs
- Identifies peak usage times
- Calculates growth rate
- Suggests scaling recommendations
```

## Security Considerations

- **API Keys**: Store Instana API keys securely, never commit to version control
- **Access Control**: Ensure proper RBAC is configured in Instana
- **Data Privacy**: Be mindful of sensitive data in traces and logs
- **Audit Logging**: Enable audit logs for compliance requirements

## Contributing

If you have suggestions for improving the SRE Diagnostics mode or encounter issues, please:

1. Document the issue with specific examples
2. Share with your SRE team
3. Consider contributing improvements to the Instana MCP server project

## License

This mode configuration follows your organization's internal licensing. The Instana MCP server has its own license terms - refer to the [official repository](https://github.com/instana/mcp-instana) for details.

---

**Happy Debugging! 🔍🚀**

*Last Updated: May 2026*