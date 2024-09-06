#!/bin/bash

# Enable command output
set -x

# Check if required commands are available
if ! command -v forge &>/dev/null || ! command -v cast &>/dev/null; then
        echo "Forge and Cast are required but not installed. Exiting."
        exit 1
fi

# Input arguments
RPC_URL=${1:-http://127.0.0.1:8545}
MNEMONIC=${2}
PRIVATE_KEY=${3}

# Check if all necessary arguments are provided
if [ -z "$MNEMONIC" ] && [ -z "$PRIVATE_KEY" ]; then
        echo "You must provide either a mnemonic or a private key. Exiting."
        exit 1
fi

# Set the account argument for forge commands
if [ -n "$MNEMONIC" ]; then
        ACCOUNT_ARG="--mnemonic \"$MNEMONIC\""
else
        ACCOUNT_ARG="--private-key \"$PRIVATE_KEY\""
fi

# Forge build
forge build

# Deploy BLUCKToken contract
echo "Deploying BLUCKToken contract..."
BLUCK_TOKEN_DEPLOY_CMD="forge create $ACCOUNT_ARG --rpc-url $RPC_URL src/BLUCKToken.sol:BLUCKToken --json"
BLUCK_TOKEN_DEPLOY_OUTPUT=$(eval "$BLUCK_TOKEN_DEPLOY_CMD")
BLUCK_TOKEN_ADDRESS=$(echo "$BLUCK_TOKEN_DEPLOY_OUTPUT" | jq -r '.deployedTo')
echo "BLUCKToken contract deployed at: $BLUCK_TOKEN_ADDRESS"

# Deploy EventOracle contract
echo "Deploying EventOracle contract..."
EVENT_ORACLE_DEPLOY_CMD="forge create $ACCOUNT_ARG --rpc-url $RPC_URL src/EventOracle.sol:EventOracle --json"
EVENT_ORACLE_DEPLOY_OUTPUT=$(eval "$EVENT_ORACLE_DEPLOY_CMD")
EVENT_ORACLE_ADDRESS=$(echo "$EVENT_ORACLE_DEPLOY_OUTPUT" | jq -r '.deployedTo')
echo "EventOracle contract deployed at: $EVENT_ORACLE_ADDRESS"

# Deploy PredictionMarket contract with zero address as third constructor argument
echo "Deploying PredictionMarket contract..."
PREDICTION_MARKET_DEPLOY_CMD="forge create $ACCOUNT_ARG --rpc-url $RPC_URL src/PredictionMarket.sol:PredictionMarket --constructor-args $EVENT_ORACLE_ADDRESS $BLUCK_TOKEN_ADDRESS 0x0000000000000000000000000000000000000000 --json"
PREDICTION_MARKET_DEPLOY_OUTPUT=$(eval "$PREDICTION_MARKET_DEPLOY_CMD")
PREDICTION_MARKET_ADDRESS=$(echo "$PREDICTION_MARKET_DEPLOY_OUTPUT" | jq -r '.deployedTo')
echo "PredictionMarket contract deployed at: $PREDICTION_MARKET_ADDRESS"

# Create Event #1
EVENT_DESCRIPTION="Test Event 1"
END_TIME=$(date +%s --date="tomorrow") # 24 hours from now
OUTCOME_NAMES='["Outcome 1", "Outcome 2"]'

# Command to create event
echo "Creating event #1..."
eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $EVENT_ORACLE_ADDRESS 'createEvent(string,uint256,string[])' '$EVENT_DESCRIPTION' $END_TIME '$OUTCOME_NAMES'"

OWNER_ADDRESS=$(eval "cast wallet address $ACCOUNT_ARG")
eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $BLUCK_TOKEN_ADDRESS 'mint(address,uint256)' $OWNER_ADDRESS 1000ether"
eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $BLUCK_TOKEN_ADDRESS 'approve(address,uint256)' $PREDICTION_MARKET_ADDRESS 1000ether"

# Function to create market and add orders
function create_and_seed_market {
        eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $PREDICTION_MARKET_ADDRESS 'createMarket(uint256)' 1"
        MARKET_ID=$(eval "cast call $ACCOUNT_ARG --rpc-url $RPC_URL $PREDICTION_MARKET_ADDRESS 'marketCount()(uint256)'")

        # Create users and distribute tokens
        for USER_ID in {1..30}; do
                USER_JSON=$(cast wallet new --json | jq '.[0]')
                USER_PRIVATE_KEY=$(echo "$USER_JSON" | jq -r '.private_key')
                USER_ADDRESS=$(echo "$USER_JSON" | jq -r '.address')
                eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $USER_ADDRESS --value 10ether"
                eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $BLUCK_TOKEN_ADDRESS 'mint(address,uint256)' $USER_ADDRESS 1000ether"
                eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $BLUCK_TOKEN_ADDRESS 'approve(address,uint256)' $PREDICTION_MARKET_ADDRESS 1000ether"

                # Randomly select outcome and amount for swaps and market orders
                OUTCOME=$((RANDOM % 2))
                SWAP_AMOUNT=$((RANDOM % 10 + 1))ether
                ORDER_AMOUNT=$((RANDOM % 10 + 1))ether

                # Use awk to generate a normal distribution around a central value (50)
                ORDER_PRICE=$(awk -v mean=50 -v stddev=10 'BEGIN{srand(); x1=rand(); x2=rand(); print int(mean + stddev * sqrt(-2*log(x1))*cos(2*3.14159*x2))}')

                # Ensure ORDER_PRICE stays within the bounds of 1 and 100
                if [ "$ORDER_PRICE" -lt 1 ]; then
                        ORDER_PRICE=1
                elif [ "$ORDER_PRICE" -gt 100 ]; then
                        ORDER_PRICE=100
                fi

                # Perform swap to ensure sufficient shares for selling
                echo "User $USER_ADDRESS swapping $SWAP_AMOUNT for outcome $OUTCOME in market $MARKET_ID..."
                cast send --private-key "$USER_PRIVATE_KEY" --rpc-url $RPC_URL $PREDICTION_MARKET_ADDRESS "swap(uint256,uint256,uint256)" $MARKET_ID $OUTCOME $SWAP_AMOUNT

                # Place market orders
                IS_BUY=$((RANDOM % 2)) # Randomly decide buy (1) or sell (0)
                IS_BUY_STRING=$([ "$IS_BUY" = 1 ] && echo "true" || echo "false")
                echo "User $USER_ADDRESS placing market order of $ORDER_AMOUNT with price $ORDER_PRICE for outcome $OUTCOME in market $MARKET_ID..."
                cast send --private-key "$USER_PRIVATE_KEY" --rpc-url $RPC_URL $PREDICTION_MARKET_ADDRESS "placeLimitOrder(uint256,uint256,uint256,uint256,bool)" $MARKET_ID $OUTCOME $ORDER_AMOUNT $ORDER_PRICE $IS_BUY_STRING
        done
}

# Seed multiple markets
for i in {1..5}; do
        create_and_seed_market $i
done

# Settle the event before settling the market
for i in {1..3}; do
        eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $EVENT_ORACLE_ADDRESS 'settleEvent(uint256,uint256)' $i 0"
        eval "cast send $ACCOUNT_ARG --rpc-url $RPC_URL $PREDICTION_MARKET_ADDRESS 'settleMarket(uint256)' $i"
done

# Echo PredictionMarket contract address
echo "PredictionMarket contract address: $PREDICTION_MARKET_ADDRESS"

echo "Seeding completed. Markets, orders, and users have been created."
