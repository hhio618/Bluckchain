import React, { useState } from "react";
import { Grid, Tab, Tabs, Box } from "@mui/material";
import BettingCard from "./BettingCard";

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
}

const SportBets: React.FC = () => {
  const [tabValue, setTabValue] = useState<number>(0);

  const bets: Bet[] = [
    {
      id: "1",
      title: "Sport Bet 1",
      description: "Bet on the winning team!",
      image: "https://via.placeholder.com/1280x720",
      status: "ongoing",
      options: [
        {
          optionId: "1a",
          label: "Team A",
          odds: 1.5,
          cryptoIconUrl: "https://via.placeholder.com/50",
        },
        {
          optionId: "1b",
          label: "Team B",
          odds: 2.0,
          cryptoIconUrl: "https://via.placeholder.com/50",
        },
      ],
    },
    {
      id: "2",
      title: "Sport Bet 2",
      description: "Bet on the best player!",
      image: "https://via.placeholder.com/1280x720",
      status: "closed",
      options: [
        {
          optionId: "2a",
          label: "Player X",
          odds: 1.8,
          cryptoIconUrl: "https://via.placeholder.com/50",
        },
        {
          optionId: "2b",
          label: "Player Y",
          odds: 2.2,
          cryptoIconUrl: "https://via.placeholder.com/50",
        },
      ],
    },
    // Add more bets as needed
  ];

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
        {bets
          .filter(
            (bet) =>
              (tabValue === 0 && bet.status === "ongoing") ||
              (tabValue === 1 && bet.status === "closed"),
          )
          .map((bet) => (
            <Grid item xs={12} sm={6} md={4} key={bet.id}>
              <BettingCard
                id={bet.id}
                title={bet.title}
                description={bet.description}
                options={bet.options}
                imageUrl={bet.image}
              />
            </Grid>
          ))}
      </Grid>
    </Box>
  );
};

export default SportBets;
