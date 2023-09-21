/**
 * This file gets only the ABIs necessary for the front-end of the Coin Genie
 */

import * as fs from "fs";
import * as path from "path";

import AirdropERC20 from "./artifacts/src/AirdropERC20.sol/AirdropERC20.json";
import AirdropERC20Claimable from "./artifacts/src/AirdropERC20Claimable.sol/AirdropERC20Claimable.json";
import AirdropERC20ClaimableFactory from "./artifacts/src/AirdropERC20ClaimableFactory.sol/AirdropERC20ClaimableFactory.json";
import CoinGenie from "./artifacts/src/CoinGenie.sol/CoinGenie.json";
import CoinGenieERC20 from "./artifacts/src/CoinGenieERC20.sol/CoinGenieERC20.json";
import ERC20Factory from "./artifacts/src/ERC20Factory.sol/ERC20Factory.json";
import LiquidityLocker from "./artifacts/src/LiquidityLocker.sol/LiquidityLocker.json";
import IUniswapV2Pair from "./artifacts/lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol/IUniswapV2Pair.json";
import IUniswapV2Router02 from "./artifacts/lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol/IUniswapV2Router02.json";

const outDir = path.join(__dirname, "..", "coingenie-frontend", "abis");

enum ContractAddresses {
  AirdropERC20,
  AirdropERC20Claimable,
  AirdropERC20ClaimableFactory,
  CoinGenie,
  CoinGenieERC20,
  ERC20Factory,
  LiquidityLocker,
}

export function writeAbis(addresses: string[]) {
  if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir);
  }

  fs.writeFileSync(
    path.join(outDir, "AirdropERC20.json"),
    JSON.stringify({ address: addresses[ContractAddresses.AirdropERC20], abi: AirdropERC20.abi }),
  );

  fs.writeFileSync(
    path.join(outDir, "AirdropERC20Claimable.json"),
    JSON.stringify({ address: addresses[ContractAddresses.AirdropERC20Claimable], abi: AirdropERC20Claimable.abi }),
  );

  fs.writeFileSync(
    path.join(outDir, "AirdropERC20ClaimableFactory.json"),
    JSON.stringify({
      address: addresses[ContractAddresses.AirdropERC20ClaimableFactory],
      abi: AirdropERC20ClaimableFactory.abi,
    }),
  );

  fs.writeFileSync(
    path.join(outDir, "CoinGenie.json"),
    JSON.stringify({ address: addresses[ContractAddresses.CoinGenie], abi: CoinGenie.abi }),
  );

  fs.writeFileSync(
    path.join(outDir, "CoinGenieERC20.json"),
    JSON.stringify({ address: addresses[ContractAddresses.CoinGenieERC20], abi: CoinGenieERC20.abi }),
  );

  fs.writeFileSync(
    path.join(outDir, "ERC20Factory.json"),
    JSON.stringify({ address: addresses[ContractAddresses.ERC20Factory], abi: ERC20Factory.abi }),
  );

  fs.writeFileSync(
    path.join(outDir, "LiquidityLocker.json"),
    JSON.stringify({ address: addresses[ContractAddresses.LiquidityLocker], abi: LiquidityLocker.abi }),
  );

  fs.writeFileSync(path.join(outDir, "IUniswapV2Pair.json"), JSON.stringify({ address: "", abi: IUniswapV2Pair.abi }));

  fs.writeFileSync(
    path.join(outDir, "IUniswapV2Router02.json"),
    JSON.stringify({ address: "", abi: IUniswapV2Router02.abi }),
  );

  console.log("🤝 ABIs generated successfully");
}
