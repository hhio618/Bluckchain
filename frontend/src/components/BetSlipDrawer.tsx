import React, { useContext, useState } from "react";
import { ethers, BrowserProvider, Contract } from "ethers";
import {
  useWeb3ModalProvider,
  useWeb3ModalAccount,
} from "@web3modal/ethers/react";
import {
  Drawer,
  Box,
  IconButton,
  Typography,
  List,
  ListItem,
  TextField,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Divider,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import { BetSlipContext, BetSlipOption } from "../providers/BetSlipProvider";
import predictionMarketAbi from "../contracts/PredictionMarket.json";
import { contractAddress } from "../contracts/contract-address";

const BetSlipDrawer = () => {
  const { drawerIsOpen, closeDrawer, betSlips, removeBetFromSlip } =
    useContext(BetSlipContext);
  const [openDialog, setOpenDialog] = useState(false);
  const [selectedBet, setSelectedBet] = useState<BetSlipOption>();
  const [betAmount, setBetAmount] = useState("");
  const { address, chainId, isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  // Open the dialog to place a bet
  const handleOpenBetDialog = (bet: BetSlipOption) => {
    setSelectedBet(bet);
    setOpenDialog(true);
  };

  // Close the dialog
  const handleCloseDialog = () => {
    setOpenDialog(false);
    setBetAmount("");
  };

  // Function to handle the actual placing of a bet
  const placeBet = async () => {
    if (!walletProvider || !isConnected) {
      console.log("Please connect to a wallet.");
      return;
    }
    if (!selectedBet) return;

    try {
      // Assuming BrowserProvider correctly wraps around the standard provider and can be used directly.
      const provider = new BrowserProvider(walletProvider);
      await provider.send("eth_requestAccounts", []);
      const signer = await provider.getSigner();
      const contract = new Contract(
        contractAddress.PredictionMarket,
        predictionMarketAbi.abi,
        signer,
      );
      console.log("marketId: ", selectedBet.betId);
      console.log("outcomeId: ", selectedBet.optionId);
      const transaction = await contract.placeBet(
        ethers.toBigInt(selectedBet.betId),
        ethers.toBigInt(selectedBet.optionId),
        { value: ethers.parseEther(betAmount) },
      );
      await transaction.wait();
      handleCloseDialog();
      alert("Bet placed successfully!");
    } catch (error) {
      console.error("Failed to place bet:", error);
      alert("Error placing bet. See console for details.");
    }
  };

  return (
    <Drawer anchor="right" open={drawerIsOpen} onClose={closeDrawer}>
      {/* Existing drawer content */}
      <Dialog open={openDialog} onClose={handleCloseDialog}>
        <DialogTitle>Place Bet</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Enter the amount of ETH you want to bet.
          </DialogContentText>
          <TextField
            autoFocus
            margin="dense"
            label="Bet Amount (ETH)"
            type="number"
            fullWidth
            variant="outlined"
            value={betAmount}
            onChange={(e) => setBetAmount(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={placeBet} color="primary">
            Place Bet
          </Button>
        </DialogActions>
      </Dialog>

      {/* List of bets */}
      <List>
        {betSlips.map((bet) => (
          <ListItem key={bet.betId}>
            <Typography>{`Bet on ${bet.label} with odds ${bet.odds}`}</Typography>
            <Button variant="outlined" onClick={() => handleOpenBetDialog(bet)}>
              Place Bet
            </Button>
          </ListItem>
        ))}
      </List>
    </Drawer>
  );
};

export default BetSlipDrawer;
