# Reactive Network Cross-Chain Governance

## Overview

In a prediction market where the price of an outcome is based on the proportion of bets placed, the price will increase if more bets are placed on that outcome. This is because the price reflects the likelihood of an outcome, which is inferred from the amount of money bet on it. Here's a detailed explanation of how this works:

Concept
Market Dynamics:

The price of an outcome in a prediction market can be understood as a reflection of the market's perceived probability of that outcome occurring.
If many people bet on a particular outcome, it signals that they believe it is more likely to occur. This increased demand drives up the price of that outcome.
Price Calculation:

The price of an outcome is calculated as the proportion of total bets placed on that outcome.
If more bets are placed on an outcome, its price will increase because it represents a larger share of the total betting pool.
Example
Suppose there are two outcomes in a market, Outcome A and Outcome B. If the total amount of money bet is 100 ETH, and 60 ETH is bet on Outcome A, while 40 ETH is bet on Outcome B, the prices might be calculated as follows:

Price of Outcome A:
60
100
=
0.60
100
60
​
=0.60
Price of Outcome B:
40
100
=
0.40
100
40
​
=0.40
This is a simple workflow demonstrating catching an update event from an Oracle on the original chain and update the destination oracle on the destination chain.
Key concepts:

- Low-latency monitoring of governance request events emitted by arbitrary contracts in the L1 Network (Sepolia testnet in this case).
- Calls from Reactive Network to L1 Governance contracts.

```mermaid
%%{ init: { 'flowchart': { 'curve': 'basis' } } }%%
flowchart TB
    subgraph RN["Reactive Network"]
        subgraph RV["ReactVM"]
            subgraph RC["Reactive Contract"]
                RGR("ReGovReactive")
            end
        end
    end
    subgraph L1["L1 Network"]
        subgraph OCC["Origin Chain Contract"]
            RGE("OrgOracle")
        end
        subgraph DCC["Destination Chain Contract"]
            RGL1("DestOracle")
        end
    end

OCC -. emitted DataUpdated .-> RGR
RGR -. callback .-> DCC

style RV stroke:transparent
```

In practical terms, this general use case can be applicable in any number of scenarios, from simple stop orders to fully decentralized algorithmic trading.

There are three main contracts involved in this scenario:

- Origin chain contract.
- Reactive contract.
- Destination chain contract.

### Origin Chain Contract

This contract, or set of contracts, presumably emits logs of interest to the Reactive Network user. In financial applications, this could be a DEX, such as a Uniswap pool, emitting data on trades and/or exchange rates. Typically, the contract is controlled by a third party; otherwise, mediation by Reactive Network would be unnecessary.

Here, this contract is implemented in OrgOracle.sol. Its functionality is to store the oracle data and emit the corresponding events on update.

## Reactive Contract

Reactive contracts implement the logic of event monitoring and initiating calls back to L1 chains. These contracts are fully-fledged EVM contracts with the ability to maintain state persistence, subscribe/unsubscribe to multiple event origins, and perform callbacks. This can be done both statically and dynamically by emitting specialized log records, which specify the parameters of a transaction to be submitted to the destination chain.

Reactive contracts are executed in a private subnet (ReactVM) tied to a specific deployer address. This limitation enhances their ability to scale, although it restricts their interaction with other reactive contracts.

In our demo, the reactive contract implemented in OracleReactive.sol subscribes to update events emitted by OrgOracle.sol upon deployment. Whenever the observed contract reports a governance decision requiring execution, the reactive contract initiates an authorized L1 callback by emitting a log record with the necessary transaction parameters and payload to ensure proper execution on the destination network.

## Destination Chain Contract

The DestOracle.sol is the L1 part of the governance logic. The governance contract listens to the update events and call the update function on the destination network.

## Deployment

### Prerequisites

Ensure you have the following environment variables set up:

```
export SEPOLIA_RPC="<YOUR_SEPOLIA_RPC_URL>"
export SEPOLIA_PRIVATE_KEY="<YOUR_SEPOLIA_PRIVATE_KEY>"
export REACTIVE_RPC="<YOUR_REACTIVE_RPC_URL>"
export REACTIVE_PRIVATE_KEY="<YOUR_REACTIVE_PRIVATE_KEY>"
export SYSTEM_CONTRACT_ADDR="<YOUR_SYSTEM_CONTRACT_ADDR>"
```

### Deploy the Contracts

First, deploy the origin contract to Sepolia:

```
forge create --rpc-url $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY src/EventOracle.sol:EventOracle # deployed to 0x979EEa9893304d2584291b59e6bAA1EB624f2220
```

Assign the deployment address to the environment variable ORIGIN_ADDR.

Now deploy the destination contract to Sepolia (Here, the AUTHORIZED_CALLER_ADDRESS should contain the address you intend to authorize for performing callbacks or use 0x0000000000000000000000000000000000000000 to skip this check):

```
forge create --rpc-url $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY src/PredictionMarket.sol:PredictionMarket --constructor-args $ORACLE_ADDRESS $AUTHORIZED_CALLER_ADDRESS
```

Assign the deployment address to the environment variable `CALLBACK_ADDR`.

Finally, deploy the reactive contract, configuring it to send callbacks
to `CALLBACK_ADDR`.

```
forge create --rpc-url $REACTIVE_RPC --private-key $REACTIVE_PRIVATE_KEY src/demos/cross-chain-oracle/OracleReactive.sol:OracleReactive --constructor-args $SYSTEM_CONTRACT_ADDR $CALLBACK_ADDR # deployed at 0xc6F237C2ED2434aF698CeE205A2C158E9E118B77
```

## Testing the workflow

Test the whole setup by emitting an DataUpdated event from the origin chain:

````
cast send $ORACLE_ADDRESS 'createEvent(string,uint256,string[])' --rpc-url $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY 'Test event' $((`date +%s`+86400)) '["Outcome1", "Outcome2"]'  ```

After a few moments, the ReactVM calls on the callback contract, and we will have the updated data on the destination oracle:

```
```
cast send $PM_ADDRESS 'createMarket(uint256)' --rpc-url "http://127.0.0.1:8545" --mnemonic $MNEMONIC 1

```
Get the market details:
```
cast call $PM_ADDRESS 'getMarketDetails(uint256)' --rpc-url "http://127.0.0.1:8545"  --mnemonic $MNEMONIC 1
```
````
