import React from "react";
import { Grid, List, ListItem } from "@mui/material";
import FinishedBetCard from "./FinishedBetCard";

const BetHistory: React.FC = () => (
  <List>
    <ListItem>
      <FinishedBetCard title="Finished Bet 1" />
    </ListItem>
  </List>
);

export default BetHistory;
