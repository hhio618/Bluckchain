import React, { createContext, useState, ReactNode } from "react";

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
  openDrawer: () => void;
  closeDrawer: () => void;
}

const BetSlipContext = createContext<BetSlipContextType>(null!); // Ensure to initialize correctly

export const BetSlipProvider: React.FC<{ children: ReactNode }> = ({
  children,
}) => {
  const [betSlips, setBetSlips] = useState<BetSlipOption[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const addBetToSlip = (option: BetSlipOption) => {
    setBetSlips((current) => [...current, option]);
  };

  const openDrawer = () => {
    setDrawerOpen(true);
  };

  const closeDrawer = () => {
    setDrawerOpen(false);
  };

  return (
    <BetSlipContext.Provider
      value={{ betSlips, addBetToSlip, openDrawer, closeDrawer }}
    >
      {children}
    </BetSlipContext.Provider>
  );
};

export default BetSlipContext;
