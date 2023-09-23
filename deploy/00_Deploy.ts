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
    const logFileName =
      networkName === "localhost" ? `./logs/${networkName}/latest.md` : `./logs/${networkName}/${numFiles}.md`;

    const logToFile = (message: string) => {
      fs.appendFileSync(logFileName, message + "\n");
    };

    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const safeTransferLib = await deploy("SafeTransfer", {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });

    const commonLib = await deploy("Common", {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });

    const erc20Factory = await deploy("ERC20Factory", {
      from: deployer,
      libraries: { Common: commonLib.address },
      args: [],
      log: true,
      autoMine: true,
    });

    const airdropClaimableFactory = await deploy("AirdropERC20ClaimableFactory", {
      from: deployer,
      args: [],
      log: true,
      autoMine: true,
    });

    const airdropERC20 = await deploy("AirdropERC20", {
      from: deployer,
      libraries: { SafeTransfer: safeTransferLib.address },
      args: [],
      log: true,
      autoMine: true,
    });

    const coinGenie = await deploy("CoinGenie", {
      from: deployer,
      libraries: { SafeTransfer: safeTransferLib.address, Common: commonLib.address },
      args: [erc20Factory.address, airdropClaimableFactory.address],
      log: true,
      autoMine: true,
    });

    const uniV2Locker = await deploy("LiquidityLocker", {
      from: deployer,
      libraries: { SafeTransfer: safeTransferLib.address },
      args: [parseEther("0.01"), coinGenie.address],
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

    const erc20FactoryContract = await hre.ethers.getContractAt("ERC20Factory", erc20Factory.address);

    const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
    const genie = await coinGenieContract.launchToken(
      "Genie",
      "GENIE",
      parseEther("100000000"),
      deployer,
      {
        isBurnable: true,
        isPausable: false,
        isDeflationary: true,
      },
      parseEther("5000000"),
      parseEther("500000"),
      coinGenie.address,
      coinGenie.address,
      100,
      10,
    );

    const txReceipt = await genie.wait();
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    const erc20LaunchedLog = coinGenieContract.interface.parseLog(txReceipt?.logs[txReceipt.logs.length - 1]);
    const genieAddress = erc20LaunchedLog?.args[0];
    const genieContract = await hre.ethers.getContractAt("CoinGenieERC20", genieAddress);

    logToFile(`## 🧞‍♂️🪙 Creating $GENIE token`);
    logToFile(
      `- Address: [${genieAddress}](https://${
        networkName === "mainnet" ? "" : networkName
      }.etherscan.io/token/${genieAddress})`,
    );
    logToFile(`- Name: Genie`);
    logToFile(`- Symbol: GENIE`);
    logToFile(`- Tax: 1%`);
    logToFile(`- Total Supply: ${(100_000_000).toLocaleString()}`);
    logToFile(`- Max/Wallet: ${(5_000_000).toLocaleString()}`);
    logToFile(`- Max to Swap for Tax: ${(500_000).toLocaleString()}`);
    logToFile(`- Tax Wallet: ${deployer}`);

    await genieContract.setGenie(genieAddress);
    await erc20FactoryContract.setGenie(genieAddress);

    const contracts = [
      { name: "ERC20Factory", address: erc20Factory.address },
      { name: "AirdropERC20ClaimableFactory", address: airdropClaimableFactory.address },
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
