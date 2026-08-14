# Pharmacy Web Dashboard

Web-based dashboard for the Smart Healthcare System pharmacy module.

## Tech Stack

- **React** — UI library
- **TypeScript** — Type safety
- **Vite** — Build tool and dev server

## Getting Started

### Prerequisites

- Node.js (v18 or later)
- npm

### Installation

```bash
cd web_dashboard
npm install
```

### Development

```bash
npm run dev
```

The dev server will start at `http://localhost:5173`.

### Production Build

```bash
npm run build
```

The output will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Project Structure

```
web_dashboard/
├── public/                 # Static assets
├── src/
│   ├── assets/             # Images, fonts, etc.
│   ├── components/         # Reusable UI components
│   ├── pages/              # Page-level components
│   ├── layouts/            # Layout wrappers
│   ├── routes/             # Route definitions
│   ├── services/           # API service layers
│   ├── hooks/              # Custom React hooks
│   ├── contexts/           # React context providers
│   ├── types/              # TypeScript type definitions
│   ├── utils/              # Utility functions
│   ├── config/             # App configuration
│   ├── App.tsx             # Root component
│   ├── main.tsx            # Entry point
│   └── index.css           # Global styles
├── .env.example            # Environment variable template
├── index.html              # HTML entry point
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
└── vite.config.ts
```

## Environment Variables

Copy `.env.example` to `.env` and configure the required values:

```bash
cp .env.example .env
```
