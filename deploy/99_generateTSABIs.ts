/**
 * DON'T MODIFY OR DELETE THIS SCRIPT (unless you know what you're doing)
 *
 * This script generates the file containing the contracts Abi definitions.
 * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
 * This script should run as the last deploy script.
 *  */

import * as fs from "fs";
import { DeployFunction } from "hardhat-deploy/types";
import * as path from "path";
import prettier from "prettier";

function copyRecursive(src: string, dest: string) {
  if (fs.existsSync(src) && fs.statSync(src).isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    fs.readdirSync(src).forEach((childItemName) => {
      const childSrcPath = path.join(src, childItemName);
      const childDestPath = path.join(dest, childItemName);
      copyRecursive(childSrcPath, childDestPath);
    });
  } else {
    fs.copyFileSync(src, dest);
  }
}

function getDirectories(path: string) {
  return fs
    .readdirSync(path, { withFileTypes: true })
    .filter((dirent) => dirent.isDirectory())
    .map((dirent) => dirent.name);
}

function getContractNames(path: string) {
  return fs
    .readdirSync(path, { withFileTypes: true })
    .filter((dirent) => dirent.isFile() && dirent.name.endsWith(".json"))
    .map((dirent) => dirent.name.split(".")[0]);
}

const SOURCE_PATH = "./artifacts/contracts";
const DESTINATION_PATH = "../app/generated/abi";
const DEPLOYMENTS_DIR = "./deployments";
const ABI_DIR_ERC20 = "./artifacts/contracts/token/CoinGenieERC20.sol";
const ABI_UNISWAP_V2_ROUTER_02 = "./artifacts/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

function getContractDataFromDeployments() {
  if (!fs.existsSync(DEPLOYMENTS_DIR)) {
    throw Error("At least one other deployment script should exist to generate an actual contract.");
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const output = {} as Record<string, any>;
  for (const chainName of getDirectories(DEPLOYMENTS_DIR)) {
    const chainId = fs.readFileSync(`${DEPLOYMENTS_DIR}/${chainName}/.chainId`)?.toString();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const contracts = {} as Record<string, any>;
    for (const contractName of getContractNames(`${DEPLOYMENTS_DIR}/${chainName}`)) {
      const { abi, address } = JSON.parse(
        fs.readFileSync(`${DEPLOYMENTS_DIR}/${chainName}/${contractName}.json`)?.toString(),
      );
      contracts[contractName] = { address, abi };
    }

    // push CoinGenieERC20 since it doesn't get deployed
    let abi = JSON.parse(fs.readFileSync(`${ABI_DIR_ERC20}/CoinGenieERC20.json`)?.toString());
    contracts["CoinGenieERC20"] = { address: "", abi };

    // push UniswapV2Router02 since it doesn't get deployed
    abi = JSON.parse(fs.readFileSync(`${ABI_UNISWAP_V2_ROUTER_02}/IUniswapV2Router02.json`)?.toString());
    contracts["IUniswapV2Router02"] = { address: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", abi };

    output[chainId] = [
      {
        chainId,
        name: chainName,
        contracts,
      },
    ];
  }
  return output;
}

/**
 * Generates the TypeScript contract definition file based on the json output of the contract deployment scripts
 * This script should be run last.
 */
const generateTsAbis: DeployFunction = async function () {
  const TARGET_DIR = "../app/generated/";
  const allContractsData = getContractDataFromDeployments();

  const fileContent = Object.entries(allContractsData).reduce((content, [chainId, chainConfig]) => {
    return `${content}${parseInt(chainId).toFixed(0)}:${JSON.stringify(chainConfig, null, 2)},`;
  }, "");

  if (!fs.existsSync(TARGET_DIR)) {
    fs.mkdirSync(TARGET_DIR);
  }
  fs.writeFileSync(
    `${TARGET_DIR}deployedContracts.ts`,
    await prettier.format(`const contracts = {${fileContent}} as const; \n\n export default contracts`, {
      parser: "typescript",
    }),
  );

  await copyRecursive(SOURCE_PATH, DESTINATION_PATH);
  console.log(`✅ Updated TypeScript contract definition file on ${TARGET_DIR}deployedContracts.ts`);
};

export default generateTsAbis;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags generateTsAbis
generateTsAbis.tags = ["generateTsAbis"];

generateTsAbis.runAtTheEnd = true;
