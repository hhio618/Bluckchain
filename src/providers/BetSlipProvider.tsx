import React, { createContext, useState, ReactNode } from "react";
import { useContext } from "react";

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
    setBetSlips([...betSlips, option]);
    openDrawer();
  };

  const openDrawer = () => {
    setDrawerIsOpen(true);
  };

  const closeDrawer = () => {
    setDrawerIsOpen(false);
  };

  return (
    <BetSlipContext.Provider
      value={{ betSlips, addBetToSlip, openDrawer, closeDrawer, drawerIsOpen }}
    >
      {children}
    </BetSlipContext.Provider>
  );
};

export const useBetSlip = () => useContext(BetSlipContext);
