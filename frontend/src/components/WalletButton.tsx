'use client';

import { useCurrentWallet, useConnectWallet, useDisconnectWallet, useWallets } from '@mysten/dapp-kit';
import { Button } from './ui/button';
import { WalletIcon } from 'lucide-react';

export function WalletButton() {
  const { currentWallet, connectionStatus } = useCurrentWallet();
  const { mutate: connect } = useConnectWallet();
  const { mutate: disconnect } = useDisconnectWallet();
  const wallets = useWallets();

  // Handle the case when a wallet is connected
  if (connectionStatus === 'connected' && currentWallet) {
    return (
      <Button onClick={() => disconnect()}>
        <WalletIcon className="mr-2 h-4 w-4" />
        Disconnect
      </Button>
    );
  }

  // Handle the case when connecting
  if (connectionStatus === 'connecting') {
    return (
      <Button disabled>
        <WalletIcon className="mr-2 h-4 w-4 animate-spin" />
        Connecting...
      </Button>
    );
  }

  // Handle the case when disconnected
  return (
    <Button 
      onClick={() => {
        if (wallets.length > 0) {
          connect({ wallet: wallets[0] });
        }
      }} 
      disabled={wallets.length === 0}
    >
      <WalletIcon className="mr-2 h-4 w-4" />
      {wallets.length === 0 ? 'No Wallets Found' : 'Connect Wallet'}
    </Button>
  );
}
