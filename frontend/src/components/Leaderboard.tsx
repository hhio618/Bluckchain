import React, { useState, useEffect } from "react";
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
  IconButton,
} from "@mui/material";
import { makeStyles, createStyles } from "@mui/styles";
import SortIcon from "@mui/icons-material/Sort";
import {
  useWeb3ModalProvider,
  useWeb3ModalAccount,
} from "@web3modal/ethers/react";
import { ethers, Contract, BrowserProvider } from "ethers";
import predictionMarketAbi from "../contracts/PredictionMarket.json";
import { contractAddress } from "../contracts/contract-address";

const useStyles = makeStyles(() =>
  createStyles({
    container: {
      marginTop: 20,
    },
    table: {
      minWidth: 650,
      backgroundColor: "#002b36",
    },
    header: {
      backgroundColor: "#073642",
      color: "#839496",
    },
    row: {
      color: "#839496",
    },
    switchContainer: {
      display: "flex",
      justifyContent: "flex-start",
      alignItems: "center",
      marginBottom: 10,
    },
    switchLabel: {
      color: "#839496",
    },
    sortButton: {
      border: "none",
      background: "none",
      color: "#839496",
      cursor: "pointer",
      display: "flex",
      alignItems: "center",
      "&:hover": {
        color: "#fff",
      },
    },
  }),
);

interface LeaderboardEntry {
  rank: number;
  user: string;
  totalBets: number;
  totalPrizes: number;
}

const Leaderboard: React.FC = () => {
  const classes = useStyles();
  const [showPrizeInUSD, setShowPrizeInUSD] = useState(false);
  const [sortKey, setSortKey] = useState<"totalBets" | "totalPrizes">(
    "totalBets",
  );
  const [leaderboardData, setLeaderboardData] = useState<LeaderboardEntry[]>(
    [],
  );
  const { isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  useEffect(() => {
    const fetchLeaderboard = async () => {
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
        const [users, totalBets, totalPrizes] =
          await contract.getUserRankings();
        const newLeaderboardData = users.map((user: string, index: number) => ({
          rank: index + 1,
          user,
          totalBets: parseInt(totalBets[index].toString(), 10),
          totalPrizes: parseInt(totalPrizes[index].toString(), 10),
        }));
        setLeaderboardData(newLeaderboardData);
      } catch (error) {
        console.error("Error fetching leaderboard data:", error);
      }
    };

    fetchLeaderboard();
  }, [isConnected, walletProvider]);

  useEffect(() => {
    setLeaderboardData((prevData) =>
      [...prevData].sort((a, b) => b[sortKey] - a[sortKey]),
    );
  }, [sortKey]);

  const handlePrizeSwitch = (event: React.ChangeEvent<HTMLInputElement>) => {
    setShowPrizeInUSD(event.target.checked);
  };

  const convertToUSD = (amount: number) => {
    return amount * 2000; // Example: convert ETH to USD assuming $2000 per ETH
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
              <TableCell align="right" onClick={() => setSortKey("totalBets")}>
                <button className={classes.sortButton}>
                  Total Bets <SortIcon fontSize="small" />
                </button>
              </TableCell>
              <TableCell
                align="right"
                onClick={() => setSortKey("totalPrizes")}
              >
                <button className={classes.sortButton}>
                  Total Prizes ({showPrizeInUSD ? "USD" : "ETH"}){" "}
                  <SortIcon fontSize="small" />
                </button>
              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {leaderboardData.map((entry) => (
              <TableRow key={entry.rank}>
                <TableCell component="th" scope="row" className={classes.row}>
                  {entry.rank}
                </TableCell>
                <TableCell className={classes.row}>{entry.user}</TableCell>
                <TableCell align="right" className={classes.row}>
                  {ethers.formatUnits(entry.totalBets.toString(), 18)}
                </TableCell>
                <TableCell align="right" className={classes.row}>
                  {showPrizeInUSD
                    ? `$${convertToUSD(
                        parseFloat(
                          ethers.formatUnits(entry.totalPrizes.toString(), 18),
                        ),
                      ).toLocaleString()}`
                    : `${ethers.formatUnits(
                        entry.totalPrizes.toString(),
                        18,
                      )} ETH`}
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
