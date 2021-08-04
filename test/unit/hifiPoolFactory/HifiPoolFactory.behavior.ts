import shouldBehaveLikeCreatePool from "./effects/createPool";

export function shouldBehaveLikeHifiPoolFactory(): void {
  describe("Effects Functions", function () {
    describe("createPool", function () {
      shouldBehaveLikeCreatePool();
    });
  });
}
