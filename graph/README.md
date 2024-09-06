To enable querying for the various statistics and data points related to your Prediction Market subgraph using The Graph, you'll need to define a set of queries in your GraphQL schema. Below are the necessary queries to retrieve the information you specified:

1. Get Top Share Holders for a Market

```graphql
query GetTopShareHoldersForMarket($marketId: ID!, $limit: Int!) {
  users(
    where: { markets_contains: $marketId }
    orderBy: totalLocked
    orderDirection: desc
    first: $limit
  ) {
    id
    totalLocked
  }
}
```

2. Get Market Order Activity

```graphql
query GetMarketOrderActivity($marketId: ID!) {
  orders(
    where: { market: $marketId }
    orderBy: timestamp
    orderDirection: desc
  ) {
    id
    trader
    outcome
    share
    price
    isBuy
    isLimit
    timestamp
  }
}
```

3. Get Order Activity for a User

```graphql
query GetOrderActivityForUser($userId: ID!) {
  orders(where: { trader: $userId }, orderBy: timestamp, orderDirection: desc) {
    id
    market {
      id
    }
    outcome
    share
    price
    isBuy
    isLimit
    timestamp
  }
}
```

4. Get All Volume Traded by a User

```graphql
query GetVolumeTradedByUser($userId: ID!) {
  user(id: $userId) {
    volumeTraded
  }
}
```

5. Get All Volume for Unsettled Orders for a User

```graphql
query GetUnsettledVolumeForUser($userId: ID!) {
  user(id: $userId) {
    unsettledVolume
  }
}
```

6. Get All Profit for a User from Settled Markets

```graphql
query GetProfitForUserFromSettledMarkets($userId: ID!) {
  user(id: $userId) {
    profit
  }
}
```

7. Get All Potential Profit for Current Positions (Shares)

```graphql
query GetPotentialProfitForUser($userId: ID!) {
  user(id: $userId) {
    potentialProfit
  }
}
```

8. List All Bet History Records for All Markets

```graphql
query ListAllBetHistoryRecords {
  bets(orderBy: timestamp, orderDirection: desc) {
    id
    user {
      id
    }
    market {
      id
    }
    valueIn
    valueOut
    profit
    loss
    timestamp
  }
}
```

9. Get Top Share Holders Across All Markets

```graphql
query GetTopShareHoldersAcrossAllMarkets($limit: Int!) {
  users(orderBy: totalLocked, orderDirection: desc, first: $limit) {
    id
    totalLocked
  }
}
```

10. Get Top Volume Traded Across All Markets

```graphql
query GetTopVolumeTradedAcrossAllMarkets($limit: Int!) {
  users(orderBy: volumeTraded, orderDirection: desc, first: $limit) {
    id
    volumeTraded
  }
}
```

11. Get Top Profitable Users Across All Markets

```graphql
query GetTopProfitableUsersAcrossAllMarkets($limit: Int!) {
  users(orderBy: profit, orderDirection: desc, first: $limit) {
    id
    profit
  }
}
```

## Explanation of Queries

Top Share Holders: This query lists users who have locked the most value in a particular market.
Market Order Activity: Fetches all orders for a given market, sorted by timestamp.
Order Activity for a User: Retrieves all orders placed by a specific user.
Volume Traded by a User: Provides the total volume a user has traded across all markets.
Volume for Unsettled Orders: Shows the volume of orders that are still unsettled for a specific user.
Profit from Settled Markets: Retrieves the total profit a user has made from settled markets.
Potential Profit: Estimates potential profit for current shares based on market odds.
Bet History Records: Lists all bets across all markets with detailed financial outcomes.
Top Share Holders Across All Markets: Finds users with the highest total value locked across all markets.
Top Volume Traded Across All Markets: Identifies users who have traded the highest volume across all markets.
Top Profitable Users Across All Markets: Determines users who have made the most profit across all markets.
These queries provide a comprehensive overview of user activities, market dynamics, and individual performance across your prediction markets, offering the insights needed to build an engaging and transparent interface for users.
