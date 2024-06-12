import { useState, useEffect } from 'react';
import { Principal } from '@dfinity/principal';
import { ConnectButton, ConnectDialog, useConnect, useCanister } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import { idlFactory } from "@dfinity/ledger-icp/dist/candid/ledger.idl"
function App() {

  const [ic_nft_backend] = useCanister("ic_nft_backend")

  const [walletAddress, setWalletAddress] = useState('not connected');
  const [activeProviderState, setActiveProviderState] = useState(null);
  const [NFTserver, setNFTserver] = useState(null);
  
  
  const { isConnected, principal, activeProvider } = useConnect({
    onConnect: () => {
      // Signed in

    },
    onDisconnect: () => {
      // Signed out

    }
  })
  useEffect(() => {
    if (isConnected) {
      setWalletAddress(principal);
      setActiveProviderState(activeProvider);

      setNFTserver(ic_nft_backend);
    } else {
      setWalletAddress("not connected");
    }
  }, [isConnected, principal]);

  async function transfer_ledger () {
    const transfer = {
      idl: idlFactory,
      canisterId: "ryjl3-tyaaa-aaaaa-aaaba-cai",
      methodName: 'send_dfx',
      args: [
        {
          to: "f1d25dd1aa2b2ec17b09fd7796782501915710e3ea0b60691b3d7aa8d10dc1ca",
          fee: { e8s: BigInt(10000) },
          amount: { e8s: BigInt(1000000) },
          memo: BigInt(0),
          from_subaccount: [], // For now, using default subaccount to handle ICP
          created_at_time: [],
        },
      ],
      onSuccess: async (res) => {
        console.log('transferred icp successfully', typeof(res));
      },
      onFail: (res) => {
        console.log('transfer icp error', res);
      },
    };

    console.log(await activeProviderState.ic.batchTransactions([transfer], { host: undefined }));
  }

  async function mint_multiple () {
    const args = {
      names: [
        "nft1",
        "nft2",
        "nft3",
      ],
      address : Principal.from(walletAddress),
      url : "https://openseauserdata.com/files/7fa7ffb9e887d9d02800261060b8410b.svg"
    };
    console.log(await NFTserver.mint_multiple(args.names, args.address, args.url));
  }

  async function mint_multiple_with_addresses () {

    const args = {
      data: [
        {
          address : Principal.from("6cqmr-enjkl-tv7pv-k5mf3-xzx2t-l4sxr-uw63p-rbk3f-5rrlp-ueunf-zae"),
          name : "nft_1",
        },
        {
          address : Principal.from("kvbbj-w57zu-7u7a5-44btd-x4sle-vqwpi-zd3vv-r223a-qbmkj-2zsvs-sqe"),
          name : "nft_2",
        },
        {
          address : Principal.from("6cqmr-enjkl-tv7pv-k5mf3-xzx2t-l4sxr-uw63p-rbk3f-5rrlp-ueunf-zae"),
          name : "nft_3",
        }
      ],
      url : "https://openseauserdata.com/files/7fa7ffb9e887d9d02800261060b8410b.svg"
    };
    console.log(await NFTserver.mint_multiple_with_addresses(args.data, args.url))
  }

  return (
    <>
      <ConnectButton/>
      <ConnectDialog dark={false} />
      <br/>
      {isConnected ?
        <>
          <br/>
          <button className="connect-button" onClick={transfer_ledger}>Transfer</button>
          <br/>
          <button className="connect-button" onClick={mint_multiple}>Mint Multiple</button>
          <br/>
          <button className="connect-button" onClick={mint_multiple_with_addresses}>Mint Multiple With Adress</button> 
        </>
      :''
      }
      <br/>
    </>
  )
}

export default App;
