import React, { useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  Box,
  Grid,
  Tab,
  Tabs,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Typography,
  Button,
  IconButton,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import BettingCard from "./BettingCard";

interface BetOption {
  optionId: string;
  label: string;
  odds: number;
  cryptoIconUrl: string; // Each bet option might have a different crypto associated
}

interface BetDetails {
  user: string;
  time: string;
  odds: number;
  amount: number;
}

interface FeaturedBet {
  title: string;
  image: string;
  description: string;
  options: BetOption[];
}

const BetInfo: React.FC = () => {
  const [tabValue, setTabValue] = useState<number>(0);
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

  // Guard clause to handle undefined id
  if (!id) {
    return <Typography variant="h6">No bet selected</Typography>;
  }

  const featuredBet: FeaturedBet = {
    title: `Bet Details for ID: ${id}`,
    description: "Detailed information about the bet.",
    image: "https://via.placeholder.com/1280x720",
    options: [
      {
        optionId: "1a",
        label: "Option A",
        odds: 2.0,
        cryptoIconUrl: "https://via.placeholder.com/50",
      },
      {
        optionId: "1b",
        label: "Option B",
        odds: 3.0,
        cryptoIconUrl: "https://via.placeholder.com/50",
      },
    ],
  };

  const allBets: BetDetails[] = [
    { user: "User1", time: "10:00", odds: 1.5, amount: 100 },
    { user: "User2", time: "10:30", odds: 1.8, amount: 150 },
  ];

  const topBets: BetDetails[] = [
    { user: "User2", time: "10:30", odds: 1.8, amount: 150 },
  ];

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const renderTable = (bets: BetDetails[]) => (
    <TableContainer component={Paper}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>User</TableCell>
            <TableCell align="right">Time</TableCell>
            <TableCell align="right">Odds</TableCell>
            <TableCell align="right">Bet Amount</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {bets.map((bet, index) => (
            <TableRow key={index}>
              <TableCell component="th" scope="row">
                {bet.user}
              </TableCell>
              <TableCell align="right">{bet.time}</TableCell>
              <TableCell align="right">{bet.odds}</TableCell>
              <TableCell align="right">{bet.amount}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );

  const handleBack = () => {
    navigate("/dapp/sport-events");
  };

  return (
    <Box sx={{ flexGrow: 1 }}>
      <IconButton
        onClick={handleBack}
        sx={{ mb: 2 }}
        aria-label="back to sports events"
      >
        <ArrowBackIcon />
      </IconButton>
      <Grid container spacing={2}>
        <Grid item xs={12}>
          <BettingCard
            id={id}
            title={featuredBet.title}
            description={featuredBet.description}
            options={featuredBet.options}
            imageUrl={featuredBet.image}
          />
        </Grid>
        <Grid item xs={12}>
          <Tabs
            value={tabValue}
            onChange={handleTabChange}
            aria-label="bet tabs"
          >
            <Tab label="All Bets" />
            <Tab label="Top Bets" />
          </Tabs>
          {tabValue === 0 ? renderTable(allBets) : renderTable(topBets)}
        </Grid>
      </Grid>
    </Box>
  );
};

export default BetInfo;
