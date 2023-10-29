import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { parseEther } from "ethers";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  try {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    let GENIE_ADDRESS = "";

    switch (hre.network.name) {
      case "localhost": {
        // On Localhost since we have a fresh instance of the chain each time, we must first deploy all of the V1 contracts
        await deploy("AirdropERC20", {
          from: deployer,
          args: [],
          log: true,
          autoMine: true,
        });

        await deploy("PresaleGenie", {
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

        const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
        await coinGenieContract.launchToken("Genie", "GENIE", parseEther("1000000000"), coinGenie.address, 0, 500, 500);

        const liquidityLocker = await deploy("LiquidityLocker", {
          from: deployer,
          args: [parseEther("0.0075"), coinGenie.address],
          log: true,
          autoMine: true,
        });

        const liquidityLockerContract = await hre.ethers.getContractAt("LiquidityLocker", liquidityLocker.address);

        await liquidityLockerContract.setFeeRecipient(coinGenie.address);

        break;
      }

      case "goerli": {
        GENIE_ADDRESS = "0xFa5671B2B5b00767a0CfCF2043d4f7815961cF5A";

        const coinGenie = await deploy("CoinGenie", {
          from: deployer,
          args: [],
          log: true,
          autoMine: true,
        });

        const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
        await coinGenieContract.setGenie(GENIE_ADDRESS);

        const liquidityLocker = await hre.ethers.getContractAt(
          "LiquidityLocker",
          "0xA9811495079517dCCa463e802043eD7Ae434a9D6",
        );

        await liquidityLocker.setFeeRecipient(coinGenie.address);

        break;
      }

      case "mainnet": {
        GENIE_ADDRESS = "0xe1136f999Cf8315B5399E9717AfEd446CF6eb1f4";

        const coinGenie = await deploy("CoinGenie", {
          from: deployer,
          args: [],
          log: true,
          autoMine: true,
        });

        const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
        await coinGenieContract.setGenie(GENIE_ADDRESS);

        const liquidityLocker = await hre.ethers.getContractAt(
          "LiquidityLocker",
          "0x30ef9c41e389b50580da9713c3e6fd18c262fc82",
        );

        await liquidityLocker.setFeeRecipient(coinGenie.address);

        break;
      }
    }
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

export default deployYourContract;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["CoinGenie"];
