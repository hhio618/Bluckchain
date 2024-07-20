import React, { useState, useContext } from "react";
import {
  Card,
  CardContent,
  CardActions,
  CardMedia,
  Typography,
  Button,
  IconButton,
} from "@mui/material";
import BetSlipContext from "../providers/BetSlipProvider";

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
  imageUrl: string;
}

const BettingCard: React.FC<Bet> = ({
  id,
  title,
  description,
  options,
  imageUrl,
}) => {
  const { addBetToSlip, openDrawer } = useContext(BetSlipContext); // Context to manage bet slips and drawer state
  const [selectedOptionId, setSelectedOptionId] = useState<string | null>(null);

  const handleBetOptionClick = (option: BetOption) => {
    addBetToSlip({
      betId: id,
      optionId: option.optionId,
      odds: option.odds,
      label: option.label,
      cryptoIconUrl: option.cryptoIconUrl,
    });
    setSelectedOptionId(option.optionId);
    openDrawer(); // Open the bet slip drawer
  };

  return (
    <Card sx={{ maxWidth: 345, m: 1 }}>
      <CardMedia
        component="img"
        height="140"
        image={imageUrl}
        alt="Bet Image"
      />
      <CardContent>
        <Typography gutterBottom variant="h5" component="div">
          {title}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {description}
        </Typography>
      </CardContent>
      <CardActions>
        {options.map((option) => (
          <Button
            key={option.optionId}
            onClick={() => handleBetOptionClick(option)}
            variant={
              selectedOptionId === option.optionId ? "contained" : "outlined"
            }
            disabled={
              selectedOptionId !== null && selectedOptionId !== option.optionId
            }
          >
            {option.label} @ {option.odds}
          </Button>
        ))}
      </CardActions>
    </Card>
  );
};

export default BettingCard;
