// src/components/SportBets.tsx
import React from "react";
import { Grid } from "@mui/material";
import BettingCard from "./BettingCard";

const SportBets: React.FC = () => {
  const bets = [
    { title: "Sport Bet 1", image: "https://via.placeholder.com/1280x720" },
    { title: "Sport Bet 2", image: "https://via.placeholder.com/1280x720" },
    // Add more bets as needed
  ];

  return (
    <Grid container spacing={3} direction="column">
      {bets.map((bet, index) => (
        <Grid item xs={12} key={index}>
          <BettingCard title={bet.title} image={bet.image} />
        </Grid>
      ))}
    </Grid>
  );
};

export default SportBets;
