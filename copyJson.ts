// TODO: convert this into a hardhat task

import * as fs from "fs";
import CoinGenieERC20JSON from "./artifacts/solidity-json/src/CoinGenieERC20.sol.json";

const TARGET_DIR = "../app/generated";

const main = async () => {
  fs.writeFileSync(TARGET_DIR, JSON.stringify(CoinGenieERC20JSON));
};

main()
  .then(() => {
    console.log("Done");
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
