// Define a type for the addresses in each network
type NetworkAddresses = {
  PredictionMarket: string;
};
// Define the main type for the contract addresses, using an index signature
type ContractAddresses = {
  [key: string]: NetworkAddresses;
};
export const addresses: ContractAddresses = {
  development: {
    PredictionMarket: "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82",
  },
  testnet: {
    PredictionMarket: "0xYourTestnetContractAddress",
  },
  mainnet: {
    PredictionMarket: "0xYourMainnetContractAddress",
  },
};

const environment = process.env.REACT_APP_STAGE || "development";

export const contractAddress = {
  PredictionMarket: addresses[environment].PredictionMarket,
};
