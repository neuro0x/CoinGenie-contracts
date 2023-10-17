import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers";
import * as fs from "fs";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const networkName = hre.network.name;
  try {
    // Create 'logs' folder if it doesn't exist
    if (!fs.existsSync("./logs")) {
      fs.mkdirSync("./logs");
    }

    if (!fs.existsSync(`./logs/${networkName}`)) {
      fs.mkdirSync(`./logs/${networkName}`);
    }

    // Read the number of files in the 'logs' folder
    const date = Date.now();
    const displayDate = `${new Date(date).toLocaleDateString()}-${new Date(date).toLocaleTimeString()}`;
    const numFiles = fs.readdirSync(`./logs/${networkName}`).length;
    const logFileName = `./logs/${networkName}/${numFiles}.md`;

    const logToFile = (message: string) => {
      if (networkName === "localhost") return;
      fs.appendFileSync(logFileName, message + "\n");
    };

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const airdropERC20 = await deploy("AirdropERC20", {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });

    const coinGenie = await deploy("CoinGenie", {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });

    const uniV2Locker = await deploy("LiquidityLocker", {
      from: deployer,
      args: [parseEther("0.0075"), coinGenie.address],
      log: true,
      autoMine: true,
    });

    logToFile(`# ${numFiles}. ${networkName.toUpperCase()}`);
    logToFile(`<blockquote>📅 ${displayDate}</blockquote>\n`);
    logToFile(`<blockquote>🧞‍♂️ Deployer: ${deployer}</blockquote>\n`);
    logToFile(`<blockquote>⛽️ Gas Used: ${hre.deployments.getGasUsed().toLocaleString()}</blockquote>\n`);
    logToFile(`## 🕊️ Whitelisting`);
    logToFile(
      `We whitelist the coin genie contract for the airdrop contract, each of the factory contracts, and the liquidity locker contract.`,
    );

    const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
    const genie = await coinGenieContract.launchToken(
      "Genie",
      "GENIE",
      parseEther("1000000000"),
      coinGenie.address,
      100,
      500,
      500,
    );

    const txReceipt = await genie.wait();
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const erc20LaunchedLog = coinGenieContract.interface.parseLog(txReceipt?.logs[txReceipt.logs.length - 1]);
    const genieAddress = erc20LaunchedLog?.args[0];

    logToFile(`## 🧞‍♂️🪙 Creating $GENIE token`);
    logToFile(
      `- Address: [${genieAddress}](https://${
        networkName === "mainnet" ? "" : networkName
      }.etherscan.io/token/${genieAddress})`,
    );
    logToFile(`- Name: Genie`);
    logToFile(`- Symbol: GENIE`);
    logToFile(`- Tax: 1%`);
    logToFile(`- Total Supply: ${(1_000_000_000).toLocaleString()}`);
    logToFile(`- Max/Wallet: ${(50_000_000).toLocaleString()}`);
    logToFile(`- Tax Wallet: ${deployer}`);

    // TODO: Airdrop Genie
    // TODO: Open trading on Genie
    // TODO: Set Fee Recipient to Coin Genie
    // TODO: Check for renounce ownership/fee recipient issues

    const contracts = [
      { name: "AirdropERC20", address: airdropERC20.address },
      { name: "CoinGenie", address: coinGenie.address },
      { name: "LiquidityLocker", address: uniV2Locker.address },
      { name: "CoinGenieERC20", address: genieAddress },
    ];

    logToFile(`## 👷‍♂️ Contract Links`);
    contracts.forEach((contract, i) => {
      logToFile(
        `${i + 1}. [${contract.name} - ${contract.address}](https://${
          networkName === "mainnet" ? "" : networkName
        }.etherscan.io/address/${contract.address})`,
      );
    });
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["CoinGenie"];
