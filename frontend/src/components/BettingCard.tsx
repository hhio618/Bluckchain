// BettingCard.tsx
import React from "react";
import {
  Card,
  CardContent,
  CardMedia,
  Typography,
  Button,
} from "@mui/material";
import { useBetSlip } from "../providers/BetSlipProvider";

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
  const { addBetToSlip } = useBetSlip();

  return (
    <Card
      sx={{
        width: "100%",
        display: "flex",
        flexDirection: "column",
        justifyContent: "space-between",
      }}
    >
      <CardMedia
        component="img"
        image={imageUrl}
        alt="Bet Image"
        sx={{ height: 140, objectFit: "cover" }}
      />
      <CardContent>
        <Typography gutterBottom variant="h5" component="div">
          {title}
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {description}
        </Typography>
        {options.map((option) => (
          <Button
            key={option.optionId}
            onClick={() => addBetToSlip({ ...option, betId: id })}
            variant="outlined"
            sx={{ mr: 1, mt: 1 }}
          >
            {option.label} @ {option.odds}
          </Button>
        ))}
      </CardContent>
    </Card>
  );
};

export default BettingCard;
