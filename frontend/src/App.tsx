// src/App.tsx
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { ThemeProvider, CssBaseline } from "@mui/material";
import LandingPage from "./pages/LandingPage";
import DappPage from "./pages/DappPage";
import theme from "./theme";
import { createWeb3Modal, defaultConfig } from "@web3modal/ethers/react";

// Initialize Web3Modal
const initializeWeb3Modal = () => {
  const projectId = "6bafac0aa2ed032f90b69cf608269b9e";
  const mainnet = {
    chainId: 1,
    name: "Ethereum",
    currency: "ETH",
    explorerUrl: "https://etherscan.io",
    rpcUrl: "https://cloudflare-eth.com",
  };

  const metadata = {
    name: "My Website",
    description: "My Website description",
    url: "https://mywebsite.com",
    icons: ["https://avatars.mywebsite.com/"],
  };

  const ethersConfig = defaultConfig({
    metadata,
    enableEIP6963: true,
    enableInjected: true,
    enableCoinbase: false,
    rpcUrl: "...", // Replace with actual RPC URL if needed
    defaultChainId: 1,
  });

  createWeb3Modal({
    ethersConfig,
    chains: [mainnet],
    projectId,
    enableAnalytics: true,
  });
};

initializeWeb3Modal(); // Initialize Web3Modal

const App: React.FC = () => {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/dapp/*" element={<DappPage />} />
        </Routes>
      </Router>
    </ThemeProvider>
  );
};

export default App;
