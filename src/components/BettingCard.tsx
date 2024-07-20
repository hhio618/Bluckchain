// src/components/BettingCard.tsx
import React from "react";
import { makeStyles, createStyles } from "@mui/styles";
import {
  Card,
  CardContent,
  CardActions,
  Button,
  CardMedia,
  Typography,
} from "@mui/material";
import { useNavigate } from "react-router-dom";

const useStyles = makeStyles(() =>
  createStyles({
    card: {
      width: "100%",
      marginBottom: 20,
      backgroundColor: "#002b36", // Background color from Solarized Dark
      overflow: "hidden", // Hide overflow to prevent scrollbars
    },
    content: {
      color: "#839496", // Text color from Solarized Dark
    },
    action: {
      backgroundColor: "#073642", // Action button background from Solarized Dark
    },
  }),
);

interface BettingCardProps {
  title: string;
  image: string;
}

const BettingCard: React.FC<BettingCardProps> = ({ title, image }) => {
  const classes = useStyles();
  const navigate = useNavigate();

  const handleClick = () => {
    navigate("/bet/1"); // Navigate to the specific bet page
  };

  return (
    <Card className={classes.card}>
      <CardMedia
        image={image} // Image URL passed from props
        title="Betting Card Image"
      />
      <CardContent className={classes.content}>
        <Typography variant="h5">{title}</Typography>
      </CardContent>
      <CardActions className={classes.action}>
        <Button size="small" onClick={handleClick}>
          Go to Bet
        </Button>
      </CardActions>
    </Card>
  );
};

export default BettingCard;
