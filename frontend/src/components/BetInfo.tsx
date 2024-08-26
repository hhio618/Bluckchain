import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  Box,
  Typography,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Card,
  CardContent,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import StarIcon from "@mui/icons-material/Star";
import { ethers, Contract, BrowserProvider } from "ethers";
import predictionMarketAbi from "../contracts/PredictionMarket.json";
import { contractAddress } from "../contracts/contract-address";
import {
  useWeb3ModalProvider,
  useWeb3ModalAccount,
} from "@web3modal/ethers/react";
import Divider from "@mui/material/Divider";
import CasinoIcon from "@mui/icons-material/Casino";

interface MarketDetails {
  eventId: number;
  totalBets: string;
  marketSettled: boolean;
  outcome: number;
  description: string;
  endTime: string;
  eventSettled: boolean;
  eventOutcome: number;
  outcomeNames: string[];
}

interface BetTopDetail {
  better: string;
  amount: string;
  winningChance: number;
}

const BetInfo: React.FC = () => {
  const [topBets, setTopBets] = useState<BetTopDetail[]>([]);
  const [marketDetails, setMarketDetails] = useState<MarketDetails | null>(
    null,
  );
  const { id } = useParams<{ id?: string }>();
  const navigate = useNavigate();
  const { isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  useEffect(() => {
    const fetchTopBets = async () => {
      if (!walletProvider || !isConnected || !id) {
        console.log("Please connect to a wallet or check the bet ID.");
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
        const details = await contract.getMarketDetails(parseInt(id));
        setMarketDetails({
          eventId: details[0],
          totalBets: ethers.formatEther(details[1].toString()),
          marketSettled: details[2],
          outcome: details[3],
          description: details[4],
          endTime: new Date(details[5] * 1000).toLocaleString(),
          eventSettled: details[6],
          eventOutcome: details[7],
          outcomeNames: details[8],
        });
      } catch (error) {
        console.error("Error fetching market details:", error);
      }

      try {
        const [bets, winningChances] = await contract.getTopBets(parseInt(id));
        setTopBets(
          bets.map((bet: any, index: number) => ({
            better: bet.better,
            amount: ethers.formatEther(bet.amount.toString()).toString(),
            winningChance: winningChances[index].toFixed(2) + "%",
          })),
        );
      } catch (error) {
        console.error("Error fetching top bets:", error);
      }
    };

    fetchTopBets();
  }, [id, isConnected, walletProvider]);

  const handleBack = () => {
    navigate(-1);
  };

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <IconButton onClick={handleBack} sx={{ mb: 2 }}>
        <ArrowBackIcon />
      </IconButton>
      <Typography
        variant="h4"
        gutterBottom
        sx={{ display: "flex", alignItems: "center" }}
      >
        <CasinoIcon sx={{ mr: 1 }} /> Market Details
      </Typography>
      <Divider sx={{ mb: 2 }} />
      {marketDetails && (
        <Card>
          <CardContent>
            <Typography variant="h5">{marketDetails.description}</Typography>
            <Typography variant="body2">
              Total Bets: {marketDetails.totalBets} ETH
            </Typography>
            <Typography variant="body2">
              Outcome: {marketDetails.outcomeNames.join(", ")}
            </Typography>
            <Typography variant="body2">
              Event Settled: {marketDetails.eventSettled ? "Yes" : "No"}
            </Typography>
          </CardContent>
        </Card>
      )}
      <Typography
        variant="h4"
        gutterBottom
        sx={{ display: "flex", alignItems: "center" }}
      >
        <CasinoIcon sx={{ mr: 1 }} /> Top Bets
      </Typography>
      <Divider sx={{ mb: 2 }} />
      <Card>
        <CardContent>
          <TableContainer component={Paper}>
            <Table aria-label="top bets table">
              <TableHead>
                <TableRow>
                  <TableCell>Rank</TableCell>
                  <TableCell>User</TableCell>
                  <TableCell align="right">Bet Amount (ETH)</TableCell>
                  <TableCell align="right">Winning Chance</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {topBets.map((entry, index) => (
                  <TableRow key={index}>
                    <TableCell component="th" scope="row">
                      {index === 0 ? (
                        <StarIcon color="primary" />
                      ) : index === 1 ? (
                        <StarIcon color="secondary" />
                      ) : index === 2 ? (
                        <StarIcon color="action" />
                      ) : (
                        index + 1
                      )}
                    </TableCell>
                    <TableCell>{entry.better}</TableCell>
                    <TableCell align="right">{entry.amount}</TableCell>
                    <TableCell align="right">{entry.winningChance}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>
    </Box>
  );
};

export default BetInfo;
