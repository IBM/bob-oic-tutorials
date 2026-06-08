# Library System Architecture

## System Overview

This document describes the architecture of the Library System application, including its monitoring infrastructure with Instana and the application layer components.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          INSTANA MONITORING LAYER                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌──────────────┐         ┌──────────────┐         ┌──────────────┐        │
│  │  Instana UI  │         │ Instana MCP  │         │   Instana    │        │
│  │              │         │    Server    │         │    Agent     │        │
│  │  (Web-based  │         │              │         │              │        │
│  │  Dashboard)  │         │  (MCP Tools) │         │ (Monitoring) │        │
│  └──────┬───────┘         └──────┬───────┘         └──────┬───────┘        │
│         │                        │                        │                 │
│         │                        │                        │                 │
│         └────────────────────────┼────────────────────────┘                 │
│                                  │                                          │
│                                  ▼                                          │
│                     ┌─────────────────────────┐                            │
│                     │   INSTANA BACKEND       │                            │
│                     │                         │                            │
│                     │  - Data Collection      │                            │
│                     │  - Analytics Engine     │                            │
│                     │  - Alert Management     │                            │
│                     │  - Metrics Storage      │                            │
│                     └────────────┬────────────┘                            │
│                                  │                                          │
└──────────────────────────────────┼──────────────────────────────────────────┘
                                   │
                                   │ Monitors
                                   │
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                          APPLICATION LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  ┌────────────────────────────────────────────────────────────┐             │
│  │                        Web UI                               │             │
│  │                                                             │             │
│  │  Technology: Node.js + Express                             │             │
│  │  Port: 3000                                                │             │
│  │  Purpose: Frontend interface for library management       │             │
│  └────────────┬───────────────────────────┬───────────────────┘             │
│               │                           │                                  │
│               │                           │                                  │
│               ▼                           ▼                                  │
│  ┌─────────────────────┐     ┌─────────────────────┐                       │
│  │    Books API        │     │    Users API        │                       │
│  │                     │     │                     │                       │
│  │  Technology:        │     │  Technology:        │                       │
│  │  - Python           │     │  - Python           │                       │
│  │  - Flask            │     │  - Flask            │                       │
│  │  Port: 5000         │     │  Port: 5001         │                       │
│  │                     │     │                     │                       │
│  │  Endpoints:         │     │  Endpoints:         │                       │
│  │  - GET /books       │     │  - GET /users       │                       │
│  │  - POST /books      │     │  - POST /users      │                       │
│  │  - GET /books/:id   │     │  - GET /users/:id   │                       │
│  │  - PUT /books/:id   │     │  - PUT /users/:id   │                       │
│  │  - DELETE /books/:id│     │  - DELETE /users/:id│                       │
│  └──────────┬──────────┘     └──────────┬──────────┘                       │
│             │                           │                                   │
│             │                           │                                   │
│             └───────────┬───────────────┘                                   │
│                         │                                                   │
│                         ▼                                                   │
│              ┌─────────────────────┐                                        │
│              │      MongoDB        │                                        │
│              │                     │                                        │
│              │  Technology:        │                                        │
│              │  - NoSQL Database   │                                        │
│              │  Port: 27017        │                                        │
│              │                     │                                        │
│              │  Collections:       │                                        │
│              │  - books            │                                        │
│              │  - users            │                                        │
│              └─────────────────────┘                                        │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### Monitoring Layer (Instana)

#### 1. **Instana UI**
- **Purpose**: Web-based dashboard for visualizing application performance and infrastructure metrics
- **Features**:
  - Real-time monitoring dashboards
  - Application performance metrics
  - Infrastructure visualization
  - Alert management interface
  - Trace analysis

#### 2. **Instana MCP Server**
- **Purpose**: Model Context Protocol server providing programmatic access to Instana capabilities
- **Features**:
  - Infrastructure analysis tools
  - Application management
  - Event monitoring
  - SLO management
  - Website monitoring
  - Custom dashboard creation
  - Automation actions

#### 3. **Instana Agent**
- **Purpose**: Lightweight monitoring agent deployed alongside applications
- **Features**:
  - Automatic discovery of application components
  - Metrics collection
  - Distributed tracing
  - Log collection
  - Real-time data streaming to Instana backend

#### 4. **Instana Backend**
- **Purpose**: Central processing and storage system
- **Components**:
  - Data collection and aggregation
  - Analytics engine
  - Alert management system
  - Metrics storage and retrieval
  - API gateway

### Application Layer

#### 1. **Web UI**
- **Technology**: Node.js with Express framework
- **Port**: 3000
- **Purpose**: Frontend interface for library management system
- **Features**:
  - User interface for browsing books
  - User management interface
  - Integration with Books API and Users API
- **Dependencies**: 
  - Express.js for server framework
  - HTTP client for API communication

#### 2. **Books API**
- **Technology**: Python with Flask framework
- **Port**: 5000
- **Purpose**: RESTful API for book management
- **Endpoints**:
  - `GET /books` - List all books
  - `POST /books` - Create new book
  - `GET /books/:id` - Get book details
  - `PUT /books/:id` - Update book
  - `DELETE /books/:id` - Delete book
- **Database**: MongoDB (books collection)

#### 3. **Users API**
- **Technology**: Python with Flask framework
- **Port**: 5001
- **Purpose**: RESTful API for user management
- **Endpoints**:
  - `GET /users` - List all users
  - `POST /users` - Create new user
  - `GET /users/:id` - Get user details
  - `PUT /users/:id` - Update user
  - `DELETE /users/:id` - Delete user
- **Database**: MongoDB (users collection)

#### 4. **MongoDB**
- **Technology**: NoSQL document database
- **Port**: 27017
- **Purpose**: Persistent data storage
- **Collections**:
  - `books` - Stores book information
  - `users` - Stores user information

## Data Flow

1. **User Interaction**: Users interact with the Web UI through a browser
2. **API Requests**: Web UI makes HTTP requests to Books API and Users API
3. **Data Processing**: APIs process requests and interact with MongoDB
4. **Data Storage**: MongoDB stores and retrieves data
5. **Monitoring**: Instana Agent monitors all components and sends data to Instana Backend
6. **Visualization**: Instana UI displays metrics and traces from Instana Backend
7. **Automation**: Instana MCP Server provides programmatic access to monitoring data and controls

## Deployment

The application is containerized using Docker and can be deployed to Kubernetes:
- Each component runs in its own container
- Kubernetes manifests available in `k8s-manifests/all-in-one.yaml`
- Instana Agent deployed as DaemonSet for comprehensive monitoring

## Technology Stack Summary

| Component | Technology | Language | Port |
|-----------|-----------|----------|------|
| Web UI | Node.js + Express | JavaScript | 3000 |
| Books API | Flask | Python | 5000 |
| Users API | Flask | Python | 5001 |
| Database | MongoDB | N/A | 27017 |
| Monitoring | Instana | N/A | Various |

## Monitoring Integration

The Instana monitoring layer provides:
- **Automatic Discovery**: Detects all application components
- **Distributed Tracing**: Tracks requests across Web UI → APIs → MongoDB
- **Performance Metrics**: CPU, memory, response times, error rates
- **Custom Dashboards**: Visualize application-specific metrics
- **Alerting**: Proactive notification of issues
- **SLO Tracking**: Monitor service level objectives