import shouldBehaveLikeCreatePool from "./effects/createPool";
import shouldBehaveLikeTrackPool from "./effects/trackPool";
import shouldBehaveLikeUntrackPool from "./effects/untrackPool";

export function shouldBehaveLikeHifiPoolFactory(): void {
  describe("Effects Functions", function () {
    describe("createPool", function () {
      shouldBehaveLikeCreatePool();
    });

    describe("trackPool", function () {
      shouldBehaveLikeTrackPool();
    });

    describe("untrackPool", function () {
      shouldBehaveLikeUntrackPool();
    });
  });
}
