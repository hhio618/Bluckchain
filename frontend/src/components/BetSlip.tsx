import React, { useState, useEffect } from "react";
import {
  Container,
  Typography,
  Box,
  Paper,
  List,
  ListItem,
  ListItemText,
} from "@mui/material";
import { makeStyles, createStyles } from "@mui/styles";
import { ethers } from "ethers"; // Ensure you have ethers to format the values

const useStyles = makeStyles(() =>
  createStyles({
    container: {
      marginTop: 20,
      display: "flex",
      flexDirection: "column",
      alignContent: "center",
    },
    paper: {
      padding: 20,
      width: "100%",
      maxWidth: 1200,
      backgroundColor: "#002b36",
      color: "#839496",
    },
  }),
);

interface BetSlip {
  id: string;
  amount: string; // assuming the amount is stored as a string representing ether (not wei)
  odds: number;
  potentialPayout: string;
}

const BetSlip: React.FC = () => {
  const classes = useStyles();
  const [betSlips, setBetSlips] = useState<BetSlip[]>([
    // Example bet slips
    { id: "1", amount: "0.01", odds: 1.5, potentialPayout: "0.015" },
    { id: "2", amount: "0.05", odds: 2.0, potentialPayout: "0.1" },
  ]);

  const formatEther = (value: string) => {
    return `${parseFloat(value).toFixed(5)} ETH`;
  };

  return (
    <Container className={classes.container}>
      <Typography variant="h4" gutterBottom>
        Bet Slips
      </Typography>
      <Paper className={classes.paper}>
        <Typography variant="body1">
          Here you can view all your bet slips.
        </Typography>
        <List>
          {betSlips.map((slip, index) => (
            <ListItem key={index}>
              <ListItemText
                primary={`Bet #${slip.id}`}
                secondary={`Amount: ${formatEther(slip.amount)} | Odds: ${
                  slip.odds
                } | Potential Payout: ${formatEther(slip.potentialPayout)}`}
              />
            </ListItem>
          ))}
        </List>
      </Paper>
    </Container>
  );
};

export default BetSlip;
