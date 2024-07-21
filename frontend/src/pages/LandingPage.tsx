// src/pages/LandingPage.tsx
import React from "react";
import { Button, Container, Typography } from "@mui/material";
import { useNavigate } from "react-router-dom";

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  const handleLaunchDApp = () => {
    navigate("/dapp"); // Navigate to the main app route
  };

  return (
    <div
      style={{
        backgroundImage: `url("https://via.placeholder.com/1600x900")`, // Replace with your background image URL
        backgroundSize: "cover",
        backgroundPosition: "center",
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        alignItems: "center",
        textAlign: "center",
      }}
    >
      <Container maxWidth="sm">
        <Typography variant="h2" gutterBottom style={{ color: "#fff" }}>
          Welcome to Bluckchain!
        </Typography>
        <Typography variant="h5" gutterBottom style={{ color: "#fff" }}>
          Experience the future of betting and predictions.
        </Typography>
        <Button
          variant="contained"
          color="primary"
          size="large"
          onClick={handleLaunchDApp}
          style={{ marginTop: 20 }}
        >
          Launch DApp
        </Button>
      </Container>
    </div>
  );
};

export default LandingPage;
