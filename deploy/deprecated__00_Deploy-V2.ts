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

        const coinGenie = await deploy("CoinGenie", {
          from: deployer,
          args: [],
          log: true,
          autoMine: true,
        });

        const liquidityLocker = await deploy("LiquidityLocker", {
          from: deployer,
          args: [parseEther("0.0075"), coinGenie.address],
          log: true,
          autoMine: true,
        });

        const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
        await coinGenieContract.launchToken("Genie", "GENIE", parseEther("1000000000"), coinGenie.address, 0, 500, 500);

        // get genie token address
        GENIE_ADDRESS = await coinGenieContract.launchedTokens(0);

        const coinGenieV2 = await deploy("CoinGenieV2", {
          from: deployer,
          args: [GENIE_ADDRESS],
          log: true,
          autoMine: true,
        });

        const liquidityLockerContract = await hre.ethers.getContractAt("LiquidityLocker", liquidityLocker.address);
        console.log("Setting fee recipient on LiquidityLocker...");
        await liquidityLockerContract.setFeeRecipient(coinGenieV2.address);

        break;
      }

      case "goerli": {
        GENIE_ADDRESS = "0xFa5671B2B5b00767a0CfCF2043d4f7815961cF5A";

        const coinGenieV2 = await deploy("CoinGenieV2", {
          from: deployer,
          args: [GENIE_ADDRESS],
          log: true,
          autoMine: true,
        });

        const liquidityLocker = await hre.ethers.getContractAt(
          "LiquidityLocker",
          "0xA9811495079517dCCa463e802043eD7Ae434a9D6",
        );
        console.log("Setting fee recipient on LiquidityLocker...");
        await liquidityLocker.setFeeRecipient(coinGenieV2.address);

        break;
      }

      case "mainnet": {
        GENIE_ADDRESS = "0xe1136f999Cf8315B5399E9717AfEd446CF6eb1f4";

        const coinGenieV2 = await deploy("CoinGenieV2", {
          from: deployer,
          args: [GENIE_ADDRESS],
          log: true,
          autoMine: true,
        });

        const liquidityLocker = await hre.ethers.getContractAt(
          "LiquidityLocker",
          "0x30ef9c41e389b50580da9713c3e6fd18c262fc82",
        );
        console.log("Setting fee recipient on LiquidityLocker...");
        await liquidityLocker.setFeeRecipient(coinGenieV2.address);

        break;
      }
    }
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

// This is commented out bc this is the V1 deployment script and this save me from specifying tags on each deployment
// export default deployYourContract;
export default () => {};

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployYourContract.tags = ["CoinGenieV2"];
