import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.scss';

import { defaultProviders } from "@connect2ic/core/providers"
import { createClient } from "@connect2ic/core"
import { Connect2ICProvider } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as ic_nft_backend from 'declarations/ic-nft-backend';
const client = createClient({
  canisters: {
    ic_nft_backend,
  },
  providers: defaultProviders,
  globalProviderConfig: {
    dev: false,
    ledgerHost: "https://boundary.ic0.app/"
  },
})

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Connect2ICProvider client={client}>
      <App />
    </Connect2ICProvider>
  </React.StrictMode>,
);
