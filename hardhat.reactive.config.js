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
    sources: "./reactive/src",
    cache: "./cache-reactive",
    artifacts: "./artifacts-reactive",
  },
};

export default config;
