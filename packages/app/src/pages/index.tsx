import { formatUnits } from "ethers/lib/utils";
import type { NextPage } from "next";
import { useContractRead } from "wagmi";

import IERC20abi from "../../../contracts/out/IERC20.sol/IERC20.abi.json";
import { useIsMounted } from "../useIsMounted";

enum BatchType {
  Mint,
  Redeem,
}

const HomePage: NextPage = () => {
  const {
    data: mainnetData,
    isError: mainnetError,
    isLoading: mainnetLoading,
  } = useContractRead({
    addressOrName: "0xd0cd466b34a24fcb2f87676278af2005ca8a78c4",
    contractInterface: IERC20abi,
    functionName: "totalSupply",
    chainId: 1,
  });
  const {
    data: polygonData,
    isError: polygonError,
    isLoading: polygonLoading,
  } = useContractRead({
    addressOrName: "0xc5b57e9a1e7914fda753a88f24e5703e617ee50c",
    contractInterface: IERC20abi,
    functionName: "totalSupply",
    chainId: 137,
  });
  const isMounted = useIsMounted();

  const formatter = Intl.NumberFormat("en", {
    //@ts-ignore
    notation: "compact",
  });

  console.log(BatchType[BatchType.Mint]);

  return (
    <div className="min-h-screen flex flex-col">
      <div className="flex-grow flex flex-col gap-4 items-center justify-center p-8 pb-[50vh]">
        <h1 className="text-4xl">POP Supply</h1>

        {/* Use isMounted to temporarily workaround hydration issues where
        server-rendered markup doesn't match the client due to localStorage
        caching in wagmi. See https://github.com/holic/web3-scaffold/pull/26 */}
        <p>
          {(isMounted && mainnetData
            ? formatter.format(parseInt(formatUnits(mainnetData, 18)))
            : null) ?? "??"}{" "}
          POP on Mainnet
        </p>
        <p>
          {(isMounted && polygonData
            ? formatter.format(parseInt(formatUnits(polygonData, 18)))
            : null) ?? "??"}{" "}
          POP on Polygon
        </p>
      </div>
    </div>
  );
};

export default HomePage;
