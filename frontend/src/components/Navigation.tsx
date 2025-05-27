'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { WalletButton } from './WalletButton';

export function Navigation() {
  const pathname = usePathname();
  
  const links = [
    { href: '/', label: 'Home' },
    { href: '/projects', label: 'Projects' },
    { href: '/dashboard', label: 'Dashboard' },
    { href: '/admin', label: 'Admin' },
  ];

  return (
    <header className="border-b">
      <div className="container flex h-16 items-center justify-between">
        <nav className="flex items-center space-x-6">
          <Link href="/" className="font-bold">
            SuiLaunch
          </Link>
          <div className="flex items-center space-x-6">
            {links.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  'text-sm font-medium transition-colors hover:text-primary',
                  pathname === link.href ? 'text-primary' : 'text-muted-foreground'
                )}
              >
                {link.label}
              </Link>
            ))}
          </div>
        </nav>
        <WalletButton />
      </div>
    </header>
  );
}
