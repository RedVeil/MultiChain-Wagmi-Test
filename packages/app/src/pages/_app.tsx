import "tailwindcss/tailwind.css";
import "react-toastify/dist/ReactToastify.css";

import type { AppProps } from "next/app";
import Head from "next/head";
import { WagmiConfig } from "wagmi";

import { wagmiClient } from "../EthereumProviders";

const MyApp = ({ Component, pageProps }: AppProps) => {
  return (
    <>
      <Head>
        <title>POP Supply</title>
      </Head>
      <WagmiConfig client={wagmiClient}>
        <Component {...pageProps} />
      </WagmiConfig>
    </>
  );
};

export default MyApp;
