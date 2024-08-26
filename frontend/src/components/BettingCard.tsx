import React from "react";
import { Card, CardContent, Typography, Button, Box } from "@mui/material";
import BarChartIcon from "@mui/icons-material/BarChart";
import { useBetSlip } from "../providers/BetSlipProvider";
import { useNavigate } from "react-router-dom";

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
  totalBets: string;
  totalUniqueUsers: string;
}

const BettingCard: React.FC<Bet> = ({
  id,
  title,
  description,
  options,
  totalBets,
  totalUniqueUsers,
}) => {
  const navigate = useNavigate();
  const { addBetToSlip } = useBetSlip();

  const goToDetails = () => {
    navigate(`/dapp/bet/${id}`);
  };

  return (
    <Card
      sx={{
        width: "100%",
        display: "flex",
        flexDirection: "column",
        marginBottom: 2,
        justifyContent: "space-between",
      }}
    >
      <CardContent>
        <Typography gutterBottom variant="h5" component="div">
          {title}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {description}
        </Typography>
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            flexWrap: "wrap",
            alignItems: "center",
            mt: 2,
          }}
        >
          <Typography variant="body2">Total Bets: {totalBets} ETH</Typography>
          <Typography variant="body2">
            Unique Users: {totalUniqueUsers}
          </Typography>
        </Box>
        <Box sx={{ mt: 2, display: "flex", justifyContent: "space-between" }}>
          {options.map((option, index) => (
            <Button
              key={option.optionId}
              onClick={() => addBetToSlip({ ...option, betId: id })}
              variant="outlined"
              sx={{ width: "48%" }} // Ensures that two buttons fit side by side
            >
              {option.label} @ {option.odds}
            </Button>
          ))}
        </Box>
      </CardContent>
      <Button
        size="small"
        onClick={goToDetails}
        sx={{ alignSelf: "flex-start", m: 1 }}
      >
        <BarChartIcon />
      </Button>
    </Card>
  );
};

export default BettingCard;
