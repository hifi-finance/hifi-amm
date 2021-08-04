import {} from "../../../shared/errors";

import { expect } from "chai";

import { HifiPoolFactoryErrors } from "../../../shared/errors";

export default function shouldBehaveLikeTrackPool(): void {
  context("when called to track an untracked pool", function () {
    it("tracks the new pool", async function () {
      await expect(this.contracts.hifiPoolFactory.connect(this.signers.admin).trackPool(this.mocks.hifiPool.address))
        .to.emit(this.contracts.hifiPoolFactory, "TrackPool")
        .withArgs(this.mocks.hifiPool.address);

      expect(await this.contracts.hifiPoolFactory.pools(0)).to.be.eq(this.mocks.hifiPool.address);
    });
  });

  context("when called to track an already-tracked pool", function () {
    beforeEach(async function () {
      await this.contracts.hifiPoolFactory.connect(this.signers.admin).trackPool(this.mocks.hifiPool.address);
    });

    it("reverts", async function () {
      await expect(
        this.contracts.hifiPoolFactory.connect(this.signers.admin).trackPool(this.mocks.hifiPool.address),
      ).to.be.revertedWith(HifiPoolFactoryErrors.PoolAlreadyTracked);
    });
  });
}
