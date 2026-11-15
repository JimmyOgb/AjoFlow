/** @type import('hardhat/config').HardhatUserConfig */
const config = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "cancun",
    },
  },
  paths: {
    sources: "./contracts/src",
    tests: "./contracts/test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
};

export default config;
