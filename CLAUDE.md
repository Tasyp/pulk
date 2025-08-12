# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is Pulk, a multiplayer Tetris 99-like game implemented as a learning playground for Elixir services. The project is an Elixir umbrella application with two main apps:

- `pulk`: Core game logic and business domain (backend)
- `pulk_web`: Phoenix web application with WebSocket channels and React frontend

## Development Commands

### Elixir Backend Commands (run from root)
- `mix setup` - Install dependencies and set up the project
- `mix format` - Format all Elixir code (runs format.all alias which includes JS formatting)
- `mix lint` - Run linting for both Elixir (format check + Credo) and frontend (ESLint + Prettier)
- `mix test` - Run all tests
- `iex -S mix phx.server` - Start interactive Elixir shell with Phoenix server

### Frontend Commands (run from apps/pulk_web/frontend)
- `yarn dev` - Start Vite development server
- `yarn build` - Build production frontend assets (TypeScript compilation + Vite build)
- `yarn lint` - Run ESLint and Prettier checks
- `yarn format` - Auto-format code with Prettier

### Development Workflow
- Start backend: `iex -S mix phx.server` (from root)
- Start frontend: `yarn dev` (from apps/pulk_web/frontend)
- The backend serves at http://localhost:4000, frontend dev server typically at http://localhost:5173

## Architecture

### Backend (Elixir/Phoenix)
The backend follows standard OTP supervision patterns:

**Core Supervision Tree:**
- `Pulk.Application` - Main supervisor with PubSub, Registry, GameSupervisor
- `Pulk.GameSupervisor` - Manages game room processes
- `Pulk.Registry` - Process registry for rooms and players

**Domain Entities:**
- `Pulk.Room` - Game room state with board size, player limits, game modes
- `Pulk.Player` - Player entity with unique IDs
- `Pulk.Board` - Tetris game board logic with piece placement and line clearing
- `Pulk.Piece` - Tetris pieces with rotations and positioning

**Key Modules:**
- `PulkWeb.RoomChannel` - WebSocket channel handling real-time game communication
- `Pulk.Room.RoomManager` - Room lifecycle management
- `Pulk.Player.PlayerManager` - Player state management

### Frontend (React/TypeScript)
- **Framework:** React 18 with Vite, TypeScript
- **Styling:** Styled Components + React95 theme (Windows 95 aesthetic)
- **Real-time:** Phoenix WebSocket channels for game state synchronization
- **State Management:** SWR for data fetching, React context for socket/player state
- **Routing:** Wouter for client-side routing

**Key Frontend Structure:**
- `src/lib/socket/` - Phoenix socket connection and channel management
- `src/containers/game_container/` - Main game UI orchestration
- `src/containers/tetris_field/` - Tetris game board rendering
- `src/lib/board/` - Board state utilities
- `src/lib/piece/` - Tetris piece logic and rendering

### Communication Flow
1. Players join rooms via WebSocket channels (`"room:{room_id}"`)
2. Real-time board updates sent through `PulkWeb.RoomChannel`
3. Game state synchronized between all players in the room
4. Frontend renders board snapshots and handles user input

### Type System
- Backend uses TypedStruct + Domo for compile-time type validation
- Frontend uses TypeScript with strict type checking
- Both sides validate data at boundaries (WebSocket JSON serialization)

## Testing
- Backend: `mix test` runs ExUnit tests
- Frontend: Tests configured but minimal coverage currently
- Integration testing happens through WebSocket channel tests

## Build Process
- Frontend assets built with `yarn build` and integrated into Phoenix static assets
- Production deployment uses Mix releases
- Assets are digested and served through Phoenix static plug