import "@rainbow-me/rainbowkit/styles.css";

import { getDefaultWallets, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import {
  chain,
  configureChains,
  createClient,
  defaultChains,
  WagmiConfig,
} from "wagmi";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";

// Will default to goerli if nothing set in the ENV
export const targetChainId =
  parseInt(process.env.NEXT_PUBLIC_CHAIN_ID || "0") || 5;

// filter down to just mainnet + optional target testnet chain so that rainbowkit can tell
// the user to switch network if they're on an alternative one
const targetChains = defaultChains.filter(
  (chain) => chain.id === 1 || chain.id === targetChainId
);

export const { chains, provider, webSocketProvider } = configureChains(
  [chain.mainnet, chain.polygon],
  [
    jsonRpcProvider({
      rpc: (chainId) => ({
        http:
          chainId === chain.mainnet
            ? `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
            : `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      }),
    }),
  ]
);

const { connectors } = getDefaultWallets({
  appName: "Example NFT",
  chains,
});

export const wagmiClient = createClient({
  autoConnect: false,
  provider,
  webSocketProvider,
});

export const EthereumProviders: React.FC = ({ children }) => (
  <WagmiConfig client={wagmiClient}>
    <RainbowKitProvider chains={chains}>{children}</RainbowKitProvider>
  </WagmiConfig>
);
