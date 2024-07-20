// src/theme.ts
import { createTheme } from "@mui/material/styles";

const theme = createTheme({
  palette: {
    mode: "dark",
    primary: {
      main: "#268bd2", // Blue primary color
    },
    secondary: {
      main: "#2aa198", // Cyan secondary color
    },
    background: {
      paper: "#002b36", // Dark background
      default: "#002b36", // Dark background
    },
    text: {
      primary: "#839496", // Light text color
      secondary: "#93a1a1", // Lighter secondary text color
    },
  },
});

export default theme;
