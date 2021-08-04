import { Signer } from "@ethersproject/abstract-signer";
import { MockContract } from "ethereum-waffle";
import hre from "hardhat";
import { Artifact } from "hardhat/types";

import {
  HIFI_POOL_NAME,
  HIFI_POOL_SYMBOL,
  H_TOKEN_DECIMALS,
  H_TOKEN_MATURITY,
  H_TOKEN_NAME,
  H_TOKEN_SYMBOL,
  UNDERLYING_PRECISION_SCALAR,
  USDC_DECIMALS,
  USDC_NAME,
  USDC_SYMBOL,
} from "../../helpers/constants";

const { deployMockContract } = hre.waffle;

export async function deployMockHToken(deployer: Signer, underlyingAddress: string): Promise<MockContract> {
  const hTokenArtifact: Artifact = await hre.artifacts.readArtifact("GodModeHToken");
  const hToken: MockContract = await deployMockContract(deployer, hTokenArtifact.abi);
  await hToken.mock.name.returns(H_TOKEN_NAME);
  await hToken.mock.symbol.returns(H_TOKEN_SYMBOL);
  await hToken.mock.decimals.returns(H_TOKEN_DECIMALS);
  await hToken.mock.maturity.returns(H_TOKEN_MATURITY);
  await hToken.mock.underlying.returns(underlyingAddress);
  await hToken.mock.underlyingPrecisionScalar.returns(UNDERLYING_PRECISION_SCALAR);
  return hToken;
}

export async function deployMockUsdc(deployer: Signer): Promise<MockContract> {
  const erc20Artifact: Artifact = await hre.artifacts.readArtifact("Erc20");
  const erc20: MockContract = await deployMockContract(deployer, erc20Artifact.abi);
  await erc20.mock.decimals.returns(USDC_DECIMALS);
  await erc20.mock.name.returns(USDC_NAME);
  await erc20.mock.symbol.returns(USDC_SYMBOL);
  return erc20;
}

export async function deployMockHifiPool(
  deployer: Signer,
  hTokenAddress: string,
  underlyingAddress: string,
): Promise<MockContract> {
  const hifiPoolArtifact: Artifact = await hre.artifacts.readArtifact("GodModeHifiPool");
  const hifiPool: MockContract = await deployMockContract(deployer, hifiPoolArtifact.abi);
  await hifiPool.mock.name.returns(HIFI_POOL_NAME);
  await hifiPool.mock.symbol.returns(HIFI_POOL_SYMBOL);
  await hifiPool.mock.hToken.returns(hTokenAddress);
  await hifiPool.mock.maturity.returns(H_TOKEN_MATURITY);
  await hifiPool.mock.underlying.returns(underlyingAddress);
  await hifiPool.mock.underlyingPrecisionScalar.returns(UNDERLYING_PRECISION_SCALAR);
  return hifiPool;
}
