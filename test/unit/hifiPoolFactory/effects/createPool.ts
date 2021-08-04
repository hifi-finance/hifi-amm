import {} from "../../../shared/errors";

import { expect } from "chai";

import { HIFI_POOL_NAME, HIFI_POOL_SYMBOL, ZERO_ADDRESS } from "../../../../helpers/constants";

export default function shouldBehaveLikeCreatePool(): void {
  context("when called with correct arguments", function () {
    it("creates a new pool and returns its reference", async function () {
      await expect(
        this.contracts.hifiPoolFactory
          .connect(this.signers.admin)
          .createPool(HIFI_POOL_NAME, HIFI_POOL_SYMBOL, this.mocks.hToken.address),
      )
        .to.emit(this.contracts.hifiPoolFactory, "CreatePool")
        .to.emit(this.contracts.hifiPoolFactory, "TrackPool");

      expect(await this.contracts.hifiPoolFactory.pools(0)).to.not.be.eq(ZERO_ADDRESS);
    });
  });
}
