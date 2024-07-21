// src/components/FinishedBetCard.tsx
import React from "react";
import {
  Card,
  CardContent,
  CardActions,
  Button,
  CardMedia,
  Typography,
} from "@mui/material";
import { makeStyles, createStyles } from "@mui/styles";
import { useNavigate } from "react-router-dom";

const useStyles = makeStyles({
  card: {
    marginBottom: 20,
    position: "relative",
    maxWidth: "100%",
  },
  media: {
    height: 0,
    paddingTop: "56.25%", // 16:9 aspect ratio
  },
});

interface FinishedBetCardProps {
  title: string;
}

const FinishedBetCard: React.FC<FinishedBetCardProps> = ({ title }) => {
  const classes = useStyles();
  const navigate = useNavigate();

  const handleClick = () => {
    // Handle click action, e.g., navigate to details page
    navigate(`/finished-bet/${title}`); // Example navigation path
  };

  return (
    <Card className={classes.card}>
      <CardMedia
        className={classes.media}
        image="https://via.placeholder.com/690x388" // Placeholder image URL
        title="Placeholder"
      />
      <CardContent>
        <Typography variant="h5">{title}</Typography>
        <Typography variant="body2">Bet details...</Typography>
      </CardContent>
      <CardActions>
        <Button size="small" onClick={handleClick}>
          View Details
        </Button>
      </CardActions>
    </Card>
  );
};

export default FinishedBetCard;
