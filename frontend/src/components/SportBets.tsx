import React, { useState, useEffect } from "react";
import { Grid, Tab, Tabs, Box } from "@mui/material";
import BettingCard from "./BettingCard";
import {
  useWeb3ModalProvider,
  useWeb3ModalAccount,
} from "@web3modal/ethers/react";
import { ethers, BrowserProvider, Contract } from "ethers";
import predictionMarketAbi from "../contracts/PredictionMarket.json";
import { contractAddress } from "../contracts/contract-address";
import { formatBets } from "./utils";

interface BetOption {
  optionId: string;
  label: string;
  odds: number;
  cryptoIconUrl: string;
}

interface Bet {
  id: string;
  title: string;
  description: string;
  options: BetOption[];
  image: string;
  status: "ongoing" | "closed";
  totalBets: string; // Representing as string to handle big numbers safely
  totalUniqueUsers: number;
}

interface Market {
  id: number;
  settled: boolean;
  outcomes: any[];
}

const SportBets: React.FC = () => {
  const [tabValue, setTabValue] = useState<number>(0);
  const [bets, setBets] = useState<Bet[]>([]);
  const { address, chainId, isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  useEffect(() => {
    const fetchBets = async () => {
      if (!walletProvider || !isConnected) {
        console.log("Please connect to a wallet.");
        return;
      }

      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();
      const contract = new Contract(
        contractAddress.PredictionMarket,
        predictionMarketAbi.abi,
        signer,
      );

      try {
        const [marketIds, descriptions, outcomes, totalBets, totalUniqueUsers] =
          await contract.getMarkets(tabValue === 1);

        const marketPromises = marketIds.map(
          async (id: number, idx: number) => {
            // Explicitly type 'id' as number
            const odds = (await contract.calculateMarketOdds(1)) as number[];
            console.log("odds: ", odds.length);
            return {
              id: id.toString(),
              title: `Market ${id}`,
              description: descriptions[idx],
              image: "https://via.placeholder.com/1280x720",
              status: tabValue === 1 ? "closed" : "ongoing",
              options: outcomes[idx].map(
                (outcome: string, outcomeIdx: number) => ({
                  // Added explicit types for outcome and outcomeIdx
                  optionId: `${id}`,
                  label: outcome,
                  odds: parseFloat(odds[outcomeIdx].toString()),
                  cryptoIconUrl: "https://via.placeholder.com/50",
                }),
              ),
              totalBets: ethers.formatEther(totalBets[idx]).toString(), // Converting to ether for readability
              totalUniqueUsers: totalUniqueUsers[idx].toString(),
            } as Bet;
          },
        );
        const fetchedBets = await Promise.all(marketPromises);
        setBets(fetchedBets);
      } catch (error) {
        console.error("Error fetching markets and odds:", error);
      }
    };

    fetchBets();
  }, [tabValue, walletProvider, isConnected]);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Box sx={{ width: "100%" }}>
      <Tabs
        value={tabValue}
        onChange={handleTabChange}
        aria-label="sports bets tabs"
      >
        <Tab label="Ongoing" />
        <Tab label="Closed" />
      </Tabs>
      <Grid container spacing={3}>
        {bets.map((bet) => (
          <Grid item xs={12} sm={6} md={4} key={bet.id}>
            <BettingCard
              id={bet.id}
              title={bet.title}
              description={bet.description}
              options={bet.options}
              totalBets={formatBets(bet.totalBets)}
              totalUniqueUsers={bet.totalUniqueUsers.toString()}
            />
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default SportBets;
