import { unitFixtureHifiPoolFactory } from "../../shared/fixtures";
import { shouldBehaveLikeHifiPoolFactory } from "./HifiPoolFactory.behavior";

export function unitTestHifiPoolFactory(): void {
  describe("HifiPoolFactory", function () {
    beforeEach(async function () {
      const { hToken, hifiPool, hifiPoolFactory } = await this.loadFixture(unitFixtureHifiPoolFactory);
      this.contracts.hifiPoolFactory = hifiPoolFactory;
      this.mocks.hifiPool = hifiPool;
      this.mocks.hToken = hToken;
    });

    shouldBehaveLikeHifiPoolFactory();
  });
}
