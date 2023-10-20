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

    await deploy("LiquidityLocker", {
      from: deployer,
      args: [parseEther("0.0075"), coinGenie.address],
      log: true,
      autoMine: true,
    });

    const coinGenieContract = await hre.ethers.getContractAt("CoinGenie", coinGenie.address);
    await coinGenieContract.launchToken("Genie", "GENIE", parseEther("1000000000"), coinGenie.address, 0, 500, 500);
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
deployYourContract.tags = ["CoinGenie"];
