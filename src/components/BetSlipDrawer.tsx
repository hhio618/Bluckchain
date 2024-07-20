import React, { useContext, useState } from "react";
import {
  Drawer,
  Box,
  IconButton,
  Typography,
  List,
  ListItem,
  TextField,
  Button,
  Divider,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";
import DeleteIcon from "@mui/icons-material/Delete";
import ClearAllIcon from "@mui/icons-material/ClearAll";
import { BetSlipContext } from "../providers/BetSlipProvider";

interface BetSlip {
  betId: string;
  odds: number;
  cryptoIconUrl: string; // URL to the crypto icon image
}

const BetSlipDrawer: React.FC = () => {
  const {
    drawerIsOpen,
    closeDrawer,
    betSlips,
    removeBetFromSlip,
    clearAllBets,
  } = useContext(BetSlipContext);
  const [bets, setBets] = useState<{ [key: string]: number }>({});

  const handleBetAmountChange = (betId: string, amount: number) => {
    setBets({ ...bets, [betId]: amount });
  };

  const calculatePayout = (odds: number, amount: number): number => {
    return odds * amount;
  };

  return (
    <Drawer
      anchor="right"
      open={drawerIsOpen}
      onClose={closeDrawer}
      sx={{
        width: 250,
        "& .MuiDrawer-paper": { width: 250, boxSizing: "border-box" },
      }}
    >
      <Box
        sx={{
          width: 250,
          p: 2,
          display: "flex",
          flexDirection: "column",
          height: "100%",
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center" }}>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Your Bet Slip
          </Typography>
          <IconButton onClick={clearAllBets}>
            <ClearAllIcon />
          </IconButton>
          <IconButton onClick={closeDrawer}>
            <CloseIcon />
          </IconButton>
        </Box>
        <Divider sx={{ my: 1 }} />
        <List sx={{ flexGrow: 1, overflow: "auto" }}>
          {betSlips.map((bet) => (
            <ListItem
              key={bet.betId}
              sx={{ flexDirection: "column", alignItems: "start" }}
            >
              <Box
                sx={{
                  display: "flex",
                  alignItems: "center",
                  width: "100%",
                  mb: 1,
                }}
              >
                <img
                  src={bet.cryptoIconUrl}
                  alt="Crypto"
                  style={{ height: 24, marginRight: 8 }}
                />
                <TextField
                  type="number"
                  size="small"
                  variant="outlined"
                  value={bets[bet.betId] || ""}
                  onChange={(e) =>
                    handleBetAmountChange(bet.betId, parseFloat(e.target.value))
                  }
                  InputProps={{ startAdornment: "₿" }}
                  fullWidth
                  label="Bet Amount"
                />
                <IconButton
                  onClick={() => removeBetFromSlip(bet.betId)}
                  sx={{ ml: "auto" }}
                >
                  <DeleteIcon />
                </IconButton>
              </Box>
              <Typography variant="body2">Odds: {bet.odds}</Typography>
              <Typography variant="body2">
                Potential Payout: ₿
                {calculatePayout(bet.odds, bets[bet.betId] || 0).toFixed(2)}
              </Typography>
              <Divider sx={{ width: "100%", mt: 1 }} />
            </ListItem>
          ))}
        </List>
        <Button
          variant="contained"
          color="primary"
          fullWidth
          sx={{ mt: "auto" }}
        >
          Place Bet
        </Button>
      </Box>
    </Drawer>
  );
};

export default BetSlipDrawer;
