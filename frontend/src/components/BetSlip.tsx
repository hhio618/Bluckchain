// src/components/BetSlip.tsx
import React from "react";
import { Container, Typography, Box, Paper } from "@mui/material";
import { makeStyles, createStyles } from "@mui/styles";

const useStyles = makeStyles(() =>
  createStyles({
    container: {
      marginTop: 20,
      display: "flex",
      flexDirection: "column",
      alignContent: "center",
    },
    paper: {
      padding: 20,
      width: "100%",
      maxWidth: 1200,
      backgroundColor: "#002b36",
      color: "#839496",
    },
  }),
);

const BetSlip: React.FC = () => {
  const classes = useStyles();

  return (
    <Container className={classes.container}>
      <Typography variant="h4" gutterBottom>
        Bet Slips
      </Typography>
      <Paper className={classes.paper}>
        <Typography variant="body1">
          Here you can view all your bet slips.
        </Typography>
        {/* Add bet slip details here */}
      </Paper>
    </Container>
  );
};

export default BetSlip;
