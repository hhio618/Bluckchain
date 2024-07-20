import React, { useState } from "react";
import { Routes, Route, Outlet, useNavigate } from "react-router-dom";
import {
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Container,
  Box,
  Switch,
  FormControlLabel,
} from "@mui/material";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import MenuIcon from "@mui/icons-material/Menu";
import SportsIcon from "@mui/icons-material/Sports";
import HistoryIcon from "@mui/icons-material/History";
import EmojiEventsOutlinedIcon from "@mui/icons-material/EmojiEventsOutlined";
import ReceiptIcon from "@mui/icons-material/Receipt";
import SportBets from "../components/SportBets";
import BetHistory from "../components/BetHistory";
import Leaderboard from "../components/Leaderboard";
import BetSlip from "../components/BetSlip";

const solarizedDarkTheme = createTheme({
  palette: {
    mode: "dark",
    background: {
      default: "#002b36",
      paper: "#073642",
    },
    text: {
      primary: "#839496",
      secondary: "#657b83",
    },
  },
  typography: {
    allVariants: {
      color: "#839496",
    },
  },
});

const solarizedLightTheme = createTheme({
  palette: {
    mode: "light",
    background: {
      default: "#fdf6e3",
      paper: "#eee8d5",
    },
    text: {
      primary: "#657b83",
      secondary: "#586e75",
    },
  },
  typography: {
    allVariants: {
      color: "#657b83",
    },
  },
});

const DappPage: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const navigate = useNavigate();

  const handleDrawerToggle = () => {
    setOpen(!open);
  };

  const handleThemeChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setDarkMode(event.target.checked);
  };

  return (
    <ThemeProvider theme={darkMode ? solarizedDarkTheme : solarizedLightTheme}>
      <AppBar position="static" style={{ paddingLeft: open ? 200 : 60 }}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            <img
              src="/bluckchain_logo.png"
              alt="Bluckchain Logo"
              style={{ height: 30, marginRight: 10 }}
            />
            Bluckchain
          </Typography>
          <FormControlLabel
            control={
              <Switch
                checked={darkMode}
                onChange={handleThemeChange}
                color="primary"
              />
            }
            label={darkMode ? "Light Mode" : "Dark Mode"}
            sx={{ marginRight: 2 }}
          />
          <w3m-button />
        </Toolbar>
      </AppBar>
      <Box sx={{ display: "flex" }}>
        <Drawer
          variant="permanent"
          sx={{
            width: open ? 200 : 60,
            flexShrink: 0,
            "& .MuiDrawer-paper": {
              width: open ? 200 : 60,
              boxSizing: "border-box",
            },
          }}
          open={open}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
        >
          <Toolbar>
            <IconButton
              color="inherit"
              aria-label="open drawer"
              edge="start"
              onClick={handleDrawerToggle}
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
            <Typography variant="h6" noWrap>
              Menu
            </Typography>
          </Toolbar>
          <List>
            <ListItem button onClick={() => navigate("/dapp/sport-events")}>
              <ListItemIcon>
                <SportsIcon />
              </ListItemIcon>
              {open && <ListItemText primary="Sport events" />}
            </ListItem>
            <ListItem button onClick={() => navigate("/dapp/bet-slip")}>
              <ListItemIcon>
                <ReceiptIcon />
              </ListItemIcon>
              {open && <ListItemText primary="Bet Slip" />}
            </ListItem>
            <ListItem button onClick={() => navigate("/dapp/betting-history")}>
              <ListItemIcon>
                <HistoryIcon />
              </ListItemIcon>
              {open && <ListItemText primary="Betting History" />}
            </ListItem>
            <ListItem button onClick={() => navigate("/dapp/leaderboard")}>
              <ListItemIcon>
                <EmojiEventsOutlinedIcon />
              </ListItemIcon>
              {open && <ListItemText primary="Leaderboard" />}
            </ListItem>
          </List>
        </Drawer>
        <Container
          maxWidth="xl"
          sx={{
            marginTop: 8,
            marginLeft: open ? 60 : 60,
            paddingLeft: open ? 140 : 0,
            width: "100%",
            transition: "padding-left 0.3s ease",
            display: "flex",
            flexDirection: "column",
            alignContent: "center",
          }}
        >
          <Box sx={{ mt: 2, width: "100%", maxWidth: 1200 }}>
            <Routes>
              <Route path="/sport-events" element={<SportBets />} />
              <Route path="/bet-slip" element={<BetSlip />} />
              <Route path="/betting-history" element={<BetHistory />} />
              <Route path="/leaderboard" element={<Leaderboard />} />
              <Route path="/" element={<Outlet />} />
            </Routes>
          </Box>
        </Container>
      </Box>
    </ThemeProvider>
  );
};

export default DappPage;
