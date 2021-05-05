import { HardhatUserConfig } from 'hardhat/config';
import environment from './config';

import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-ganache';

import 'hardhat-typechain';

import 'hardhat-deploy';
import 'hardhat-deploy-ethers';

import 'solidity-coverage';

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.3",
    // version: "0.7.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    },
  },
  paths: {
    root: './',
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  defaultNetwork: 'ganache',
  // defaultNetwork: 'rinkeby',
  networks: {
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/" + environment.alchemyRinkebyKey,
      chainId: 4,
      accounts: {
          mnemonic: "test test test test test test test test test test test junk",
          path: "m/44'/60'/0'/0",
          initialIndex: 0,
          count: 0
      }
    },
    hardhat: {
      forking: {
        enabled: true,
        url: 'https://eth-mainnet.alchemyapi.io/v2/' + environment.alchemyKey,
      },
      accounts: {
        mnemonic: "",
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 0
      },
      allowUnlimitedContractSize: true,
      blockGasLimit: 0x1fffffffffffff,
    },
    ganache: {
      url: 'localhost:7545',
      allowUnlimitedContractSize: true
      // gasLimit: 6000000000,
      // defaultBalanceEther: 10
    }
  },
  namedAccounts: {
    deployer: {
      default: 0,
      ropsten: '0x40aB75676527ec9830fEAc40e525764405453914',
    },
    admin: {
      default: 0,
      ropsten: '0x40aB75676527ec9830fEAc40e525764405453914',
    },
    proxyOwner: 1,
  },
  etherscan: {
    apiKey: environment.etherScanKey,
  },
};

export default config;
