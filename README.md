<!--
title: 'AWS Simple HTTP Endpoint example in NodeJS'
description: 'This template demonstrates how to make a simple HTTP API with Node.js running on AWS Lambda and API Gateway using the Serverless Framework.'
layout: Doc
framework: v4
platform: AWS
language: nodeJS
authorLink: 'https://github.com/serverless'
authorName: 'Serverless, Inc.'
authorAvatar: 'https://avatars1.githubusercontent.com/u/13742415?s=200&v=4'
-->

# Save5Cents - Expense Tracking Application

A modern expense tracking application built with AWS Serverless architecture, featuring shared wallets, budget planning, and expense categorization.

## Features

- **Multi-Wallet Support**

  - Individual wallets
  - Shared wallets with multiple members
  - Role-based access control (Owner, Admin, Member)

- **Expense Management**

  - Track expenses by category
  - Support for multiple currencies
  - Credit card expense tracking with payment due dates
  - Recurring transactions

- **Budget Planning**

  - Category-based budgets
  - Individual and shared wallet budgets
  - Budget allocation for shared expenses
  - Budget tracking and monitoring

- **Income Tracking**

  - Multiple income sources
  - Income categorization
  - Recurring income support

- **Advanced Features**
  - Real-time notifications
  - Custom tags for expenses and incomes
  - Audit logging
  - User preferences

## Tech Stack

- **Backend**

  - AWS AppSync (GraphQL API)
  - AWS Lambda (Serverless Functions)
  - Amazon RDS (PostgreSQL)
  - Amazon Cognito (Authentication)

- **Frontend**
  - React
  - TypeScript
  - AWS Amplify

## Prerequisites

- Node.js (v14 or later)
- AWS CLI configured with appropriate credentials
- PostgreSQL (for local development)

## Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/save5cents.git
   cd save5cents
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Set up environment variables:

   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Run local development:
   ```bash
   npm run offline
   ```

## Development

- `npm run deploy` - Deploy to AWS
- `npm run offline` - Run locally
- `npm run test` - Run tests
- `npm run lint` - Run linting

## Project Structure

```
save5cents/
├── src/
│   ├── db/              # Database migrations and models
│   ├── graphql/         # GraphQL schema and resolvers
│   ├── functions/       # Lambda functions
│   └── utils/           # Utility functions
├── resources/           # AWS resources configuration
├── tests/              # Test files
└── scripts/            # Build and deployment scripts
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
