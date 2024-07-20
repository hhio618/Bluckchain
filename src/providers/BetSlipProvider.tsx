import React, { createContext, useState, ReactNode, useContext } from "react";

interface BetSlipOption {
  betId: string;
  optionId: string;
  odds: number;
  label: string;
  cryptoIconUrl: string;
}

interface BetSlipContextType {
  betSlips: BetSlipOption[];
  addBetToSlip: (option: BetSlipOption) => void;
  removeBetFromSlip: (betId: string) => void; // Function to remove a bet slip by betId
  clearAllBets: () => void; // Function to clear all bets from the slip
  openDrawer: () => void;
  closeDrawer: () => void;
  drawerIsOpen: boolean;
}

export const BetSlipContext = createContext<BetSlipContextType>(
  {} as BetSlipContextType,
);

export const BetSlipProvider: React.FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [betSlips, setBetSlips] = useState<BetSlipOption[]>([]);
  const [drawerIsOpen, setDrawerIsOpen] = useState(false);

  const addBetToSlip = (option: BetSlipOption) => {
    setBetSlips((prev) => [...prev, option]);
    openDrawer();
  };

  const removeBetFromSlip = (betId: string) => {
    setBetSlips((prev) => prev.filter((bet) => bet.betId !== betId));
  };

  const clearAllBets = () => {
    setBetSlips([]); // Clears all bets from the state
  };

  const openDrawer = () => {
    setDrawerIsOpen(true);
  };

  const closeDrawer = () => {
    setDrawerIsOpen(false);
  };

  return (
    <BetSlipContext.Provider
      value={{
        betSlips,
        addBetToSlip,
        removeBetFromSlip,
        clearAllBets,
        openDrawer,
        closeDrawer,
        drawerIsOpen,
      }}
    >
      {children}
    </BetSlipContext.Provider>
  );
};

export const useBetSlip = () => useContext(BetSlipContext);
