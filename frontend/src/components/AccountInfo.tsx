import React, { useState, useEffect } from "react";
import { useParams } from "react-router-dom";
import { ethers, Contract, BrowserProvider } from "ethers";
import makeBlockie from "ethereum-blockies-base64";
import {
  useWeb3ModalProvider,
  useWeb3ModalAccount,
} from "@web3modal/ethers/react";
import predictionMarketAbi from "../contracts/PredictionMarket.json";
import { contractAddress } from "../contracts/contract-address";

interface BetSlip {
  marketId: string;
  better: string;
  amount: string;
  outcome: string;
  winningPrize: string;
  settled: boolean;
}

const AccountInfo = () => {
  const { address } = useParams<{ address: string }>();
  const [betSlips, setBetSlips] = useState<BetSlip[]>([]);
  const [loading, setLoading] = useState(true);
  const { isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  useEffect(() => {
    const fetchBetSlips = async () => {
      if (!walletProvider || !isConnected || !address) {
        console.log("Please connect to a wallet.");
        return;
      }

      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();
      const contract = new Contract(
        contractAddress.PredictionMarket,
        predictionMarketAbi.abi,
        signer,
      );

      try {
        const _marketId = 1; // Example market ID
        const [slips, winningChances] = await contract.getUserBetSlips(
          _marketId,
          address,
        );

        setBetSlips(
          slips.map((slip: any, index: number) => ({
            marketId: slip.marketId.toString(),
            better: slip.better,
            amount: slip.amount.toString(),
            outcome: slip.outcome.toString(),
            winningPrize:
              ethers.formatEther(slip.winningPrize.toString()) === "0"
                ? "0"
                : ethers.formatEther(winningChances[index].toString()),
            settled: slip.settled,
          })),
        );
      } catch (error) {
        console.error("Error fetching bet slips:", error);
      }
      setLoading(false);
    };

    fetchBetSlips();
  }, [address, isConnected, walletProvider]);

  if (loading) {
    return <p>Loading bet slips...</p>;
  }

  return (
    <div>
      <div className="header">
        <img
          src={makeBlockie(address || "0x0000")}
          alt="User Avatar"
          style={{ borderRadius: "50%" }}
        />
        <h2>{address}</h2>
      </div>
      <div className="betslips">
        {betSlips.map((slip, index) => (
          <div key={index}>
            <p>Bet Amount: {ethers.formatEther(slip.amount.toString())} ETH</p>
            <p>Outcome: {slip.outcome}</p>
            <p>Winning Prize: {slip.winningPrize} ETH</p>
            <p>Status: {slip.settled ? "Settled" : "Pending"}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AccountInfo;
