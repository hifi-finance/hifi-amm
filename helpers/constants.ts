import { BigNumber } from "@ethersproject/bignumber";

import { fp, maxInt, minInt } from "./numbers";

export const E: BigNumber = fp("2.718281828459045235");
export const MAX_SD59x18: BigNumber = maxInt(256);
export const MIN_SD59x18: BigNumber = minInt(256);
export const PI: BigNumber = fp("3.141592653589793238");
export const ZERO = BigNumber.from(0);
export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
