import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { MockContract } from "ethereum-waffle";

import { GodModeErc20 } from "../typechain/GodModeErc20";
import { GodModeHifiPool } from "../typechain/GodModeHifiPool";
import { GodModeHifiPoolRegistry } from "../typechain/GodModeHifiPoolRegistry";
import { GodModeHToken } from "../typechain/GodModeHToken";
import { YieldSpaceMock } from "../typechain/YieldSpaceMock";

export interface Contracts {
  hifiPool: GodModeHifiPool;
  hifiPoolRegistry: GodModeHifiPoolRegistry;
  hToken: GodModeHToken;
  underlying: GodModeErc20;
  yieldSpace: YieldSpaceMock;
}

export interface Signers {
  admin: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
}

export interface Mocks {
  hifiPool: MockContract;
  hToken: MockContract;
  underlying: MockContract;
}
