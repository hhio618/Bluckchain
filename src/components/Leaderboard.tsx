// src/components/Leaderboard.tsx
import React, { useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Container,
  Typography,
  Box,
  Switch,
  FormControlLabel,
} from "@mui/material";
import { makeStyles, createStyles } from "@mui/styles";

const useStyles = makeStyles(() =>
  createStyles({
    container: {
      marginTop: 20,
    },
    table: {
      minWidth: 650,
      backgroundColor: "#002b36", // Background color from Solarized Dark
    },
    header: {
      backgroundColor: "#073642", // Header background color from Solarized Dark
      color: "#839496", // Text color from Solarized Dark
    },
    row: {
      color: "#839496", // Text color from Solarized Dark
    },
    switchContainer: {
      display: "flex",
      justifyContent: "flex-start",
      alignItems: "center",
      marginBottom: 10,
    },
    switchLabel: {
      color: "#839496", // Text color for the switch label
    },
  }),
);

interface LeaderboardEntry {
  rank: string;
  user: string;
  coin: string;
  wagered: number;
  prize: number;
}

const leaderboardData: LeaderboardEntry[] = [
  { rank: "1", user: "Alice", coin: "BTC", wagered: 120, prize: 1000 },
  { rank: "2", user: "Bob", coin: "ETH", wagered: 110, prize: 900 },
  { rank: "3", user: "Charlie", coin: "BTC", wagered: 105, prize: 850 },
  { rank: "4", user: "David", coin: "ETH", wagered: 95, prize: 800 },
  // Add more entries as needed
];

const rankToEmoji = (rank: string) => {
  switch (rank) {
    case "1":
      return "🥇";
    case "2":
      return "🥈";
    case "3":
      return "🥉";
    default:
      return rank;
  }
};

const Leaderboard: React.FC = () => {
  const classes = useStyles();
  const [showPrizeInUSD, setShowPrizeInUSD] = useState(false);

  const handlePrizeSwitch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setShowPrizeInUSD(event.target.checked);
  };

  const convertToUSD = (prize: number, coin: string) => {
    // Placeholder conversion rates, replace with real data as needed
    const conversionRates: { [key: string]: number } = {
      BTC: 30000,
      ETH: 2000,
    };
    return prize * conversionRates[coin];
  };

  return (
    <Container className={classes.container}>
      <Typography variant="h4" gutterBottom style={{ color: "#839496" }}>
        Leaderboard
      </Typography>
      <Box className={classes.switchContainer}>
        <FormControlLabel
          control={
            <Switch
              checked={showPrizeInUSD}
              onChange={handlePrizeSwitch}
              color="primary"
            />
          }
          label="Show Prize in USD"
          className={classes.switchLabel}
        />
      </Box>
      <TableContainer component={Paper}>
        <Table className={classes.table} aria-label="leaderboard table">
          <TableHead>
            <TableRow className={classes.header}>
              <TableCell>Rank</TableCell>
              <TableCell>User</TableCell>
              <TableCell>Coin</TableCell>
              <TableCell align="right">Wagered</TableCell>
              <TableCell align="right">
                Prize ({showPrizeInUSD ? "USD" : "Coin"})
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {leaderboardData.map((row) => (
              <TableRow key={row.rank}>
                <TableCell component="th" scope="row" className={classes.row}>
                  {rankToEmoji(row.rank)}
                </TableCell>
                <TableCell className={classes.row}>{row.user}</TableCell>
                <TableCell className={classes.row}>{row.coin}</TableCell>
                <TableCell align="right" className={classes.row}>
                  {row.wagered}
                </TableCell>
                <TableCell align="right" className={classes.row}>
                  {showPrizeInUSD
                    ? `$${convertToUSD(row.prize, row.coin).toLocaleString()}`
                    : row.prize}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Container>
  );
};

export default Leaderboard;
