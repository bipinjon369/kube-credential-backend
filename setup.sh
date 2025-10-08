#!/bin/bash

set -e

echo "🚀 Setting up Kube Credential Backend..."

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Install service dependencies
echo "📦 Installing issuance service dependencies..."
cd services/issuance
npm install
cd ../..

echo "📦 Installing verification service dependencies..."
cd services/verification
npm install
cd ../..

# Create .env files from examples
echo "⚙️  Creating environment files..."
cp services/issuance/.env.example services/issuance/.env
cp services/verification/.env.example services/verification/.env

# Build services
echo "🔨 Building services..."
cd services/issuance
npm run build
cd ../verification
npm run build
cd ../..

echo "✅ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Start the database: docker-compose up -d postgres"
echo "   2. Start services: docker-compose up issuance verification"
echo "   3. Test endpoints:"
echo "      - Health: curl http://localhost:3001/health"
echo "      - Issue: curl -X POST http://localhost:3001/issuance/credentials -H 'Content-Type: application/json' -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"credentialType\":\"Developer Certificate\"}'"
echo ""