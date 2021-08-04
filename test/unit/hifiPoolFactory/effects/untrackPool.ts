import {} from "../../../shared/errors";

import { expect } from "chai";

import { HifiPoolFactoryErrors } from "../../../shared/errors";

export default function shouldBehaveLikeUntrackPool(): void {
  context("when called to untrack a tracked pool", function () {
    beforeEach(async function () {
      await this.contracts.hifiPoolFactory.connect(this.signers.admin).trackPool(this.mocks.hifiPool.address);
    });

    it("untracks pool", async function () {
      await expect(
        this.contracts.hifiPoolFactory.connect(this.signers.admin).untrackPool(this.mocks.hifiPool.address),
      ).to.emit(this.contracts.hifiPoolFactory, "UntrackPool");
    });
  });

  context("when called to untrack an non-tracked pool", function () {
    it("reverts", async function () {
      await expect(
        this.contracts.hifiPoolFactory.connect(this.signers.admin).untrackPool(this.mocks.hifiPool.address),
      ).to.be.revertedWith(HifiPoolFactoryErrors.PoolNotTracked);
    });
  });
}
